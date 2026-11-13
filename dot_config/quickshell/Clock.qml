// Middle of the bar: date, time and notifications (swaync)
// click: calendar & notifications menu (CalendarMenu.qml)
import QtQuick
import QtQuick.Layouts
import Quickshell

MouseArea {
    id: root
    required property var barWindow

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: CalendarMenu.toggle(barWindow)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Text {
            font.family: Theme.font
            font.pixelSize: Theme.barFontSize
            font.bold: true
            color: CalendarMenu.open || root.containsMouse ? Theme.accent : Theme.barText
            text: Qt.formatDateTime(clock.date, "dddd d MMM  HH:mm")
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // bell: off when do not disturb, with the count when there are notifications
        RowLayout {
            spacing: 3
            Text {
                font.family: Theme.font
                font.pixelSize: Theme.barFontSize + 2
                color: CalendarMenu.dnd ? Theme.barDim
                     : CalendarMenu.count > 0 ? Theme.accent
                     : Theme.barSubtext
                text: CalendarMenu.dnd ? "󰂛" : CalendarMenu.count > 0 ? "󱅫" : "󰂚"
            }
            Text {
                visible: CalendarMenu.count > 0 && !CalendarMenu.dnd
                font.family: Theme.font
                font.pixelSize: Theme.barFontSize - 1
                font.bold: true
                color: Theme.accent
                text: CalendarMenu.count
            }
        }
    }
}
