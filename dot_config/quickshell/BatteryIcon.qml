// macOS-like battery icon: translucent outline and nub, solid fill for the level,
// green with a bolt when charging, red when low
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int percent: 100
    property bool charging: false
    property color color: Theme.barText

    readonly property bool low: percent <= 20 && !charging
    readonly property color fill: charging ? "#34c759" : low ? "#ff3b30" : color
    readonly property color outline: Qt.rgba(color.r, color.g, color.b, 0.4)

    implicitWidth: 27
    implicitHeight: 12

    // body
    Rectangle {
        id: body
        width: 24; height: 12
        anchors.verticalCenter: parent.verticalCenter
        radius: 3.5
        color: "transparent"
        border.width: 1
        border.color: root.outline

        // level
        Rectangle {
            x: 2; y: 2
            height: parent.height - 4
            width: Math.max(2, (parent.width - 4) * Math.min(100, Math.max(0, root.percent)) / 100)
            radius: 1.8
            color: root.fill
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }

    // nub
    Rectangle {
        x: body.width + 1
        width: 1.8; height: 4.5
        anchors.verticalCenter: parent.verticalCenter
        radius: 1
        color: root.outline
    }

    // charging bolt, centered on the body
    Shape {
        visible: root.charging
        width: 7; height: 10
        x: (body.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeColor: Qt.rgba(0, 0, 0, 0.35)   // thin rim so the bolt stays visible on the green fill
            strokeWidth: 0.6
            joinStyle: ShapePath.RoundJoin
            startX: 4.3; startY: 0
            PathLine { x: 0.3; y: 5.7 }
            PathLine { x: 3.2; y: 5.7 }
            PathLine { x: 2.6; y: 10 }
            PathLine { x: 6.7; y: 4.2 }
            PathLine { x: 3.8; y: 4.2 }
            PathLine { x: 4.3; y: 0 }
        }
    }
}
