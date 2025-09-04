// MasterHomePage.qml
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import App 1.0
import "qrc:/"

Page {
    id: homePage
    background: Rectangle { color: "#0f1921" }

    /* ====== Props ====== */
    property string  playerName: ""
    property int     maxSeconds: 5
    property real    timeLeft:   maxSeconds
    property bool    running:    false
    property string  currency:   "€"

    // Modello C++ (iniettalo dall’esterno: es. context property "BidsModel")
    property var bidsModel: Bids

    signal roundStarted(string player)
    signal roundEnded(string player, int finalBid)

    // ultima puntata (il modello inserisce in testa → riga 0)
    readonly property var    lastBid:   (bidsModel && bidsModel.count > 0) ? bidsModel.get(0) : null
    readonly property string lastWho:   lastBid ? lastBid.who   : qsTr("—")
    readonly property int    lastTotal: lastBid ? lastBid.total : 0

    /* ====== Funzioni ====== */
    function startCountdown(resetToMax) {
        if (resetToMax === undefined) resetToMax = true
        countdownAnim.stop()
        if (resetToMax) {
            homePage.timeLeft = homePage.maxSeconds
        }
        countdownAnim.from = homePage.timeLeft
        countdownAnim.to = 0
        countdownAnim.duration = Math.max(1, homePage.timeLeft * 1000) // ms
        pulse.start()
        countdownAnim.start()
        homePage.running = true
        homePage.roundStarted(homePage.playerName)
    }

    function pauseCountdown() {
        if (countdownAnim.running) {
            countdownAnim.pause()
        }
        homePage.running = false
    }

    function resumeCountdown() {
        if (countdownAnim.paused) {
            countdownAnim.resume()
            homePage.running = true
        } else if (!countdownAnim.running && homePage.timeLeft > 0) {
            // safety: riparte da dove era
            startCountdown(false)
        }
    }

    function stopCountdownToEnd() {
        countdownAnim.stop()
        homePage.timeLeft = 0
        homePage.running = false
        winPopup.open()
        homePage.roundEnded(homePage.playerName, currentTotal)
    }

    /* ====== Animazione countdown ====== */
    NumberAnimation {
        id: countdownAnim
        target: homePage
        property: "timeLeft"
        from: homePage.maxSeconds
        to: 0
        duration: homePage.maxSeconds * 1000
        easing.type: Easing.Linear

        // Se fermata naturalmente → fine round
        onStopped: {
            // se si è fermata perché ha finito (non per pausa)
            if (!countdownAnim.paused && homePage.timeLeft <= 0.001) {
                homePage.running = false
                winPopup.open()
                if(lastBid.photo !== ""){
                    celebration.celebrate(lastBid.photo, 2000)
                }
                homePage.roundEnded(homePage.playerName, currentTotal)
            }
        }
    }

    WinPopup {
        id: winPopup
        onNewRoundClicked: function () {
            homePage.timeLeft = homePage.maxSeconds
            homePage.running = false
            choosePlayerPopup.open()
        }
    }

    CelebrationPopup {
        id: celebration
        onFinished: {
        }
    }

    ChoosePlayerPopup {
        id: choosePlayerPopup
        onAccepted: function(n) {
            homePage.playerName = n || ""     // evita undefined
            homePage.timeLeft = homePage.maxSeconds
            homePage.running = false
            if (bidsModel && bidsModel.clear) bidsModel.clear()  // usa l’istanza
            choosePlayerPopup.close()
        }
    }

    /* Totale corrente (se il modello fornisce "total", uso l'ultima riga; altrimenti sommo i amount) */
    readonly property int currentTotal: {
        if (!bidsModel || !bidsModel.count) return 0
        var row0 = 0 // più recente in alto
        var itm = bidsModel.get ? bidsModel.get(row0) : null
        if (itm && itm.total !== undefined) return itm.total
        var s = 0
        for (var i = 0; i < bidsModel.count; i++) {
            var it = bidsModel.get(i)
            if (it && it.amount !== undefined) s += it.amount
        }
        return s
    }

    /* Reset/Start su nuova puntata dal C++ */
    Connections {
        target: bidsModel
        ignoreUnknownSignals: true

        onRowsInserted: {
            // nuova bid → reset e riparti
            homePage.timeLeft = homePage.maxSeconds
            circle.requestPaint()
            startCountdown(true)
        }

        onModelReset: {
            homePage.timeLeft = homePage.maxSeconds
            homePage.running = false
            circle.requestPaint()
        }
    }

    // Quando questa Page diventa attiva nello StackView
    StackView.onStatusChanged: {
        if (StackView.status === StackView.Active) {
            choosePlayerPopup.open()
        }
    }

    /* ====== Layout ====== */
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Intestazione sopra il cerchio
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: qsTr("Puntata per")
                color: "#b5c9d8"
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            // --- chip col nome ---
            Rectangle {
                id: playerChip
                radius: 8
                color: "white"

                // Usa implicit size così RowLayout non lo schiaccia a 0
                implicitHeight: titleLbl.implicitHeight + 8
                implicitWidth:  titleLbl.implicitWidth  + 18

                // Limiti di layout (ok tenerli)
                Layout.maximumWidth: homePage.width * 0.6
                Layout.alignment: Qt.AlignVCenter

                // Se vuoi evitare “sparizioni” quando la stringa è momentaneamente vuota:
                Layout.minimumWidth: 80  // o quello che preferisci

                // Mostralo solo se c’è un nome
                visible: homePage.playerName && homePage.playerName.length > 0

                Label {
                    id: titleLbl
                    anchors.fill: parent
                    anchors.margins: 9
                    text: homePage.playerName
                    color: "black"
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap        // importante: niente a capo, solo elide
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            /* --- Centro: cerchio timer/bid --- */
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: 360; implicitHeight: 360

                readonly property int size: Math.min(width, height) - 24

                // flash verde
                Rectangle {
                    id: pulse
                    anchors.centerIn: parent
                    width: parent.size; height: width; radius: width / 2
                    color: "#2ecc71"; opacity: 0; scale: 0.9

                    SequentialAnimation on opacity {
                        id: pulseAnim
                        running: false
                        NumberAnimation { from: 0.25; to: 0.0; duration: 400; easing.type: Easing.OutQuad }
                    }
                    SequentialAnimation on scale {
                        running: pulseAnim.running
                        NumberAnimation { from: 0.9; to: 1.1; duration: 400; easing.type: Easing.OutQuad }
                    }
                    function start() { pulseAnim.running = true }
                }

                Connections {
                    target: homePage
                    onTimeLeftChanged: circle.requestPaint()
                    onRunningChanged:  circle.requestPaint()
                }


                // === Cerchio GPU (Shapes) ===
                /*
                CircleProgress {
                    id: circle
                    anchors.centerIn: parent
                    width: parent.size
                    height: parent.size

                    progress: (homePage.maxSeconds > 0) ? (homePage.timeLeft / homePage.maxSeconds) : 0
                    running: homePage.running
                    thickness: 18
                    pad: 3
                    baseColor: "#1f2a33"
                    progressColor: homePage.running ? "#2A9D8F" : "#496a63"
                    innerColor: "#121b22"
                    startAngle: -90
                }
                */
                Canvas {
                    id: circle
                    anchors.centerIn: parent
                    width: parent.size
                    height: parent.size

                    // Ottimizzazioni: GPU + thread separato
                    renderTarget: Canvas.FramebufferObject
                    renderStrategy: Canvas.Threaded

                    // === parametri esposti per riuso ===
                    property real lw: 18
                    property real pad: 3
                    property real radius: Math.min(width, height) / 2 - (lw / 2) - pad
                    property real innerSize: Math.max(0, (radius - lw) * 2)

                    onPaint: {
                        var ctx = getContext("2d")
                        var w = width, h = height, cx = w / 2, cy = h / 2
                        ctx.clearRect(0, 0, w, h)

                        // base
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                        ctx.lineWidth = lw
                        ctx.strokeStyle = "#1f2a33"
                        ctx.stroke()

                        // progresso
                        var frac = (homePage.maxSeconds > 0) ? (homePage.timeLeft / homePage.maxSeconds) : 0
                        var end = -Math.PI / 2 + frac * Math.PI * 2
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, -Math.PI / 2, end, false)
                        ctx.lineWidth = lw
                        ctx.lineCap = "round"
                        ctx.strokeStyle = homePage.running ? "#2A9D8F" : "#496a63"
                        ctx.stroke()

                        // disco interno
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius - lw, 0, Math.PI * 2, false)
                        ctx.fillStyle = "#121b22"
                        ctx.fill()
                    }
                    Component.onCompleted: requestPaint()
                }

                // Contenitore per testo centrato nel disco interno
                Item {
                    id: innerTextBox
                    width: circle.innerSize
                    height: circle.innerSize
                    anchors.centerIn: circle

                    Column {
                        id: textCol
                        anchors.centerIn: parent
                        spacing: Math.round(circle.innerSize * 0.05)

                        Text {
                            text: currentTotal + " " + homePage.currency
                            color: "white"
                            font.pixelSize: Math.round(circle.innerSize * 0.22)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: innerTextBox.width
                        }

                        Text {
                            text: qsTr("Tempo rimanente: ") + Math.ceil(homePage.timeLeft)
                            color: "#9fb3c4"
                            font.pixelSize: Math.round(circle.innerSize * 0.10)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: innerTextBox.width
                        }
                    }
                }
            }

            /* --- Destra: lista puntate (modello C++) --- */
            Rectangle {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                radius: 10
                color: "#111a21"
                border.color: "#22323f"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Label { text: qsTr("Puntate"); font.bold: true; color: "#b5c9d8"; font.pixelSize: 16 }

                    ListView {
                        id: bids
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: bidsModel

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 40
                            color: "transparent"

                            function formatTs(ts) {
                                var d = new Date(ts) // ts in ms epoch o ISO
                                function pad(n) { return (n < 10 ? "0" : "") + n }
                                if (!d || isNaN(d.getTime())) return "--:--:--"
                                return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8
                                Label {
                                    text: formatTs(timestamp)
                                    color: "#9fb3c4"
                                    width: 110
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: "+" + amount + " " + homePage.currency
                                    color: "#2ecc71"
                                    width: 80
                                }
                                Label {
                                    text: who
                                    color: "white"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: "#1f2a33" }
                        }
                    }
                }
            }
        }

        // START/PAUSA in basso al centro
        Row {
            Layout.fillWidth: true
            spacing: 0
            anchors.margins: 0
            Item { Layout.fillWidth: true }

            CustomButton {
                buttonText: homePage.running ? qsTr("Pausa") : qsTr("Start")
                buttonWidth: 264
                onClicked: {
                    if (!homePage.running) {
                        // (ri)parte dal valore attuale (se vuoi sempre da maxSeconds, passa true a startCountdown)
                        startCountdown(homePage.timeLeft <= 0 || homePage.timeLeft > homePage.maxSeconds ? true : false)
                    } else {
                        pauseCountdown()
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }
    }
}
