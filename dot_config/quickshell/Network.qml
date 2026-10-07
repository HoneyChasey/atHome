// Wifi / ethernet + VPN widget (NetworkManager, plus wireguard/tun interfaces for VPN apps)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root
    spacing: 10

    property string kind: "off"   // wifi | eth | off
    property int signal: 0
    property string ssid: ""
    property string vpn: ""        // empty = no vpn

    function netIcon() {
        if (kind === "eth") return "󰈀"
        if (kind !== "wifi") return "󰤭"
        if (signal >= 80) return "󰤨"
        if (signal >= 60) return "󰤥"
        if (signal >= 40) return "󰤢"
        if (signal >= 20) return "󰤟"
        return "󰤯"
    }

    Text {
        Layout.maximumWidth: 160
        elide: Text.ElideRight
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: root.kind === "off" ? Theme.subtext : Theme.text
        text: root.netIcon() + "  " + (root.kind === "wifi" ? root.ssid
                                     : root.kind === "eth" ? "Ethernet" : "Offline")
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["ghostty", "-e", "nmtui"])
        }
    }

    // always shown: dim shield when off, green shield + vpn name when connected
    Text {
        Layout.maximumWidth: 140
        elide: Text.ElideRight
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: root.vpn !== "" ? Theme.green : Theme.subtext
        text: "󰦝  " + (root.vpn !== "" ? root.vpn : "VPN off")
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Process {
        id: netProc
        command: ["sh", "-c", `
            w=$(nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes:' | head -n1)
            if [ -n "$w" ]; then echo "net|wifi|$(echo "$w" | cut -d: -f2-)"
            elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q '^ethernet:connected'; then echo 'net|eth|'
            else echo 'net|off|'; fi
            v=$(nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | grep -E '^(vpn|wireguard):' | head -n1 | cut -d: -f2-)
            [ -z "$v" ] && v=$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(wg|tun|tap|tailscale|proton|nordlynx|mullvad)' | head -n1 | cut -d@ -f1)
            echo "vpn|$v"
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const parts = line.split("|")
                    if (parts[0] === "net") {
                        root.kind = parts[1]
                        const rest = parts.slice(2).join("|")          // SIGNAL:SSID
                        const sep = rest.indexOf(":")
                        root.signal = parseInt(rest.slice(0, sep)) || 0
                        root.ssid = rest.slice(sep + 1).replace(/\\:/g, ":")
                    } else if (parts[0] === "vpn") {
                        root.vpn = parts.slice(1).join("|").trim()
                    }
                }
            }
        }
    }

    Timer {
        interval: 5000; repeat: true; running: true
        onTriggered: netProc.running = true
    }
}
