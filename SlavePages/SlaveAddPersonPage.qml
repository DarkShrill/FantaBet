// AddPersonPage.qml — Qt 5.12
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtQuick.Dialogs 1.0
import QtMultimedia 5.12
import QtGraphicalEffects 1.12

import "qrc:/"
import App 1.0
import Network 1.0

Page {
    id: page
    title: qsTr("Nuovo contatto")
    background: Rectangle { color: "#0f1921" }

    /* ====== State ====== */
    property url avatarSource: ""
    property bool hasPhoto: avatarSource.toString() !== ""


    UdpSlave {
        id: slave
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 18

        Item { Layout.fillWidth: true; height: 8 } // spacer top

        // Avatar circolare
        Item {
            id: avatarContainer
            Layout.alignment: Qt.AlignHCenter
            width: 140; height: 140

            // Componi iniziali dinamiche
            property string initials: {
                var n = nameField.text
                var s = surnameField.text
                var ini = ""
                if (n && n.length > 0)
                    ini += n.charAt(0).toUpperCase()
                if (s && s.length > 0)
                    ini += s.charAt(0).toUpperCase()
                return ini
            }

            // L'immagine originale (nascosta): serve come sorgente della maschera
            Image {
                id: avatarImage
                anchors.fill: parent
                source: page.avatarSource
                fillMode: Image.PreserveAspectCrop
                visible: false              // non disegnare direttamente
                cache: false
            }

            // Maschera circolare
            Rectangle {
                id: circleMask
                anchors.fill: parent
                radius: width / 2
                visible: false              // è solo una sorgente per la maschera
            }

            // Effetto di maschera: qui avviene il vero crop circolare
            OpacityMask {
                id: maskedAvatar
                anchors.fill: parent
                source: avatarImage
                maskSource: circleMask
                visible: hasPhoto
                antialiasing: true
            }

            // Sfondo scuro e bordo (sotto al maskedAvatar per avere un anello pulito)
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#12202b"
                border.color: "#2b3b48"
                border.width: 1
                z: -1
            }

            // Placeholder (opzionale) quando non c'è foto
            Label {
                anchors.centerIn: parent
                visible: !hasPhoto
                text: avatarContainer.initials
                color: "white"
                font.pixelSize: 40
                font.bold: true
            }

            // Badge tondo bianco con camera, in basso a destra DENTRO il cerchio
            Rectangle {
                id: chooseBadge
                width: 36; height: 36
                radius: width/2
                color: "white"
                border.color: "#E5EAF0"
                border.width: 1
                anchors.right: avatarImage.right
                anchors.bottom: avatarImage.bottom
                anchors.rightMargin: 6          // dentro il cerchio
                anchors.bottomMargin: 6
                z: 10
                opacity: hasPhoto ? 0.95 : 1.0  // sempre visibile (anche con foto)

                // ombra (se non vuoi, rimuovi layer.*)
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 10; samples: 17
                    horizontalOffset: 0; verticalOffset: 1
                    color: "#33000000"
                }

                // Iconcina camera (usa la tua immagine se preferisci)
                Image { anchors.centerIn: parent; source: "qrc:/camera.png"; width: 32; height: 32; fillMode: Image.PreserveAspectFit }


                // click sul badge → menu scelta
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pickMenu.open()
                }
            }

            // click anche su tutto il cerchio
            MouseArea {
                anchors.fill: avatarImage
                cursorShape: Qt.PointingHandCursor
                onClicked: pickMenu.open()
            }
        }

        // Nome / Cognome
        TextField {
            id: nameField
            Layout.fillWidth: true
            placeholderText: qsTr("Nome")
            color: "white"
            selectionColor: "#2aa7ff"
            background: Rectangle { radius: 10; color: "#142430"; border.color: "#2b3b48" }
        }

        TextField {
            id: surnameField
            Layout.fillWidth: true
            placeholderText: qsTr("Cognome")
            color: "white"
            selectionColor: "#2aa7ff"
            background: Rectangle { radius: 10; color: "#142430"; border.color: "#2b3b48" }
        }

        Item { Layout.fillHeight: true } // spinge il bottone in basso
    }

    /* ====== Bottone centrato in basso ====== */
    CustomButton {
        id: saveBtn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        text: qsTr("Salva")
        enabled: nameField.text.length > 0 && surnameField.text.length > 0
        onClicked: {
            // TODO: salva i dati


            slaveStack.push(Qt.resolvedUrl("SlaveBettingPage.qml"), {
                udpSlave: slave
            })

            slave.start(nameField.text, surnameField.text, page.avatarSource)
        }
    }

    /* ====== Menu scelta foto ====== */
    Menu {
        id: pickMenu
        modal: true
        MenuItem { text: qsTr("Scegli dalla galleria"); onTriggered: fileDialog.open() }
        MenuItem { text: qsTr("Scatta una foto"); onTriggered: cameraDialog.open() } // niente start qui
    }

    /* ====== Galleria (FileDialog Qt5) ====== */
    FileDialog {
        id: fileDialog
        title: qsTr("Scegli un'immagine")
        nameFilters: [ "Immagini (*.png *.jpg *.jpeg *.bmp *.gif)" ]
        selectExisting: true
        onAccepted: {
            // QtQuick.Dialogs 1.x usa fileUrl (singolo) o fileUrls (lista)
            page.avatarSource = fileUrl
        }
    }

    /* ====== Fotocamera (QtMultimedia 5.12) ====== */
    Popup {
        id: cameraDialog
        modal: true
        focus: true
        visible: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: parent.width
        height: parent.height
        background: Rectangle { color: "#0f1921"; radius: 14; border.color: "#2b3b48" }

        // Contenuto caricato SOLO quando il popup è aperto
        Loader {
            id: camLoader
            anchors.fill: parent
            active: cameraDialog.visible
            sourceComponent: cameraSheet
        }
    }

    // Tutto l'UI della camera qui dentro (viene creato/distrutto dal Loader)
    Component {
        id: cameraSheet
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label { text: qsTr("Scatta una foto"); color: "white"; font.pixelSize: 18 }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#0b141b"
                border.color: "#243543"
                clip: true

                VideoOutput {
                    id: viewfinder
                    anchors.fill: parent
                    // ⚠️ colleghiamo la sorgente SOLO quando la camera è attiva
                    source: camera
                    fillMode: VideoOutput.PreserveAspectCrop
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Button { text: qsTr("Annulla"); Layout.fillWidth: true; onClicked: cameraDialog.close() }
                Button { text: qsTr("Scatta");  Layout.fillWidth: true; onClicked: camera.imageCapture.capture() }
            }

            // Camera esiste SOLO dentro al foglio
            Camera {
                id: camera
                captureMode: Camera.CaptureStillImage
//                active: true                    // attiva solo mentre il componente esiste
                // niente forzature di resolution/fps: lascia scegliere al driver
                imageCapture {
                    id: imageCapture
                    onImageSaved: function(requestId, fileName) {
                        page.avatarSource = (Qt.platform.os === "windows" ? "file:///" : "file://") + fileName
                        cameraDialog.close()
                    }
                }
            }
        }
    }
}
