import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

Rectangle {
    id: card
    property string firstNameModel: ""
    property string lastNameModel: ""
    property string fullNameModel: ""
    property alias name: nameLabel.text
    property url avatarModel: ""
    property color accentColorModel: "#7FD1FF"

    property bool hasPhoto: avatarModel.toString() !== ""

    radius: 10
    color: "#141e26"
    border.color: "#22323f"
    border.width: 1
    clip: true

    // avatarModel tondo
    // Avatar circolare
    Item {
        id: avatarContainer
        Layout.alignment: Qt.AlignHCenter
        width: 96; height: 96

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12

        // Componi iniziali dinamiche
        property string initials: {
            var n = firstNameModel
            var s = lastNameModel
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
            source:  avatarModel
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

    }
    /*
    Rectangle {
        id: avatarModelHolder
        width: 52; height: 52
        radius: width/2
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12
        color: "#0e151b"
        border.color: "#2b3b48"
        antialiasing: true
        clip: true

        Image {
            id: avatarModelImg
            width: 32; height: 32
            source: avatarModel && avatarModel !== "" ? avatarModel : "qrc:/avatar.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            anchors.centerIn: parent
        }


        // Fallback iniziali se immagine mancante/non caricata
        Text {
            anchors.centerIn: parent
            visible: avatarModelImg.status !== Image.Ready
            text: (firstNameModel ? firstNameModel[0] : "") + (lastNameModel ? lastNameModel[0] : "")
            color: "#9fb3c4"
            font.bold: true
            font.pixelSize: 18
        }
    }
    */

    // Blocco testo a destra con larghezza corretta
    Column {
        anchors.left: avatarContainer.right
        anchors.leftMargin: 10
        anchors.right: parent.right         // <-- dà width al Column
        anchors.rightMargin: 12
        anchors.verticalCenter: avatarContainer.verticalCenter
        spacing: 8

        // Sfondo bianco dietro al nome
        Rectangle {
            id: nameBg
            color: "white"
            radius: 6
            height: nameLabel.implicitHeight + 8
            anchors.left: parent.left
            anchors.right: parent.right

            Label {
                id: nameLabel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: fullNameModel && fullNameModel.length ? fullNameModel : (firstNameModel + " " + lastNameModel)
                color: "black"                 // testo nero su sfondo bianco
                font.pixelSize: 16
                elide: Text.ElideRight
                width: parent.width - 12       // padding orizzontale
            }
        }

        // Barretta colorata (accent)
        Rectangle {
            width: 44; height: 4; radius: 2
            color: card.accentColorModel
        }
    }

    // Linea inferiore
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#20303c"
    }
}
