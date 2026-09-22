// Window title widget
import QtQuick
import Quickshell.Hyprland
Text {
    color: "#cdd6f4"
    elide: Text.ElideRight
    width: 400
    horizontalAlignment: Text.AlignHCenter
    text: Hyprland.activeToplevel?.title ?? ""
}
