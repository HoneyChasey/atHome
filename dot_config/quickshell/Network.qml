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

    // lit arcs of the wifi icon, like macOS: dot only when the signal is very weak
    function wifiBars() {
        if (signal >= 70) return 3
        if (signal >= 45) return 2
        if (signal >= 20) return 1
        return 0
    }

    Item {
        implicitWidth: netRow.implicitWidth
        implicitHeight: netRow.implicitHeight

        RowLayout {
            id: netRow
            spacing: 6

            WifiIcon {
                visible: root.kind !== "eth"
                connected: root.kind === "wifi"
                bars: root.wifiBars()
            }
            Text {
                visible: root.kind === "eth"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.barText
                text: "󰈀"
            }
            Text {
                Layout.maximumWidth: 140
                elide: Text.ElideRight
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontSize
                color: root.kind === "off" ? Theme.barSubtext : Theme.barText
                text: root.kind === "wifi" ? root.ssid : root.kind === "eth" ? "Ethernet" : "Offline"
            }
        }

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
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontSize
        color: root.vpn !== "" ? Theme.barGreen : Theme.barSubtext
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
