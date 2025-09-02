// MasterHomePage.qml
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import App 1.0
import "qrc:/"

Page {
    id: root
    background: Rectangle { color: "#0f1921" }

    /* ====== Props ====== */
    property string  playerName: "Nome giocatore"
    property int     maxSeconds: 5                // <-- 5 secondi
    property real    timeLeft:   maxSeconds
    property bool    running:    false
    property string  currency:   "€"

    // ultima puntata (il modello inserisce in testa → riga 0)
    readonly property var lastBid: (bidsModel && bidsModel.count > 0) ? bidsModel.get(0) : null
    readonly property string lastWho: lastBid ? lastBid.who   : qsTr("—")
    readonly property int    lastTotal: lastBid ? lastBid.total : 0


    // Modello C++ (iniettalo dall’esterno: es. context property "BidsModel")
    property var bidsModel: Bids

    signal roundStarted(string player)
    signal roundEnded(string player, int finalBid)

    WinPopup{
        id:winPopup
    }

    /* ====== Timer ====== */
    Timer {
        id: t
        interval: 100; repeat: true; running: root.running
        onTriggered: {
            root.timeLeft = Math.max(0, root.timeLeft - 0.1)
            if (root.timeLeft === 0) {
                root.running = false
                winPopup.open()
                root.roundEnded(root.playerName, currentTotal)
            }
        }
    }

    /* Totale corrente (se il modello fornisce "total", uso l'ultima riga; altrimenti sommo i delta) */
    readonly property int currentTotal: {
        if (!bidsModel || !bidsModel.count) return 0
        var row0 = 0 // mostro ordine: più recente in alto
        var itm = bidsModel.get ? bidsModel.get(row0) : null
        if (itm && itm.total !== undefined) return itm.total
        // fallback: somma i delta
        var s = 0
        for (var i=0;i<bidsModel.count;i++) {
            var it = bidsModel.get(i)
            if (it && it.delta !== undefined) s += it.delta
        }
        return s
    }

    /* Reset timer su nuova puntata */
    Connections {
        target: bidsModel
        ignoreUnknownSignals: true
        onRowsInserted: {
            // nuova bid aggiunta dal C++ → reset timer e pulse
            root.timeLeft = root.maxSeconds
            root.running = true
            pulse.start()
            ring.requestPaint()
        }
        // opzionale: su model reset
        onModelReset: {
            root.timeLeft = root.maxSeconds
            root.running = false
            ring.requestPaint()
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
                color: "#b5c9d8"; font.pixelSize: 18
            }
            Rectangle {
                radius: 8; color: "white"
                height: titleLbl.implicitHeight + 8
                width: Math.min(titleLbl.implicitWidth + 18, parent.width * 0.6)
                Label {
                    id: titleLbl
                    anchors.centerIn: parent
                    text: root.playerName
                    color: "black"; font.pixelSize: 18; font.bold: true
                    elide: Text.ElideRight
                }
            }
            Item { Layout.fillWidth: true }
            /*
            Label {
                text: qsTr("Rimasti: ") + Math.ceil(root.timeLeft) + "s"
                color: root.running ? "#7FD1FF" : "#89a3b4"
                font.pixelSize: 16
            }
            */
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
                    width: parent.size; height: width; radius: width/2
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
                    target: root
                    onTimeLeftChanged: ring.requestPaint()
                    onRunningChanged:  ring.requestPaint()
                }

                Canvas {
                    id: ring
                    anchors.centerIn: parent
                    width: parent.size
                    height: parent.size

                    // === parametri esposti per riuso ===
                    property real lw: 18
                    property real pad: 3
                    property real radius: Math.min(width, height)/2 - (lw/2) - pad
                    property real innerSize: Math.max(0, (radius - lw) * 2)

                    onPaint: {
                        var ctx = getContext("2d");
                        var w = width, h = height, cx = w/2, cy = h/2;
                        ctx.clearRect(0,0,w,h);

                        // base
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, 0, Math.PI*2, false);
                        ctx.lineWidth = lw;
                        ctx.strokeStyle = "#1f2a33";
                        ctx.stroke();

                        // progresso
                        var frac = (root.maxSeconds > 0) ? (root.timeLeft/root.maxSeconds) : 0;
                        var end = -Math.PI/2 + frac * Math.PI*2;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, -Math.PI/2, end, false);
                        ctx.lineWidth = lw;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = root.running ? "#2A9D8F" : "#496a63";
                        ctx.stroke();

                        // disco interno
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius - lw, 0, Math.PI*2, false);
                        ctx.fillStyle = "#121b22";
                        ctx.fill();
                    }
                    Component.onCompleted: requestPaint()
                }

                //// Contenitore per testo centrato nel disco interno
                Item {
                    id: innerTextBox
                    width: ring.innerSize
                    height: ring.innerSize
                    anchors.centerIn: ring

                    Column {
                        id: textCol
                        anchors.centerIn: parent
                        spacing: Math.round(ring.innerSize * 0.05)

                        Text {
                            text: currentTotal + " " + root.currency
                            color: "white"
                            font.pixelSize: Math.round(ring.innerSize * 0.22)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: innerTextBox.width
                        }

                        Text {
                            text: qsTr("Tempo rimanente: ") + Math.ceil(root.timeLeft)
                            color: "#9fb3c4"
                            font.pixelSize: Math.round(ring.innerSize * 0.10)
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

                    Label { text: qsTr("Puntate"); font.bold:true; color: "#b5c9d8"; font.pixelSize: 16 }

                    ListView {
                        id: bids
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: bidsModel
                        // Mostra la più recente in alto: se il C++ inserisce in coda, inverti con preferredHighlightBegin/End
                        // oppure fai gestire l'ordine nel C++ (consigliato).
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 40
                            color: "transparent"

                            function formatTs(ts) {
                                var d = new Date(ts)   // ts in ms epoch
                                function pad(n) { return (n < 10 ? "0" : "") + n }
                                return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
                            }
                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8
                                Label {
                                    // timestamp: supporto ms epoch o stringa ISO
                                    text: formatTs(timestamp)
                                    color: "#9fb3c4"
                                    width: 110
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: "+" + delta + " " + root.currency
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

                        function formatTs(ts) {
                            var d = null
                            if (typeof ts === "number") d = new Date(ts)
                            else if (typeof ts === "string") d = new Date(ts)
                            if (!d || isNaN(d.getTime())) return "--:--:--"
                            function pad(n){ return (n<10?"0":"")+n }
                            return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
                        }
                    }
                }
            }
        }

        // START in basso al centro
        Row {
            Layout.fillWidth: true
            spacing: 0
            anchors.margins: 0
            Item { Layout.fillWidth: true }
            Button {
                id: startBtn
                text: root.running ? qsTr("In pausa") : qsTr("Start")
                implicitWidth: 180; implicitHeight: 46
                font.bold: true
                onClicked: {
                    if (!root.running) {
                        // (ri)parte sempre da 5s
                        root.timeLeft = root.maxSeconds
                        pulse.start()
                        root.running = true
                        root.roundStarted(root.playerName)
                    } else {
                        root.running = false
                    }
                }
                contentItem: Text { anchors.centerIn: parent; text: startBtn.text; color: "white"; font.pixelSize: 16; font.bold: true }
                background: Rectangle {
                    id: bg
                    anchors.fill: parent
                    radius: height/2
                    color: startBtn.enabled ? (startBtn.hovered ? "#35bfa3" : "#2A9D8F") : "#335a54"
                    border.color: "#20816f"; border.width: 1
                    layer.enabled: true
                    layer.effect: DropShadow {
                        anchors.fill: bg; source: bg
                        horizontalOffset: 0
                        verticalOffset: startBtn.hovered ? 6 : 4
                        radius: startBtn.hovered ? 18 : 12
                        samples: 32
                        color: "#55000000"
                    }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onPressed: startBtn.scale = 0.96; onReleased: startBtn.scale = 1.0 }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
