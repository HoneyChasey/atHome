import QtQuick
import Quickshell
import Quickshell.Io


Text {
  id: root
  property string net: "…"

  color: "#cdd6f4"
  font.pixelSize: 14
  text: "󱚻  " + net   // wifi glyph + name


  Process {
    id: netProcess
    command: ["sh", "-c", "nmcli -t -f NAME connection show --active | head -n1"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.net = text.trim() || "disconnected"
    }
  }

  Timer {
    interval: 5000
    repeat: true
    onTriggered: netProc.running = true
  }

}
