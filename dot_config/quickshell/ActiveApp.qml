// Name of the focused app in bold, like the app menu of the macOS menu bar
import QtQuick
import Quickshell.Wayland

Text {
    readonly property string appId: ToplevelManager.activeToplevel?.appId ?? ""
    readonly property var entry: appId ? DockApps.entryOf(DockApps.keyOf(appId)) : null

    font.family: Theme.uiFont
    font.pixelSize: Theme.fontSize
    font.bold: true
    color: Theme.barText
    text: entry ? entry.name : appId || "Hyprland"
}
