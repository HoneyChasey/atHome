// Name of the focused app in bold, like the app menu of the macOS menu bar
import QtQuick
import Quickshell
import Quickshell.Wayland

Text {
    readonly property string appId: ToplevelManager.activeToplevel?.appId ?? ""
    // app_id -> .desktop file, same lookup as the workspace icons
    readonly property var entry: {
        DesktopEntries.applications.values   // re-run once desktop entries are loaded
        return appId ? DesktopEntries.heuristicLookup(appId) : null
    }

    font.family: Theme.uiFont
    font.pixelSize: Theme.fontSize
    font.bold: true
    color: Theme.barText
    text: entry ? entry.name : appId || "Hyprland"
}
