// macOS-like wifi icon: a dot and three arcs drawn as vectors (not a font glyph),
// the arcs above the signal level are dimmed like on macOS
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property int bars: 3                 // 0..3 lit arcs above the dot
    property bool connected: true        // false = everything dimmed
    property color color: Theme.barText

    readonly property color dim: Qt.rgba(color.r, color.g, color.b, 0.3)
    readonly property real cx: 9
    readonly property real cy: 11.4

    implicitWidth: 18
    implicitHeight: 13
    preferredRendererType: Shape.CurveRenderer

    component Arc: ShapePath {
        id: arc
        property real radius
        property int level
        fillColor: "transparent"
        strokeWidth: 2
        capStyle: ShapePath.RoundCap
        strokeColor: root.connected && root.bars >= level ? root.color : root.dim
        PathAngleArc {
            centerX: root.cx; centerY: root.cy
            radiusX: arc.radius; radiusY: arc.radius
            startAngle: -135; sweepAngle: 90
        }
    }

    // dot
    ShapePath {
        strokeColor: "transparent"
        fillColor: root.connected ? root.color : root.dim
        PathAngleArc {
            centerX: root.cx; centerY: root.cy
            radiusX: 1.5; radiusY: 1.5
            startAngle: 0; sweepAngle: 360
        }
    }
    Arc { radius: 3.9;  level: 1 }
    Arc { radius: 7.25; level: 2 }
    Arc { radius: 10.6; level: 3 }
}
