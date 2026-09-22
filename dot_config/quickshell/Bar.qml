// Bar composing
import QtQuick
import Quickshell
import Quickshell.Hyprland
PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "transparent"          // wallpaper shows through the bar
    // ---- left island baby ----
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: leftRow.implicitWidth + 16
        implicitHeight: leftRow.implicitHeight + 12
        radius: 8
        color: "#1e1e2e"
        Row {
            id: leftRow
            anchors.centerIn: parent
            spacing: 10
            Logo { anchors.verticalCenter: parent.verticalCenter }
            Workspaces { anchors.verticalCenter: parent.verticalCenter }
        }
    }
    // ---- center clock island baby----
    Rectangle {
        anchors.centerIn: parent
        implicitWidth: clock.implicitWidth + 24
        implicitHeight: 26
        radius: 8
        color: "#1e1e2e"
        Clock {
            id: clock
            anchors.centerIn: parent
        }
    }
    // ---- right island baby ---
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: rightRow.implicitWidth + 16
        implicitHeight: rightRow.implicitHeight + 12
        radius: 8
        color: "#1e1e2e"
        Row {
            id: rightRow
            anchors.centerIn: parent
            spacing: 12
            Network { anchors.verticalCenter: parent.verticalCenter }
            System { anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
