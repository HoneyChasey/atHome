// Shared colors and sizes for the bar
// dark / light follows the system setting (gsettings color-scheme), used by GTK, libadwaita,
// the xdg portal (browsers, electron, flatpaks) and ghostty
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    property bool dark: true

    // dark: catppuccin mocha, light: soft grey-blue, lighter but not a white bar
    readonly property color bg:      dark ? "#1e1e2e" : "#c3c7d6"
    readonly property color surface: dark ? "#313244" : "#a9aec2"
    readonly property color text:    dark ? "#cdd6f4" : "#2f3247"
    readonly property color subtext: dark ? "#7f849c" : "#5a5e75"
    readonly property color accent:  dark ? "#c4b5fd" : "#6d5bd0"   // same as hyprland active_border
    readonly property color green:   dark ? "#a6e3a1" : "#2f7d32"
    readonly property color red:     dark ? "#f38ba8" : "#b4233f"

    // macOS-like liquid glass capsules in the top bar, blurred by the hyprland layer rule
    // in hypr/hyprland/rules.lua
    readonly property color glassEdge:   dark ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.8)   // liquid glass rim

    // top bar: no background, so like macOS the text is black or white depending on the
    // wallpaper behind it (measured by Bar.qml)
    property bool wallpaperLight: false
    readonly property color barText:    wallpaperLight ? "#1d1d1f" : "#f5f5f7"
    readonly property color barSubtext: wallpaperLight ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(1, 1, 1, 0.55)
    readonly property color barGreen:   wallpaperLight ? "#1f7a2e" : "#a6e3a1"
    readonly property color barRed:     wallpaperLight ? "#c4213f" : "#f38ba8"
    readonly property color barCapsule: wallpaperLight ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.22)

    readonly property string font:   "JetBrainsMono Nerd Font"
    readonly property string uiFont: "Adwaita Sans"     // closest to SF Pro; icons fall back to the nerd font
    readonly property int fontSize:  13
    readonly property int islandHeight: 30

    // switch the whole system: apps listening to the portal update live
    function setDark(d) {
        dark = d
        Quickshell.execDetached(["sh", "-c",
            d ? "gsettings set org.gnome.desktop.interface color-scheme prefer-dark; gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark"
              : "gsettings set org.gnome.desktop.interface color-scheme prefer-light; gsettings set org.gnome.desktop.interface gtk-theme Adwaita"])
    }

    function parse(line) {
        if (line.includes("prefer-light")) dark = false
        else if (line.includes("prefer-dark")) dark = true
    }

    // current value at startup ('default' keeps the dark bar)
    Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        running: true
        stdout: StdioCollector { onStreamFinished: theme.parse(text) }
    }

    // changes made outside the bar (another tool, gnome settings...)
    Process {
        command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
        running: true
        stdout: SplitParser { onRead: line => theme.parse(line) }
    }

    IpcHandler {
        target: "theme"
        function toggle(): void { theme.setDark(!theme.dark) }
        function dark(): void { theme.setDark(true) }
        function light(): void { theme.setDark(false) }
    }
}
