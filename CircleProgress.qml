// CircleProgress.qml
import QtQuick 2.12
import QtQuick.Shapes 1.12

Item {
    id: ring
    // API del componente
    property real progress: 0.0              // 0..1
    property bool running: false
    property real thickness: 18
    property real pad: 3
    property color baseColor: "#1f2a33"
    property color progressColor: running ? "#2A9D8F" : "#496a63"
    property color innerColor: "#121b22"
    property real startAngle: -90            // in gradi; -90 = ore 12

    // espongo anche l'innerSize, così puoi centrare testi dentro
    readonly property real radius: Math.min(width, height)/2 - (thickness/2) - pad
    readonly property real innerSize: Math.max(0, (radius - thickness) * 2)

    // Cerchio base
    Shape {
        anchors.fill: parent
        layer.enabled: true
        ShapePath {
            strokeWidth: ring.thickness
            strokeColor: ring.baseColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: width/2; centerY: height/2
                radiusX: ring.radius; radiusY: ring.radius
                startAngle: 0; sweepAngle: 360
            }
        }
    }

    // Arco di progresso
    Shape {
        anchors.fill: parent
        layer.enabled: true
        ShapePath {
            strokeWidth: ring.thickness
            strokeColor: ring.progressColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: width/2; centerY: height/2
                radiusX: ring.radius; radiusY: ring.radius
                startAngle: ring.startAngle
                sweepAngle: 360 * Math.max(0, Math.min(1, ring.progress))
            }
        }
    }

    // Disco interno
    Rectangle {
        width: ring.innerSize
        height: width
        radius: width/2
        color: ring.innerColor
        anchors.centerIn: parent
    }
}
