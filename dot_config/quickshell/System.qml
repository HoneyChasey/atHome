// Monitoring your system information widget: CPU / RAM / Battery
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
    id: root
    spacing: 12

    property int cpuPct: 0
    property int ramPct: 0
    property int battPct: -1          // -1 = no battery (tower)
    property string battStatus: "Unknown"

    property real prevIdle: 0
    property real prevTotal: 0

    // ---- battery icon: charging bolt, else fill level ----
    function battIcon(p) {
        if (battStatus === "Charging") return "󰂄"
        if (battStatus === "Full")     return "󰂅"
        if (p >= 80) return "󰁹"
        if (p >= 60) return "󰂁"
        if (p >= 45) return "󰁿"
        if (p >= 20) return "󰁽"
        return "󰁺"
    }

    component Stat: Text {
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.text
    }

    Stat { text: "󰻠  " + root.cpuPct + "%" }
    Stat { text: "󰍛  " + root.ramPct + "%" }
    Stat {
        visible: root.battPct >= 0
        color: root.battPct < 20 && root.battStatus !== "Charging" ? Theme.red : Theme.text
        text: root.battIcon(root.battPct) + "  " + root.battPct + "%"
    }

    // ---- one sample of cpu (/proc/stat), ram (free) and the first BAT* found ----
    Process {
        id: statProc
        command: ["sh", "-c", `
            head -n1 /proc/stat
            free | awk '/Mem:/ {print "mem", int($3/$2*100)}'
            b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
            [ -n "$b" ] && echo "bat $(cat "$b/capacity") $(cat "$b/status")"
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/)
                    if (f[0] === "cpu") {
                        // compare to previous sample
                        const p = f.slice(1).map(Number)
                        const idle = p[3] + p[4]
                        const total = p.reduce((a, b) => a + b, 0)
                        const dTotal = total - root.prevTotal
                        if (dTotal > 0 && root.prevTotal > 0)
                            root.cpuPct = Math.round((1 - (idle - root.prevIdle) / dTotal) * 100)
                        root.prevIdle = idle
                        root.prevTotal = total
                    } else if (f[0] === "mem") {
                        root.ramPct = parseInt(f[1]) || 0
                    } else if (f[0] === "bat") {
                        root.battPct = parseInt(f[1]) || 0
                        root.battStatus = f.slice(2).join(" ") || "Unknown"
                    }
                }
            }
        }
    }

    // ---- refresh everything every 2s ----
    Timer {
        interval: 2000; repeat: true; running: true
        onTriggered: statProc.running = true
    }
}
