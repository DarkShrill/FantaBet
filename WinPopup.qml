import QtQuick.Controls 2.5
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

Popup {
    id: winPopup
    modal: true
    focus: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    x: (parent.width  - width)  / 2
    y: (parent.height - height) / 2
    width: Math.min(420, parent.width - 40)
    height: 120

    background: Rectangle {
        radius: 14
        color: "#0f1921"
        border.color: "#2b3b48"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Label { text: qsTr("🟢 Asta conclusa"); color: "white"; font.pixelSize: 20; font.bold: true }

        // Riepilogo
        Column {
            spacing: 6
            Label {
                text: qsTr("Vincitore: ") + lastWho
                color: "#b5c9d8"; font.pixelSize: 16
            }
            Label {
                text: qsTr("Giocatore aggiudicato: ") + playerName
                color: "#b5c9d8"; font.pixelSize: 16
            }
            Label {
                text: qsTr("Prezzo finale: ") + lastTotal + " " + currency
                color: "#7FD1FF"; font.pixelSize: 18; font.bold: true
            }
        }

        Column {
            width: parent.width
            spacing: 12

            // --- Nuovo Round ---
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
                    text: qsTr("NUOVO ROUND")
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
                        winPopup.close()
                        timeLeft = maxSeconds
                        running = true
                        pulse.start()
                    }
                }
            }

            // --- Chiudi ---
            Rectangle {
                id: btnClose
                width: parent.width
                height: 48
                radius: 24
                color: btnCloseArea.containsMouse ? "#e85d5d" : "#d64545"
                border.color: "#992f2f"
                layer.enabled: true
                layer.effect: DropShadow {
                    anchors.fill: btnClose
                    source: btnClose
                    horizontalOffset: 0
                    verticalOffset: btnCloseArea.containsMouse ? 6 : 4
                    radius: btnCloseArea.containsMouse ? 18 : 12
                    samples: 32
                    color: "#55000000"
                }

                Text {
                    anchors.centerIn: parent
                    text: qsTr("CHIUDI")
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                }

                MouseArea {
                    id: btnCloseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: winPopup.close()
                }
            }
        }
    }
}
