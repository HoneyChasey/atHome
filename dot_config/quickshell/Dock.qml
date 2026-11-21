// Dock, like on macOS, hidden at the bottom of the screen: it slides up as soon as the
// mouse touches the bottom edge, and hides again when the mouse leaves it
// - apps kept in the dock (DockState.qml), then a separator and the other open apps, then the trash
// - magnification under the mouse, app name above the hovered icon
// - dot under the apps that have a window
// - left click: open the app (the icon bounces until its window shows up), or focus its window,
//   click again to go to its next window. Middle click: new window
// - right click (or long press): its windows, desktop actions, new window, keep in / remove
//   from the dock, quit
// - drag an icon of the dock to move it, drag it up out of the dock to remove it
// - an app asking for attention (urgent window) bounces and shows the dock for a moment
// - `qs ipc call dock toggle` keeps it shown / back to auto-hide
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 200                 // room for the magnified icons, the bounce and the name
    exclusionMode: ExclusionMode.Ignore // windows go under it, like the auto-hidden macOS dock
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-dock"

    // ---- sizes ----
    readonly property int iconSize: 48
    readonly property real maxScale: 1.6     // magnification of the icon under the mouse
    readonly property int range: 150         // px around the mouse where icons grow
    readonly property int spacing: 6
    readonly property int pad: 6             // between the icons and the edge of the dock
    readonly property int sepW: 13
    readonly property int bottomGap: 6       // between the dock and the bottom of the screen
    readonly property int bgH: iconSize + 2 * pad
    readonly property int bgTop: height - bottomGap - bgH
    readonly property int extra: Math.ceil(iconSize * (maxScale - 1))

    // ---- show / hide ----
    property bool menuOpen: false
    property var menuItem: null
    property string dragKey: ""
    property point dragPos: Qt.point(0, 0)
    readonly property bool dragOut: dragKey !== "" && dragPos.y < bgTop - 50
    property bool peeking: false
    property bool shown: false

    readonly property bool wantShown: hover.hovered || menuOpen || dragKey !== "" || peeking || DockState.forced
    onWantShownChanged: {
        if (wantShown) { hideTimer.stop(); shown = true }
        else hideTimer.restart()
    }
    onShownChanged: if (shown) trashCheck.running = true
    Timer { id: hideTimer; interval: 350; onTriggered: dock.shown = false }
    Timer { id: peekTimer; interval: 2500; onTriggered: dock.peeking = false }

    // input only on the bottom edge when hidden, and on the dock (plus the edge) when shown,
    // the rest of the window lets the clicks go to the windows under it
    mask: Region {
        item: dock.shown ? hitbox : null
        Region { item: trigger }
    }

    // ---- apps ----
    function keyFor(appId) {
        const e = DesktopEntries.heuristicLookup(appId)
        return e ? e.id : appId
    }

    // desktop entry id -> its windows
    readonly property var running: {
        DesktopEntries.applications.values   // re-run once desktop entries are loaded
        const map = {}
        for (const t of Hyprland.toplevels.values) {
            const id = t.wayland?.appId || t.lastIpcObject?.class || ""
            if (!id) continue
            const k = keyFor(id)
            if (!map[k]) map[k] = []
            map[k].push(t)
        }
        return map
    }

    readonly property var items: {
        const pinned = DockState.pinned
        const out = pinned.map(k => ({ key: k, kind: "app" }))
        const others = Object.keys(running).filter(k => !pinned.includes(k))
        if (others.length) {
            out.push({ key: "sep:apps", kind: "sep" })
            for (const k of others) out.push({ key: k, kind: "app" })
        }
        out.push({ key: "sep:trash", kind: "sep" })
        out.push({ key: "trash", kind: "trash" })
        return out
    }

    // position of each icon without magnification: the magnification is computed from it,
    // so the icons growing don't move the point they are compared to
    readonly property var baseOffsets: {
        const offs = []
        let x = 0
        for (const it of items) { offs.push(x); x += (it.kind === "sep" ? sepW : iconSize) + spacing }
        return offs
    }
    readonly property real baseWidth: items.reduce((w, it) => w + (it.kind === "sep" ? sepW : iconSize), 0)
                                      + spacing * Math.max(0, items.length - 1)
    readonly property real baseStart: (width - baseWidth) / 2

    readonly property real mouseX: hover.point.position.x
    readonly property bool magnify: shown && hover.hovered && !menuOpen
        && hover.point.position.y >= hitbox.y
        && mouseX >= hitbox.x && mouseX <= hitbox.x + hitbox.width

    property var hoveredItem: null

    function addr(a) { return a.startsWith("0x") ? a : "0x" + a }
    function focusWindow(t) {
        if (t) Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr(t.address)}" })`)
    }

    // an app asks for attention: show the dock for a moment
    readonly property bool anyUrgent: Hyprland.toplevels.values.some(t => t.urgent)
    onAnyUrgentChanged: if (anyUrgent) { peeking = true; peekTimer.restart() }

    // ---- trash ----
    property bool trashFull: false
    Process {
        id: trashCheck
        command: ["sh", "-c", 'ls -A "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files" 2>/dev/null | head -n1']
        stdout: StdioCollector { onStreamFinished: dock.trashFull = text.trim() !== "" }
    }

    // ---- context menu ----
    function openMenu(it) {
        hoveredItem = null
        menuItem = it
        popup.anchor.rect.x = row.x + it.x + it.width / 2
        popup.anchor.rect.y = row.y + row.height - it.iconSize - 10
        menuOpen = true
    }

    readonly property var menuEntries: {
        const it = menuItem
        if (!it) return []
        if (it.kind === "trash")
            return [{ t: "Open", a: "trash-open" },
                    { sep: true },
                    { t: "Empty Trash", a: "trash-empty", off: !trashFull }]
        const out = []
        const active = Hyprland.activeToplevel?.address
        it.windows.forEach((w, i) => out.push({ t: w.title || it.name, a: "win", i, check: w.address === active }))
        if (it.windows.length) out.push({ sep: true })
        const acts = it.entry?.actions ?? []
        for (let i = 0; i < acts.length; i++) out.push({ t: acts[i].name, a: "action", i })
        if (it.entry) out.push({ t: it.windows.length ? "New Window" : "Open", a: "launch" })
        if (it.entry) {
            out.push({ sep: true })
            out.push({ t: it.pinned ? "Remove from Dock" : "Keep in Dock", a: "pin" })
        }
        if (it.windows.length) {
            out.push({ sep: true })
            out.push({ t: "Quit", a: "quit" })
        }
        if (out.length && out[0].sep) out.shift()
        return out
    }

    function runMenu(e) {
        const it = menuItem
        menuOpen = false
        if (!it) return
        switch (e.a) {
        case "win": focusWindow(it.windows[e.i]); break
        case "action": it.entry.actions[e.i].execute(); break
        case "launch": it.launch(); break
        case "pin": it.pinned ? DockState.unpin(it.key) : DockState.pin(it.key); break
        case "quit": for (const w of it.windows) w.wayland?.close(); break
        case "trash-open": Quickshell.execDetached(["gio", "open", "trash:///"]); break
        case "trash-empty":
            Quickshell.execDetached(["sh", "-c", "gio trash --empty"])
            trashFull = false
            break
        }
    }

    // ================= view =================
    Item {
        id: root
        anchors.fill: parent

        HoverHandler { id: hover }

        // bottom edge of the screen: touching it shows the dock
        Item {
            id: trigger
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 2
        }

        // input area when the dock is shown (does not move with the slide animation)
        Item {
            id: hitbox
            x: (root.width - bg.width) / 2 - 8
            width: bg.width + 16
            y: dock.bgTop - dock.extra - 4
            height: root.height - y
        }

        // everything that slides
        Item {
            id: content
            width: root.width
            height: root.height
            y: dock.shown ? 0 : dock.bgH + dock.bottomGap + 10
            Behavior on y { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }

            Rectangle {
                id: bg
                anchors.horizontalCenter: parent.horizontalCenter
                y: dock.bgTop
                width: row.width + 2 * dock.pad
                height: dock.bgH
                // glass, like the recent macOS dock: almost clear, a light white tint over the
                // blur (hyprland layer rule), a shine on the top edge and a bright thin border
                radius: 22
                color: Qt.rgba(1, 1, 1, Theme.dark ? 0.07 : 0.14)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, Theme.dark ? 0.22 : 0.45)

                // shine: brighter at the top, fading out before the middle
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.16 : 0.28) }
                        GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.04 : 0.08) }
                    }
                }
            }

            Row {
                id: row
                anchors.horizontalCenter: bg.horizontalCenter
                y: bg.y + bg.height - dock.pad - height
                height: dock.iconSize * dock.maxScale
                spacing: dock.spacing

                Repeater {
                    model: ScriptModel {
                        values: dock.items
                        objectProp: "key"
                    }
                    delegate: DockItem {}
                }
            }

            // app name above the hovered icon
            Rectangle {
                id: tip
                readonly property var target: dock.hoveredItem
                property string label: ""
                onTargetChanged: if (target) label = target.label

                opacity: target && dock.shown && !dock.menuOpen && dock.dragKey === "" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                x: target ? row.x + target.x + target.width / 2 - width / 2 : x
                y: target ? row.y + row.height - target.iconSize - height - 12 : y
                width: tipText.implicitWidth + 20
                height: tipText.implicitHeight + 8
                radius: 7
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
                border.width: 1
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)

                Text {
                    id: tipText
                    anchors.centerIn: parent
                    text: tip.label
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize
                }
            }
        }

        // icon following the mouse when it is dragged out of the dock
        Image {
            visible: dock.dragOut
            readonly property var it: dock.dragKey !== ""
                ? DesktopEntries.byId(dock.dragKey) ?? DesktopEntries.heuristicLookup(dock.dragKey) : null
            source: it ? Quickshell.iconPath(it.icon, "application-x-executable") : ""
            width: dock.iconSize; height: dock.iconSize
            sourceSize: Qt.size(dock.iconSize * 2, dock.iconSize * 2)
            x: dock.dragPos.x - width / 2
            y: dock.dragPos.y - height / 2
            opacity: 0.8
            smooth: true

            Text {
                anchors { top: parent.bottom; horizontalCenter: parent.horizontalCenter }
                text: "Remove"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: 11
                style: Text.Outline
                styleColor: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.8)
            }
        }
    }

    // ================= one icon =================
    component DockItem: Item {
        id: it
        required property var modelData
        required property int index

        readonly property string key: modelData.key
        readonly property string kind: modelData.kind
        readonly property bool isApp: kind === "app"
        readonly property var entry: {
            DesktopEntries.applications.values
            return isApp ? (DesktopEntries.byId(key) ?? DesktopEntries.heuristicLookup(key)) : null
        }
        readonly property var windows: isApp ? (dock.running[key] ?? []) : []
        readonly property bool pinned: DockState.pinned.includes(key)
        readonly property string name: entry?.name ?? key
        readonly property string label: kind === "trash" ? "Trash" : name
        readonly property string iconSource: kind === "sep" ? ""
            : kind === "trash" ? Qt.resolvedUrl(dock.trashFull ? "icons/trash-full.svg" : "icons/trash-empty.svg").toString()
            : Quickshell.iconPath(entry?.icon ?? key, true) || Quickshell.iconPath("application-x-executable", true)

        // ---- magnification ----
        readonly property real baseW: kind === "sep" ? dock.sepW : dock.iconSize
        readonly property real baseCenter: dock.baseStart + (dock.baseOffsets[index] ?? 0) + baseW / 2
        readonly property real targetScale: {
            if (kind === "sep" || !dock.magnify) return 1
            const d = Math.abs(dock.mouseX - baseCenter) / dock.range
            return d >= 1 ? 1 : 1 + (dock.maxScale - 1) * Math.cos(d * Math.PI / 2)
        }
        property real s: targetScale
        Behavior on s { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        readonly property real iconSize: dock.iconSize * s

        width: kind === "sep" ? dock.sepW : iconSize
        height: parent.height

        // ---- open / focus ----
        property bool launching: false
        property int launchCount: 0
        readonly property bool urgent: windows.some(w => w.urgent)

        function launch() {
            if (!entry) return
            launchCount = windows.length
            launching = true
            launchTimer.restart()
            entry.execute()
        }

        function activate() {
            if (kind === "trash") { Quickshell.execDetached(["gio", "open", "trash:///"]); return }
            if (windows.length === 0) { launch(); return }
            const active = Hyprland.activeToplevel?.address
            const i = windows.findIndex(w => w.address === active)
            const ws = Hyprland.focusedWorkspace?.id
            dock.focusWindow(i >= 0 ? windows[(i + 1) % windows.length]                 // next window
                                    : windows.find(w => w.workspace?.id === ws) ?? windows[0])
        }

        onWindowsChanged: if (launching && windows.length > launchCount) launching = false
        Timer { id: launchTimer; interval: 6000; onTriggered: it.launching = false }

        // ---- bounce ----
        property real bounce: 0
        SequentialAnimation on bounce {
            running: it.launching || it.urgent
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { from: 0; to: dock.iconSize * 0.45; duration: 280; easing.type: Easing.OutQuad }
            NumberAnimation { to: 0; duration: 280; easing.type: Easing.InQuad }
        }

        // ---- separator ----
        Rectangle {
            visible: it.kind === "sep"
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
            width: 1
            height: dock.iconSize - 8
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
        }

        // ---- icon ----
        Image {
            id: icon
            visible: it.kind !== "sep"
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
            width: it.iconSize
            height: it.iconSize
            source: it.iconSource
            sourceSize: Qt.size(dock.iconSize * dock.maxScale * 2, dock.iconSize * dock.maxScale * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: dock.dragKey === it.key && dock.dragOut ? 0.25 : ma.pressed && dock.dragKey === "" ? 0.7 : 1
            transform: Translate { y: -it.bounce }
        }

        // running dot
        Rectangle {
            visible: it.windows.length > 0
            anchors { top: parent.bottom; topMargin: 1; horizontalCenter: parent.horizontalCenter }
            width: 4; height: 4; radius: 2
            color: Theme.text
            opacity: 0.85
        }

        MouseArea {
            id: ma
            anchors.fill: icon
            enabled: it.kind !== "sep"
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            pressAndHoldInterval: 600

            property point press
            property bool held: false

            onContainsMouseChanged: {
                if (containsMouse) dock.hoveredItem = it
                else if (dock.hoveredItem === it) dock.hoveredItem = null
            }

            onPressed: m => {
                press = Qt.point(m.x, m.y)
                held = false
                if (m.button === Qt.RightButton) { dock.openMenu(it); return }
                dock.menuOpen = false
            }

            onPressAndHold: m => {
                if (m.button !== Qt.LeftButton || dock.dragKey !== "") return
                held = true
                dock.openMenu(it)
            }

            // drag to move a kept app, drag up out of the dock to remove it
            onPositionChanged: m => {
                if (!(pressedButtons & Qt.LeftButton) || !it.pinned || held) return
                if (dock.dragKey === "") {
                    if (Math.hypot(m.x - press.x, m.y - press.y) < 8) return
                    dock.dragKey = it.key
                    dock.menuOpen = false
                }
                const p = ma.mapToItem(root, m.x, m.y)
                dock.dragPos = p
                if (dock.dragOut) return
                const slot = Math.round((p.x - dock.baseStart - dock.iconSize / 2) / (dock.iconSize + dock.spacing))
                DockState.move(it.key, Math.max(0, Math.min(DockState.pinned.length - 1, slot)))
            }

            onReleased: m => {
                if (dock.dragKey === it.key) {
                    if (dock.dragOut) DockState.unpin(it.key)
                    dock.dragKey = ""
                    return
                }
                if (held || !containsMouse) return
                if (m.button === Qt.LeftButton) it.activate()
                else if (m.button === Qt.MiddleButton) it.launch()
            }

            onCanceled: dock.dragKey = ""
        }
    }

    // ================= context menu =================
    PopupWindow {
        id: popup
        visible: dock.menuOpen && dock.menuItem !== null
        anchor.window: dock
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        implicitWidth: card.width
        implicitHeight: card.height
        color: "transparent"

        HyprlandFocusGrab {
            active: popup.visible
            windows: [popup, dock]
            onCleared: dock.menuOpen = false
        }

        Rectangle {
            id: card
            width: Math.max(180, Math.min(320, menuCol.implicitWidth + 12))
            height: menuCol.implicitHeight + 12
            radius: Theme.roundingSmall + 2
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
            border.width: 1
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.14)

            Column {
                id: menuCol
                x: 6; y: 6
                width: card.width - 12

                Repeater {
                    model: dock.menuEntries

                    Item {
                        id: entry
                        required property var modelData
                        width: menuCol.width
                        implicitWidth: entryText.implicitWidth + 40
                        height: modelData.sep ? 9 : 26

                        Rectangle {
                            visible: !!entry.modelData.sep
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                                      leftMargin: 6; rightMargin: 6 }
                            height: 1
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                        }

                        Rectangle {
                            visible: !entry.modelData.sep
                            anchors.fill: parent
                            radius: 5
                            color: entryMa.containsMouse && !entry.modelData.off ? Theme.accent : "transparent"
                        }

                        Text {
                            visible: !!entry.modelData.check
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            text: "✓"
                            color: entryMa.containsMouse ? Theme.bg : Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            id: entryText
                            visible: !entry.modelData.sep
                            anchors { left: parent.left; right: parent.right; leftMargin: 26; rightMargin: 10
                                      verticalCenter: parent.verticalCenter }
                            text: entry.modelData.t ?? ""
                            elide: Text.ElideRight
                            color: entry.modelData.off ? Theme.subtext
                                 : entryMa.containsMouse ? Theme.bg : Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            id: entryMa
                            anchors.fill: parent
                            enabled: !entry.modelData.sep && !entry.modelData.off
                            hoverEnabled: true
                            onClicked: dock.runMenu(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}
