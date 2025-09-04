import QtQuick 2.12
import QtQuick.Controls 2.5
import QtGraphicalEffects 1.12

Button {
    property string buttonText: ""
    property bool buttonEnabled: true
    property int buttonWidth: 160
    signal clicked()

    id: startBtn
    text: buttonText
    implicitWidth: buttonWidth
    implicitHeight: 44
    enabled: buttonEnabled
    font.bold: true

    // Contenuto del bottone → centrato
    contentItem: Item {
        anchors.fill: parent

        Text {
            anchors.centerIn: parent
            text: startBtn.text
            color: "white"
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Background con hover + ombra
    background: Rectangle {
        id: bg
        radius: height / 2
        anchors.fill: parent
        color: startBtn.enabled
               ? (startBtn.hovered ? "#35bfa3" : "#2A9D8F")
               : "#335a54"
        border.color: startBtn.enabled ? "#20816f" : "#1b3f3a"
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            anchors.fill: bg
            source: bg
            horizontalOffset: 0
            verticalOffset: startBtn.hovered ? 6 : 4
            radius: startBtn.hovered ? 18 : 12
            samples: 32
            color: "#55000000"
        }
    }
    // Area mouse per cambiare il cursore
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: startBtn.clicked()  // delega al Button
    }
    // Animazioni morbide
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    onPressed:  startBtn.scale = 0.96   // effetto pressione
    onReleased: startBtn.scale = 1.0
}
