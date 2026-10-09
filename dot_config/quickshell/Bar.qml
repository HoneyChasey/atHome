// Bar composing
import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 42
    color: "transparent"          // wallpaper shows through the bar

    // rounded pill holding a row of widgets
    component Island: Rectangle {
        default property alias content: row.data
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: row.implicitWidth + 24
        implicitHeight: Theme.islandHeight
        radius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: Theme.surface
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 12
        }
    }

    // thin vertical line between groups
    component Separator: Rectangle {
        implicitWidth: 1
        implicitHeight: 14
        color: Theme.surface
    }

    // ---- left island: logo, workspaces, date & time ----
    Island {
        anchors.left: parent.left
        anchors.leftMargin: 10
        Logo {}
        Workspaces {}
        Separator {}
        Clock {}
    }

    // ---- right island: network, vpn, system, background apps ----
    Island {
        anchors.right: parent.right
        anchors.rightMargin: 10
        Network {}
        Separator {}
        System {}
        Separator { visible: tray.visible }
        Tray { id: tray; barWindow: bar }
        Separator {}
        // control center button
        Text {
            font.family: Theme.font
            font.pixelSize: 15
            color: ControlCenter.open ? Theme.accent : Theme.text
            text: "󰔡"
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: ControlCenter.toggle(bar)
            }
        }
    }
}
