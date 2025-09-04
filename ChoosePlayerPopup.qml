import QtQuick.Controls 2.5
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12


Popup {
    id: playerNameDlg
    modal: true
    focus: true
    dim: true
    x: (parent.width  - width)  / 2
    y: (parent.height - height) / 2
    width: Math.min(420, parent.width - 40)
    height: 180

    closePolicy: Popup.NoAutoClose

    background: Rectangle {
        radius: 14
        color: "#0f1921"
        border.color: "#2b3b48"
    }

    signal accepted(string name)

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Label {
            text: qsTr("Scegli giocatore")
            color: "white"
            font.pixelSize: 20
            font.bold: true
        }

        TextField {
            id: nameField
            placeholderText: qsTr("Nome giocatore")
            text: ""
            selectByMouse: true
            focus: true
            background: Rectangle { radius: 8; color: "#12212a"; border.color: "#254050" }
            color: "white"
            width: parent.width
            height: 32
        }


        Rectangle {
            id: btnNew
            width: parent.width
            height: 48
            radius: 24
            color: btnNewArea.containsMouse ? "#35bfa3" : "#2A9D8F"
            border.color: "#20816f"
            layer.enabled: true
            layer.effect: DropShadow {
                anchors.fill: btnNew
                source: btnNew
                horizontalOffset: 0
                verticalOffset: btnNewArea.containsMouse ? 6 : 4
                radius: btnNewArea.containsMouse ? 18 : 12
                samples: 32
                color: "#55000000"
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("Vai!")
                color: "white"
                font.bold: true
                font.pixelSize: 16
            }

            MouseArea {
                id: btnNewArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    accepted(nameField.text)
                    playerNameDlg.close()
                }
            }
        }
    }

    onOpened: nameField.forceActiveFocus()

}
