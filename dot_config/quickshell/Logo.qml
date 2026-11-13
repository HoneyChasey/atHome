// Icon of the focused app, the arch logo when the workspace has no focused window
// icon lookup: app_id -> .desktop file -> icon theme (see readme)
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Item {
    id: root

    readonly property var win: Hyprland.activeToplevel
    readonly property var ws: Hyprland.focusedWorkspace
    // the active window must be on the workspace we look at (it stays set after switching
    // to an empty workspace)
    readonly property bool hasWindow: win !== null && ws !== null
        && win.workspace?.id === ws.id && ws.toplevels.values.length > 0
    readonly property string appId: hasWindow ? (win.wayland?.appId ?? win.lastIpcObject?.class ?? "") : ""

    readonly property string iconPath: {
        DesktopEntries.applications.values   // re-run once desktop entries are loaded
        const entry = appId ? DesktopEntries.heuristicLookup(appId) : null
        return entry ? Quickshell.iconPath(entry.icon, true) : ""
    }

    implicitWidth: 18
    implicitHeight: 18

    IconImage {
        anchors.fill: parent
        visible: root.iconPath !== ""
        source: root.iconPath
    }
    Text {
        anchors.centerIn: parent
        visible: root.iconPath === ""
        font.family: Theme.font
        font.pixelSize: 17
        color: root.hasWindow ? Theme.barText : Theme.accent
        text: root.hasWindow ? "󰖯" : "󰣇"   // app without icon : arch
    }
}
