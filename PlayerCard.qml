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

    radius: 10
    color: "#141e26"
    border.color: "#22323f"
    border.width: 1
    clip: true

    // avatarModel tondo
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

    // Blocco testo a destra con larghezza corretta
    Column {
        anchors.left: avatarModelHolder.right
        anchors.leftMargin: 10
        anchors.right: parent.right         // <-- dà width al Column
        anchors.rightMargin: 12
        anchors.verticalCenter: avatarModelHolder.verticalCenter
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
