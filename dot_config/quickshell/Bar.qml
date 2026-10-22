// Bar composing: like the macOS 27 menu bar, no background at all: the text sits on the
// wallpaper with a faint shadow, only the active items get a liquid glass capsule
// left: logo, focused app, workspaces / right: background apps, network, system, control center, clock
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"   // the layer rule blurs behind the capsules only

    // faint shadow under the text, so it stays readable on any wallpaper
    component Side: RowLayout {
        spacing: 18
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            shadowOpacity: Theme.wallpaperLight ? 0.25 : 0.45
            shadowBlur: 0.35
            shadowVerticalOffset: 1
        }
    }

    // ---- wallpaper brightness under the bar (hyprpaper) ----
    property string wallpaper: ""
    Process {
        id: wallProc
        command: ["hyprctl", "hyprpaper", "listactive"]   // "<monitor>: <path>" per line
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const line = lines.find(l => l.startsWith(bar.screen.name + ":")) ?? lines[0] ?? ""
                const sep = line.indexOf(": ")
                if (sep > 0) bar.wallpaper = "file://" + line.slice(sep + 2).trim()
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: wallProc.running = true }

    // draws the wallpaper small and averages the luminance of its top strip
    Canvas {
        id: sampler
        width: 64; height: 36
        opacity: 0
        renderTarget: Canvas.Image
        onImageLoaded: requestPaint()
        onPaint: {
            if (!bar.wallpaper || !isImageLoaded(bar.wallpaper)) return
            const ctx = getContext("2d")
            ctx.drawImage(bar.wallpaper, 0, 0, width, height)
            const px = ctx.getImageData(0, 0, width, 2).data
            let lum = 0
            for (let i = 0; i < px.length; i += 4)
                lum += 0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2]
            Theme.wallpaperLight = lum / (px.length / 4) / 255 > 0.6
        }
    }
    Connections {
        target: bar
        function onWallpaperChanged() {
            if (sampler.isImageLoaded(bar.wallpaper)) sampler.requestPaint()
            else sampler.loadImage(bar.wallpaper)
        }
    }

    Side {
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        Logo {}
        ActiveApp {}
        Workspaces {}
    }

    Side {
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        Tray { id: tray; barWindow: bar }
        Network {}
        System {}
        // control center button
        Text {
            font.family: Theme.font
            font.pixelSize: 15
            color: ControlCenter.open ? Theme.accent : Theme.barText
            text: "󰔡"
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: ControlCenter.toggle(bar)
            }
        }
        Clock {}
    }
}
