// MasterWaitingRoomPage.qml
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQml 2.12

import "qrc:/"
import App 1.0
import Network 1.0

Page {
    id: root
    property var playersModel: Players       // <-- inietta qui il tuo modello C++
    signal startRequested()
    property var masterHomePageInstance: null

    background: Rectangle { color: "#101417" }//

    UdpMaster {
        id: master

        onPeopleReceived: {
            // Ogni volta che uno slave si registra lo porto immediatamente nel modello dei player.
            for (var i = 0; i < payload.length; ++i) {
                var p = payload[i]
                Players.appendMimimal(p.firstName, p.lastName, p.photo, unique_id)
            }
        }

        onBidReceived: {
            if(checkRunning())
                Bids.appendBid(who, amount, (new Date()).getTime())
        }

//        onSen
    }

    // Mock locale (solo per preview se non hai ancora il modello C++)
    ListModel {
        id: mockModel
        ListElement { firstName: "Mario";  lastName: "Rossi";  avatar: "qrc:/avatar.png"; accentHue: 0.0}
        ListElement { firstName: "Luca";   lastName: "Bianchi";avatar: "qrc:/avatar.png"; accentHue: 0.12}
        ListElement { firstName: "Anna";   lastName: "Verdi";  avatar: "qrc:/avatar.png"; accentHue: 0.24}
        ListElement { firstName: "Giulia"; lastName: "Neri";   avatar: "qrc:/avatar.png"; accentHue: 0.36}
        ListElement { firstName: "Giulia"; lastName: "Neri";   avatar: "qrc:/avatar.png"; accentHue: 0.48}
        ListElement { firstName: "Giulia"; lastName: "Neri";   avatar: "qrc:/avatar.png"; accentHue: 0.60}
        ListElement { firstName: "Giulia"; lastName: "Neri";   avatar: "qrc:/avatar.png"; accentHue: 0.72}
    }

    // Sceglie quale model usare
    readonly property var modelToUse: playersModel ? playersModel : mockModel // fallback comodo per test rapidi
    readonly property int peopleCount: modelToUse ? modelToUse.count : 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header titolo + contatore
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: qsTr("Persone collegate:")
                color: "white"
                font.pixelSize: 18
            }
            Label {
                text: peopleCount
                color: "#7FD1FF"
                font.pixelSize: 18
                font.bold: true
            }
            Item { Layout.fillWidth: true }
        }

        // Contenitore griglia scrollabile
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(0, root.height - 132)
            radius: 12
            color: "#0f1921"
            border.color: "#20303c"
            border.width: 1

            // Ombra soft
            DropShadow {
                anchors.fill: parent
                source: parent
                radius: 16
                samples: 32
                horizontalOffset: 0
                verticalOffset: 6
                color: "#30000000"
            }

//            ScrollView {
//                anchors.fill: parent
//                clip: true

            GridView {
                id: grid
                anchors.fill: parent
                model: modelToUse
                interactive: true
                cellWidth: Math.floor((width - (columns - 1) * spacing) / columns)
                cellHeight: 120
                boundsBehavior: Flickable.DragAndOvershootBounds
                cacheBuffer: 400
                //spacing: 12

                // colonne adattive: tra 2 e 4, basate sulla radice del count
                readonly property int columns: {
                    var c = Math.ceil(Math.sqrt(Math.max(peopleCount, 1)))
                    c = Math.min(4, Math.max(2, c))
                    return c
                }

                delegate: PlayerCard {
                    width: grid.cellWidth
                    height: grid.cellHeight
                    // Palette diversa per giocatore (se non hai un colore dal modello)
                    accentColorModel: (accentHue !== "undefined" && accentHue !== "")
                                 ? Qt.hsla(accentHue, 0.6, 0.5, 1.0)
                                 : Qt.hsla((index * 0.12) % 1.0, 0.6, 0.5, 1.0)

                    // Ruoli dal tuo modello C++
                    firstNameModel: (firstName !== "undefined") ? firstName : ""
                    lastNameModel:  (lastName  !== "undefined") ? lastName  : ""
                    fullNameModel:  (fullName  !== "undefined") ? fullName  : (firstName + " " + lastName)
                    avatarModel:    (avatar    !== "undefined") ? avatar    : ""
                }
            }
//            }
        }

        // Bottone INIZIA centrato
        Item { Layout.fillWidth: true;  } // spacer

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            CustomButton{
                buttonText: "Avanti"
                buttonEnabled: peopleCount > 0
                onClicked: {
                    // apri una sottopagina
                    masterHomePageInstance = masterStack.push(Qt.resolvedUrl("MasterHomePage.qml"), {
                        someParam: 123,
                        pageTitle: "Dettagli"
                    })
                }
            }
        }
        Item { Layout.fillWidth: true; height: 16 } // spacer
    }

    function checkRunning(){
        if(masterHomePageInstance){
            return masterHomePageInstance.running
        }
        return false;
    }
}
