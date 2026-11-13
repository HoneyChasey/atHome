// Top bar, Omarchy style: a thin solid strip, monospace text, nerd font glyphs
// left: focused app icon (arch logo when nothing is focused), workspace numbers
// middle: date / time + notifications (click: calendar & notifications menu)
// right: background apps, bluetooth, wifi, ram, battery
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: Theme.barBg
    WlrLayershell.namespace: "quickshell-bar"

    RowLayout {
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 10
        Logo {}
        Workspaces {}
    }

    Clock {
        anchors.centerIn: parent
        barWindow: bar
    }

    RowLayout {
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 14
        Tray { barWindow: bar }
        Status { barWindow: bar }
    }
}
