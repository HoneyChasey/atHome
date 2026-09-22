// Monitoring your system information widget
// CPU / RAM / Battery in one framed pill
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root
    property int cpuPct: 0
    property int ramPct: 0
    property int battPct: 0
    property string battStatus: "Unknown"

    property real prevIdle: 0
    property real prevTotal: 0

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 22
    radius: 4
    color: "#313244"

    // ---- battery icon: charging bolt, else fill level ----
    function battIcon(p) {
        if (root.battStatus === "Charging") return "󰂄"   // charging bolt
        if (root.battStatus === "Full")     return "󰂅"   // plugged in & full
        if (p >= 80) return "󰁹"      // full
        if (p >= 60) return "󰂁"      // almost full
        if (p >= 45) return "󰁿"      // mid
        if (p >= 20) return "󰁽"      // low
        return "󰁺"                    // empty
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Text {
            font.pixelSize: 14
            color: "#cdd6f4"
            text: "   " + root.cpuPct + "%"        // cpu glyph
        }
        Text {
            font.pixelSize: 14
            color: "#cdd6f4"
            text: "   " + root.ramPct + "%"        // memory glyph
        }
        Text {
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 14
            color: "#cdd6f4"
            text: root.battIcon(root.battPct) + "  " + root.battPct + "%"
        }
    }

    // ---- CPU: sample /proc/stat, compare to previous ----
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -n1 /proc/stat"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).slice(1).map(Number)
                const idle = p[3] + p[4]
                const total = p.reduce((a, b) => a + b, 0)
                const dIdle = idle - root.prevIdle
                const dTotal = total - root.prevTotal
                if (dTotal > 0 && root.prevTotal > 0)
                    root.cpuPct = Math.round((1 - dIdle / dTotal) * 100)
                root.prevIdle = idle
                root.prevTotal = total
            }
        }
    }

    // ---- RAM: used/total from free ----
    Process {
        id: ramProc
        command: ["sh", "-c", "free | awk '/Mem:/ {printf \"%d\", $3/$2*100}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.ramPct = parseInt(text.trim()) || 0
        }
    }

    // ---- Battery capacity: auto-detect any BAT* ----
    Process {
        id: battProc // change your battery here if your are on tower
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null | head -n1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.battPct = parseInt(text.trim()) || 0
        }
    }

    // ---- Battery status (Charging / Discharging / Full): auto-detect any BAT* ----
    Process {
        id: battStatProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/status 2>/dev/null | head -n1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.battStatus = text.trim() || "Unknown"
        }
    }

    // ---- refresh everything every 2s ----
    Timer {
        interval: 2000; repeat: true; running: true
        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
            battProc.running = true
            battStatProc.running = true
        }
    }
}
