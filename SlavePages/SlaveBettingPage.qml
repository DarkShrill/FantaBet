// BettingPage.qml — Qt 5.12
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12


Page {
    id: page
    title: qsTr("Scegli la puntata")
    background: Rectangle { color: "#0f1921" }

    // valori delle puntate
    property var bets: [5, 10, 20, 50, 100, 200]
    property var udpSlave

    GridLayout {
        id: grid
        anchors.centerIn: parent
        rows: 2
        columns: 3
        rowSpacing: 20
        columnSpacing: 20

        Repeater {
            model: page.bets
            delegate: Rectangle {
                width: 100; height: 100
                radius: 12
                color: "#142430"
                border.color: "#2b3b48"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "+" + modelData + " €"
                    color: "white"
                    font.pixelSize: 22
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        console.log("Hai scelto la puntata:", modelData)
                        // TODO: collega al tuo peopleModel o logica di gioco
                        udpSlave.sendBid(modelData)
                    }

                    // effetto hover / press
                    onPressed: parent.color = "#1f3547"
                    onReleased: parent.color = "#142430"
                }
            }
        }
    }
}
