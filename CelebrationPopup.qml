// CelebrationPopup.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Particles 2.12
import QtGraphicalEffects 1.0

Popup {
    id: root
    modal: true
    focus: true
    dim: true
    closePolicy: Popup.NoAutoClose

    // API
    property url imageSource: ""          // immagine dentro al cerchio
    property int durationMs: 2000         // durata di visualizzazione
    signal finished()

    function celebrate(src, ms) {
        if (src !== undefined) root.imageSource = src
        if (ms   !== undefined) root.durationMs = ms
        open()
    }

    // dimensioni e centratura
    width: parent ? parent.width  : 640
    height: parent ? parent.height : 480
    x: 0; y: 0

    background: Rectangle { color: "transparent" }

    // Chiudi dopo durationMs
    Timer {
        id: autoClose
        interval: root.durationMs
        running: false; repeat: false
        onTriggered: { root.close(); root.finished() }
    }

    // Effetto: leggera animazione di ingresso sull’avatar
    enter: Transition {
        NumberAnimation { properties: "opacity,scale"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { properties: "opacity,scale"; from: 1; to: 0.98; duration: 100; easing.type: Easing.InCubic }
    }

    // Contenuto
    Item {
        anchors.fill: parent

        // Sistema particellare (fuochi)
        ParticleSystem { id: ps }

        // Emitter "esplosione" (radiale)
        Emitter {
            id: boom
            system: ps
            anchors.centerIn: parent
            emitRate: 0
            lifeSpan: 1200
            size: 4; sizeVariation: 3
            endSize: 1
            velocity: AngleDirection {
                angle: 0; angleVariation: 360
                magnitude: 220; magnitudeVariation: 140
            }
            acceleration: AngleDirection { angle: 90; magnitude: 60; angleVariation: 30 } // un po' di gravità
        }

        // Emitter "scintille" leggere e continue
        Emitter {
            id: sparkles
            system: ps
            anchors.centerIn: parent
            emitRate: 0
            lifeSpan: 900
            size: 3; sizeVariation: 2
            velocity: AngleDirection {
                angle: 0; angleVariation: 360
                magnitude: 120; magnitudeVariation: 80
            }
        }

        // Renderer particelle (metti un piccolo PNG tondo bianco 6x6 in qrc)
        ImageParticle {
            system: ps
            source: "qrc:/round.png" // <— aggiungi l’asset (piccolo cerchietto bianco)
            color: "#ffffff"
            colorVariation: 0.9
            alpha: 0.95
            entryEffect: ImageParticle.Fade
        }

        // Cerchio con immagine al centro
        Item {
            id: avatarContainer
            width: 160; height: 160
            anchors.centerIn: parent
            property bool hasPhoto: root.imageSource && root.imageSource !== ""

            // Pop animation
            SequentialAnimation on scale {
                running: root.opened
                NumberAnimation { from: 0.9; to: 1.05; duration: 140; easing.type: Easing.OutBack }
                NumberAnimation { from: 1.05; to: 1.0; duration: 120; easing.type: Easing.OutQuad }
            }

            // Sorgente immagine (non disegnata direttamente)
            Image {
                id: avatarImage
                anchors.fill: parent
                source: root.imageSource
                fillMode: Image.PreserveAspectCrop
                visible: false
                cache: false
                smooth: true
            }

            // Maschera circolare (sorgente della maschera)
            Rectangle {
                id: circleMask
                anchors.fill: parent
                radius: width / 2
                visible: false
            }

            // Effetto: crop circolare vero
            OpacityMask {
                id: maskedAvatar
                anchors.fill: parent
                source: avatarImage
                maskSource: circleMask
                visible: avatarContainer.hasPhoto
                antialiasing: true
            }

            // Cerchio di sfondo + bordo (sotto all’immagine)
            Rectangle {
                id: circleBg
                anchors.fill: parent
                radius: width / 2
                color: "white"            // sfondo del cerchio
                border.color: "#2b3b48"   // anello
                border.width: 2
                z: -1
            }

            // Ombra morbida del cerchio
            DropShadow {
                anchors.fill: circleBg
                source: circleBg
                horizontalOffset: 0
                verticalOffset: 6
                radius: 24
                samples: 32
                color: "#66000000"
                transparentBorder: true
                z: -2
            }

            // Fallback se non c’è immagine: iniziale dentro al cerchio
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#12202b"
                border.color: "#2b3b48"
                border.width: 1
                visible: !avatarContainer.hasPhoto

                Text {
                    anchors.centerIn: parent
                    text: (typeof homePage !== "undefined" && homePage.playerName && homePage.playerName.length > 0)
                            ? homePage.playerName.charAt(0).toUpperCase() : "?"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 72
                }
            }
        }

        // Timer che genera i fuochi (burst iniziali + un paio di “raffiche”)
        Timer {
            id: fireworks
            interval: 250; repeat: true; running: false
            property int shots: 0
            onTriggered: {
                // esplosione principale
                boom.burst(220 + Math.floor(Math.random() * 120))
                // scintille di contorno
                sparkles.burst(120 + Math.floor(Math.random() * 80))
                shots++
                if (shots >= 5) stop()
            }
            onRunningChanged: if (!running) shots = 0
        }
    }

    onOpened: {
        autoClose.start()
        // primo colpo subito
        boom.burst(260)
        sparkles.burst(140)
        fireworks.start()
    }
}
