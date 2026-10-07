// Volume / brightness popup (OSD), shown like a notification under the bar
// volume: detected from pipewire, brightness: triggered by hyprland with `qs ipc call osd brightness`
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

Scope {
    id: root

    property string kind: "volume"   // volume | brightness
    property real value: 0           // 0..1
    property bool muted: false
    property bool shown: false
    property bool ready: false       // ignore the volume "changes" sent while starting up

    readonly property var sink: Pipewire.defaultAudioSink

    function show() {
        shown = true
        hideTimer.restart()
    }

    function showVolume() {
        if (!ready || !sink || !sink.audio) return
        kind = "volume"
        value = sink.audio.volume
        muted = sink.audio.muted
        show()
    }

    function icon() {
        if (kind === "brightness")
            return value < 0.34 ? "󰃞" : value < 0.67 ? "󰃟" : "󰃠"
        if (muted || value <= 0) return "󰝟"
        return value < 0.34 ? "󰕿" : value < 0.67 ? "󰖀" : "󰕾"
    }

    PwObjectTracker { objects: [root.sink] }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.showVolume() }
        function onMutedChanged() { root.showVolume() }
    }

    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    // ---- brightness: read current level when hyprland tells us it changed ----
    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]   // intel_backlight,backlight,cur,pct%,max
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                const cur = Number(f[2]), max = Number(f[4])
                if (max > 0) {
                    root.kind = "brightness"
                    root.value = cur / max
                    root.muted = false
                    root.show()
                }
            }
        }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { brightProc.running = true }
        function volume(): void { root.showVolume() }
    }

    // ---- the popup ----
    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: root.shown || card.opacity > 0
        anchors { top: true; right: true }
        margins { top: 6; right: 10 }
        exclusiveZone: 0                 // sits under the bar, reserves no space
        implicitWidth: card.width
        implicitHeight: card.height + 8
        color: "transparent"
        mask: Region {}                  // click-through
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"

        Rectangle {
            id: card
            width: 280
            height: 58
            radius: 16
            color: Theme.bg
            border.width: 1
            border.color: Theme.surface
            opacity: root.shown ? 1 : 0
            y: root.shown ? 0 : -8
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    Layout.preferredWidth: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: root.icon()
                    font.family: Theme.font
                    font.pixelSize: 22
                    color: root.muted ? Theme.subtext : Theme.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: root.kind === "volume" ? (root.muted ? "Volume (muted)" : "Volume") : "Brightness"
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.text
                        }
                        Text {
                            text: Math.round(root.value * 100) + "%"
                            font.family: Theme.font
                            font.pixelSize: 12
                            color: Theme.subtext
                        }
                    }

                    // progress bar
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Theme.surface
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.value))
                            height: parent.height
                            radius: 3
                            color: root.muted ? Theme.subtext : Theme.accent
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
