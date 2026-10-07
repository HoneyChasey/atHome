// Date & time widget
import QtQuick
import Quickshell

Text {
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    color: Theme.text
    text: Qt.formatDateTime(clock.date, "ddd dd MMM   HH:mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
