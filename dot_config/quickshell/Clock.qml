// Date & time widget
import QtQuick
import Quickshell

Text {
    font.family: Theme.uiFont
    font.pixelSize: Theme.fontSize
    color: Theme.barText
    text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
