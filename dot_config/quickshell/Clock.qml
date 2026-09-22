// Clock widget
import QtQuick
import Quickshell
Text {
    color: "#cdd6f4"
    text: Qt.formatDateTime(clock.date, "ddd dd MMM  hh:mm")
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
