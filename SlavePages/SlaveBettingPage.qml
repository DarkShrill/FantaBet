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


    // nome file configurabile
    property string betsFileName: "bets.json"

    // costruisce l'URL file:/// a partire da AppDir passato dal C++
    function betsFileUrl() {
        if (typeof AppDir !== "string" || AppDir.length === 0)
            return ""
        // normalizza backslash su Windows
        var base = AppDir.replace(/\\/g, "/")
        return "file:///" + base + "/" + betsFileName
    }

    function loadBetsFromFile() {
        var url = betsFileUrl()
        if (!url) {
            console.warn("AppDir non impostato: uso bets di default")
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Per file:// alcuni sistemi ritornano status 0; accetta anche 200
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (Array.isArray(data) && data.every(function (x) { return typeof x === "number" })) {
                            page.bets = data
                            console.log("BETS caricati da", url, "→", JSON.stringify(page.bets))
                        } else {
                            console.warn("Formato bets.json non valido, uso default")
                        }
                    } catch(e) {
                        console.warn("Errore parse bets.json:", e)
                    }
                } else {
                    console.warn("Impossibile leggere", url, "status:", xhr.status)
                }
            }
        }
        xhr.send()
    }

    Component.onCompleted: loadBetsFromFile()

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
