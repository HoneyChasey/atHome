// Dock at the bottom of the screen, like on macOS
// launcher, pinned apps, open apps and the trash; a dot under the open apps,
// icons grow under the mouse and the app name shows above
// left click: open the app or focus its window (click again: next window)
// middle click: new window, right click: menu (windows, actions, keep in dock, quit)
// macOS style: very transparent frosted glass, the blur comes from the hyprland layer rule
// "quickshell-dock" (hypr/hyprland/rules.lua)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    // ---- sizes ----
    readonly property int iconSize: 48
    readonly property real maxZoom: 1.5
    readonly property int spacing: 6
    readonly property int padding: 6
    readonly property int bottomMargin: 6
    readonly property int sepWidth: 1

    // ---- macOS colors: white glass, light border, blue menu selection ----
    readonly property color glass:       Theme.glass
    readonly property color glassBorder: Theme.glassBorder
    readonly property color popupBg:     Theme.dark ? Qt.rgba(0.12, 0.12, 0.13, 0.70) : Qt.rgba(0.96, 0.96, 0.97, 0.75)
    readonly property color popupText:   Theme.glassText
    readonly property color dotColor:    Theme.dark ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(0, 0, 0, 0.55)
    readonly property color highlight:   "#0a84ff"
    readonly property string font:       Theme.uiFont

    anchors { bottom: true; left: true; right: true }
    // room above the dock for the zoomed icons and the app name
    implicitHeight: iconSize * maxZoom + padding * 2 + bottomMargin + 34
    exclusiveZone: iconSize + padding * 2 + bottomMargin
    color: "transparent"
    mask: Region { item: bg }             // only the dock itself takes clicks
    WlrLayershell.namespace: "quickshell-dock"

    // ---- magnification ----
    // slots: launcher (0), apps (1..n), trash (n + 1), a separator after the launcher and before the trash
    // centers are computed with every icon at its normal size, so zooming doesn't move them under the mouse
    readonly property int appCount: DockApps.apps.length
    property real hoverX: 0
    property real zoomAmount: hover.hovered && !menu.visible ? 1 : 0
    Behavior on zoomAmount { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    function slotCenter(i) {
        const total = (appCount + 2) * iconSize + (appCount + 1) * spacing + 2 * (sepWidth + spacing)
        let x = width / 2 - total / 2 + i * (iconSize + spacing) + iconSize / 2
        if (i >= 1) x += sepWidth + spacing
        if (i >= appCount + 1) x += sepWidth + spacing
        return x
    }

    function slotSize(i) {
        const d = (hoverX - slotCenter(i)) / (iconSize * 1.6)
        return iconSize * (1 + (maxZoom - 1) * zoomAmount * Math.exp(-d * d))
    }

    // ---- trash ----
    property bool trashFull: false
    Process {
        id: trashProc
        command: ["sh", "-c", "ls -A \"${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files\" 2>/dev/null | head -n1"]
        stdout: StdioCollector { onStreamFinished: dock.trashFull = text.trim() !== "" }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: trashProc.running = true }

    HoverHandler {
        id: hover
        onPointChanged: dock.hoverX = point.position.x
    }

    // ---- dock background ----
    Rectangle {
        id: bg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: dock.bottomMargin
        width: row.width + dock.padding * 2
        height: dock.iconSize + dock.padding * 2
        radius: 20
        color: dock.glass
        border.width: 1
        border.color: dock.glassBorder
    }

    // icons are outside the background so they can grow above it
    Row {
        id: row
        anchors.bottom: bg.bottom
        anchors.bottomMargin: dock.padding
        anchors.horizontalCenter: bg.horizontalCenter
        spacing: dock.spacing

        // launcher (vicinae), like the macOS launchpad
        Slot {
            position: 0
            name: "Apps"
            onLeftClicked: Quickshell.execDetached(["vicinae", "toggle"])
            GlassTile {
                Grid {
                    anchors.centerIn: parent
                    columns: 3
                    spacing: parent.width * 0.07
                    Repeater {
                        model: ["#ff453a", "#ff9f0a", "#ffd60a", "#30d158", "#64d2ff", "#0a84ff", "#5e5ce6", "#bf5af2", "#ff375f"]
                        Rectangle {
                            required property string modelData
                            width: parent.parent.width * 0.16
                            height: width
                            radius: width * 0.3
                            color: modelData
                        }
                    }
                }
            }
        }

        Separator {}

        Repeater {
            model: ScriptModel { values: DockApps.apps }

            Slot {
                id: app
                required property string modelData
                required property int index
                readonly property var entry: DockApps.entryOf(modelData)
                readonly property var wins: DockApps.windows[modelData] ?? []
                readonly property string iconPath: entry ? Quickshell.iconPath(entry.icon, true) : ""

                position: index + 1
                name: entry ? entry.name : modelData
                running: wins.length > 0
                active: wins.some(t => t.activated)

                onLeftClicked: { if (!DockApps.activate(modelData)) bounce() }
                onMiddleClicked: { DockApps.launch(modelData); bounce() }
                onRightClicked: {
                    let items = [{ label: app.name, header: true }]
                    for (const t of wins)
                        items.push({ label: t.title || app.name, check: t.activated, run: () => DockApps.focus(t) })
                    items.push({ sep: true })
                    for (const a of entry ? entry.actions : [])
                        items.push({ label: a.name, run: () => a.execute() })
                    items.push({ label: "New Window", run: () => { DockApps.launch(app.modelData); app.bounce() } })
                    items.push({ sep: true })
                    const pinned = DockApps.isPinned(modelData)
                    items.push({ label: pinned ? "Remove from Dock" : "Keep in Dock",
                                 run: () => DockApps.setPinned(app.modelData, !pinned) })
                    if (running) items.push({ label: "Quit", run: () => DockApps.quit(app.modelData) })
                    menu.show(app, items)
                }

                // stop bouncing once the window is open
                onRunningChanged: if (running) stopBounce()

                IconImage {
                    anchors.fill: parent
                    visible: app.iconPath !== ""
                    source: app.iconPath
                }
                Text {
                    anchors.centerIn: parent
                    visible: app.iconPath === ""
                    text: "󰖯"
                    font.family: Theme.font
                    font.pixelSize: parent.width * 0.7
                    color: Theme.text
                }
            }
        }

        Separator {}

        Slot {
            id: trash
            position: dock.appCount + 1
            name: "Trash"
            onLeftClicked: Quickshell.execDetached(["nautilus", "trash:///"])
            onRightClicked: menu.show(trash, [
                { label: "Trash", header: true },
                { label: "Open", run: () => Quickshell.execDetached(["nautilus", "trash:///"]) },
                { label: "Empty Trash", run: () => {
                    Quickshell.execDetached(["gio", "trash", "--empty"])
                    dock.trashFull = false
                } },
            ])
            readonly property string iconPath: Quickshell.iconPath(dock.trashFull ? "user-trash-full" : "user-trash", true)
            IconImage {
                anchors.fill: parent
                visible: trash.iconPath !== ""
                source: trash.iconPath
            }
            // no trash icon in the icon theme: same tile as the launcher
            GlassTile {
                visible: trash.iconPath === ""
                Text {
                    anchors.centerIn: parent
                    text: dock.trashFull ? "\u{F0A79}" : "\u{F0A7A}"   // trash can full / empty
                    font.family: Theme.font
                    font.pixelSize: parent.width * 0.52
                    color: dock.popupText
                }
            }
        }
    }

    // one icon of the dock: zoom, name above, dot under it when open, bounce when launching
    component Slot: Item {
        id: slot
        required property int position
        property string name: ""
        property bool running: false
        property bool active: false
        default property alias content: icon.data

        signal leftClicked()
        signal middleClicked()
        signal rightClicked()

        function bounce() { if (!running) bounceAnim.restart() }
        function stopBounce() { bounceAnim.stop(); icon.y = 0 }

        width: dock.slotSize(position)
        height: width
        anchors.bottom: parent ? parent.bottom : undefined

        Item {
            id: icon
            width: parent.width
            height: parent.height
        }

        SequentialAnimation {
            id: bounceAnim
            loops: 4
            NumberAnimation { target: icon; property: "y"; to: -dock.iconSize * 0.4; duration: 280; easing.type: Easing.OutQuad }
            NumberAnimation { target: icon; property: "y"; to: 0; duration: 280; easing.type: Easing.InQuad }
        }

        // open app dot
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 2
            width: 4
            height: 4
            radius: 2
            visible: slot.running
            color: dock.dotColor
        }

        // app name above the icon
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 10
            width: label.implicitWidth + 20
            height: label.implicitHeight + 8
            radius: 8
            color: dock.popupBg
            border.width: 1
            border.color: dock.glassBorder
            visible: mouse.containsMouse && !menu.visible && slot.name !== ""
            Text {
                id: label
                anchors.centerIn: parent
                text: slot.name
                font.family: dock.font
                font.pixelSize: 13
                color: dock.popupText
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: e => {
                if (e.button === Qt.RightButton) slot.rightClicked()
                else if (e.button === Qt.MiddleButton) slot.middleClicked()
                else slot.leftClicked()
            }
        }
    }

    component Separator: Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: dock.iconSize * 0.12
        width: dock.sepWidth
        height: dock.iconSize * 0.76
        color: dock.glassBorder
    }

    // rounded square of light glass, for the icons drawn by the dock (launcher, trash)
    component GlassTile: Rectangle {
        anchors.fill: parent
        anchors.margins: parent.width * 0.06
        radius: width * 0.24
        border.width: 1
        border.color: dock.glassBorder
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.32 : 0.75) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.12 : 0.45) }
        }
    }

    // ---- right click menu ----
    PopupWindow {
        id: menu
        property var items: []

        function show(item, list) {
            items = list
            anchor.item = item
            visible = true
        }

        anchor.window: dock
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        implicitWidth: Math.max(180, Math.min(320, column.implicitWidth + 12))
        implicitHeight: column.implicitHeight + 12
        color: "transparent"

        HyprlandFocusGrab {
            active: menu.visible
            windows: [menu]
            onCleared: menu.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: dock.popupBg
            border.width: 1
            border.color: dock.glassBorder

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: 6
                spacing: 0

                Repeater {
                    model: menu.items

                    Rectangle {
                        id: entry
                        required property var modelData
                        Layout.fillWidth: true
                        implicitWidth: text.implicitWidth + 24
                        implicitHeight: modelData.sep ? 9 : 24
                        radius: 5
                        color: area.containsMouse && modelData.run ? dock.highlight : "transparent"

                        Rectangle {
                            visible: entry.modelData.sep ?? false
                            anchors.centerIn: parent
                            width: parent.width - 12
                            height: 1
                            color: Qt.rgba(dock.popupText.r, dock.popupText.g, dock.popupText.b, 0.15)
                        }

                        Text {
                            id: text
                            visible: !entry.modelData.sep
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            elide: Text.ElideRight
                            text: (entry.modelData.check ? "• " : "") + (entry.modelData.label ?? "")
                            font.family: dock.font
                            font.pixelSize: 13
                            font.bold: entry.modelData.header ?? false
                            color: area.containsMouse && entry.modelData.run ? "white"
                                 : entry.modelData.header ? Qt.rgba(dock.popupText.r, dock.popupText.g, dock.popupText.b, 0.55)
                                 : dock.popupText
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !!entry.modelData.run
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                menu.visible = false
                                entry.modelData.run()
                            }
                        }
                    }
                }
            }
        }
    }
}
