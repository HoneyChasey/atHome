// Background apps (system tray)
// left click: bring the app window to the CURRENT workspace and focus it
//   - window already open somewhere (other workspace, special workspace): moved here
//   - app only in the tray (no window): activated, and the window it opens is moved here
// middle click: secondary action, right click: app menu, scroll: app scroll action
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    required property var barWindow
    spacing: 10
    visible: SystemTray.items.values.length > 0

    // ---- bring a window here ----
    property int targetWs: -1          // workspace the click was made on
    property real pendingUntil: 0      // waiting for the window of an activated tray app

    function norm(s) { return (s ?? "").toLowerCase().replace(/[^a-z0-9]/g, "") }
    function addr(a) { return a.startsWith("0x") ? a : "0x" + a }

    // tray item id / title vs window class: "discord" ~ "discord", "spotify-client" ~ "spotify"
    function findWindow(item) {
        const keys = [item.id, item.title].map(norm).filter(k => k.length >= 3)
        const entry = DesktopEntries.heuristicLookup(item.id)
        if (entry) keys.push(norm(entry.id))
        for (const t of Hyprland.toplevels.values) {
            const cls = norm(t.wayland?.appId ?? t.lastIpcObject?.class)
            if (cls.length < 3) continue
            if (keys.some(k => cls.includes(k) || k.includes(cls))) return t
        }
        return null
    }

    function bringHere(address) {
        const a = addr(address)
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${targetWs}, window = "address:${a}" })`)
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${a}" })`)
    }

    function open(item) {
        targetWs = Hyprland.focusedWorkspace?.id ?? 1
        const t = findWindow(item)
        if (t) { bringHere(t.address); return }
        pendingUntil = Date.now() + 4000
        item.activate()
    }

    // the app opened (or focused, with focus_on_activate) its window: pull it here
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (Date.now() > root.pendingUntil) return
            if (event.name !== "openwindow" && event.name !== "activewindowv2") return
            const a = event.data.split(",")[0]
            if (!a) return
            root.pendingUntil = 0
            root.bringHere(a)
        }
    }

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item
            required property SystemTrayItem modelData
            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            function openMenu() {
                const p = item.mapToItem(null, 0, item.height + 8)
                modelData.display(root.barWindow, p.x, p.y)
            }

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate()
                else if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) openMenu()
                } else root.open(modelData)
            }
            onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
