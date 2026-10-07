// Shared colors and sizes for the bar
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg:      "#1e1e2e"
    readonly property color surface: "#313244"
    readonly property color text:    "#cdd6f4"
    readonly property color subtext: "#7f849c"
    readonly property color accent:  "#c4b5fd"   // same as hyprland active_border
    readonly property color green:   "#a6e3a1"
    readonly property color red:     "#f38ba8"

    readonly property string font:   "JetBrainsMono Nerd Font"
    readonly property int fontSize:  13
    readonly property int islandHeight: 30
}
