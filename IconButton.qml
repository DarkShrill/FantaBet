import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQml 2.12
import QtQuick.Controls 2.12




Item {
    id: root
    property alias iconSource: icon.source
    property string label: ""
    signal clicked()

    width: 160; height: 180

    // Ombra (sotto al background)
    DropShadow {
        anchors.fill: bg
        source: bg
        horizontalOffset: 0
        verticalOffset: hovered ? 8 : 4
        radius: hovered ? 24 : 16
        samples: 32
        color: hovered ? "#55000000" : "#40000000"
        cached: true
    }

    // Card
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 16
        color: hovered ? "#1c2730" : "#192229"
        border.color: hovered ? "#2b3b48" : "#20303c"
        border.width: 1
    }

    // Immagine centrata
    Image {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -10
        sourceSize.width: 72
        sourceSize.height: 72
        fillMode: Image.PreserveAspectFit
        mipmap: true
        smooth: true

    }

    // Testo in basso al centro
    Text {
        id: caption
        text: root.label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        font.pixelSize: 16
        color: hovered ? "white" : "#e8f0f6"
    }

    // Hover/click handler
    property bool hovered: false

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.scale = 0.98
        onReleased: root.scale = 1.0
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
    }

    // Transizioni morbide
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on hovered { NumberAnimation { duration: 120 } }
}
