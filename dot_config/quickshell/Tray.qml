// Background apps (system tray), like the macOS menu bar
// left click: open app / menu, middle click: secondary action, right click: menu
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    required property var barWindow
    spacing: 8
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item
            required property SystemTrayItem modelData
            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            function openMenu() {
                const p = item.mapToItem(null, 0, item.height + 10)
                modelData.display(root.barWindow, p.x, p.y)
            }

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate()
                else if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) openMenu()
                } else modelData.activate()
            }
            onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
