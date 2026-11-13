// Workspace numbers, Omarchy style: 1-5 always shown, plus any other open workspace
// active: accent + underline / with windows: normal / empty: dim
// click: go to it, scroll: previous / next
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root
    spacing: 0

    readonly property var ids: {
        const set = new Set([1, 2, 3, 4, 5])
        for (const w of Hyprland.workspaces.values)
            if (w.id > 0) set.add(w.id)      // skip special workspaces
        return [...set].sort((a, b) => a - b)
    }

    Repeater {
        model: root.ids

        MouseArea {
            id: cell
            required property int modelData
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
            readonly property bool active: Hyprland.focusedWorkspace?.id === modelData
            readonly property bool occupied: (ws?.toplevels.values.length ?? 0) > 0

            implicitWidth: 22
            implicitHeight: Theme.barHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${modelData} })`)
            onWheel: wheel => Hyprland.dispatch(
                `hl.dsp.focus({ workspace = "${wheel.angleDelta.y > 0 ? "e-1" : "e+1"}" })`)

            Text {
                anchors.centerIn: parent
                text: cell.modelData
                font.family: Theme.font
                font.pixelSize: Theme.barFontSize
                font.bold: cell.active
                color: cell.active ? Theme.accent
                     : cell.occupied || cell.containsMouse ? Theme.barText
                     : Theme.barDim
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Rectangle {
                anchors { bottom: parent.bottom; bottomMargin: 3; horizontalCenter: parent.horizontalCenter }
                width: cell.active ? 12 : 0
                height: 2
                radius: 1
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }
    }
}
