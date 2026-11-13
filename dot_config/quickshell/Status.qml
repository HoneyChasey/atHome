// Right side status: bluetooth (only when a device is connected), wifi / ethernet, ram, battery
// bluetooth / wifi click: control center, ram click: btop
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

RowLayout {
    id: root
    required property var barWindow
    spacing: 14

    property string net: "off"     // wifi | eth | off
    property int signal: 0
    property int ramPct: 0
    property real ramUsed: 0       // GiB
    property int battPct: -1       // -1 = no battery
    property bool charging: false
    property bool full: false

    readonly property var btDevice: Bluetooth.defaultAdapter?.devices.values.find(d => d.connected) ?? null

    component Glyph: Text {
        font.family: Theme.font
        font.pixelSize: Theme.barFontSize + 2
        color: Theme.barText
        Behavior on color { ColorAnimation { duration: 200 } }
    }
    component Label: Text {
        font.family: Theme.font
        font.pixelSize: Theme.barFontSize
        color: Theme.barText
    }
    component Click: MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
    }

    // ---- bluetooth ----
    Glyph {
        visible: root.btDevice !== null
        text: "󰂱"
        color: Theme.accent
        Click { onClicked: ControlCenter.toggle(root.barWindow) }
    }

    // ---- wifi / ethernet ----
    Glyph {
        text: root.net === "eth" ? "󰈀"
            : root.net === "off" ? "󰤮"
            : root.signal >= 80 ? "󰤨" : root.signal >= 60 ? "󰤥"
            : root.signal >= 40 ? "󰤢" : root.signal >= 20 ? "󰤟" : "󰤯"
        color: root.net === "off" ? Theme.barDim : Theme.barText
        Click { onClicked: ControlCenter.toggle(root.barWindow) }
    }

    // ---- ram ----
    Item {
        implicitWidth: ramRow.implicitWidth
        implicitHeight: ramRow.implicitHeight
        RowLayout {
            id: ramRow
            spacing: 5
            Glyph { text: "󰍛"; color: root.ramPct >= 85 ? Theme.barRed : Theme.barText }
            Label { text: root.ramUsed.toFixed(1) + "G" }
        }
        Click { onClicked: Quickshell.execDetached(["ghostty", "-e", "btop"]) }
    }

    // ---- battery ----
    RowLayout {
        visible: root.battPct >= 0
        spacing: 4
        Glyph {
            readonly property int step: Math.min(10, Math.max(0, Math.round(root.battPct / 10)))
            text: root.charging || root.full
                ? ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"][step]
                : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][step]
            color: root.charging ? Theme.barGreen
                 : root.battPct <= 20 ? Theme.barRed
                 : Theme.barText
        }
        Label {
            text: root.battPct + "%"
            color: root.battPct <= 20 && !root.charging ? Theme.barRed : Theme.barText
        }
    }

    // ---- polling: nmcli, /proc/meminfo, first BAT* in sysfs ----
    Process {
        id: proc
        command: ["sh", "-c", `
            w=$(nmcli -t -f ACTIVE,SIGNAL dev wifi list --rescan no 2>/dev/null | grep '^yes:' | head -n1 | cut -d: -f2)
            if [ -n "$w" ]; then echo "net wifi $w"
            elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q '^ethernet:connected'; then echo 'net eth 0'
            else echo 'net off 0'; fi
            awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {print "mem", t, t-a}' /proc/meminfo
            b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
            [ -n "$b" ] && echo "bat $(cat "$b/capacity") $(cat "$b/status")"
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/)
                    if (f[0] === "net") {
                        root.net = f[1]
                        root.signal = parseInt(f[2]) || 0
                    } else if (f[0] === "mem") {
                        const total = Number(f[1]), used = Number(f[2])
                        root.ramPct = total > 0 ? Math.round(used / total * 100) : 0
                        root.ramUsed = used / 1048576
                    } else if (f[0] === "bat") {
                        root.battPct = parseInt(f[1]) || 0
                        const status = f.slice(2).join(" ")
                        root.charging = status === "Charging"
                        root.full = status === "Full"
                    }
                }
            }
        }
    }

    Timer {
        interval: 3000; repeat: true; running: true
        onTriggered: proc.running = true
    }
}
