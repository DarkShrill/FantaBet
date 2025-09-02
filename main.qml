import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import "qrc:/MasterPages/"
import "qrc:/SlavePages/"

ApplicationWindow {
    id: win
    visible: true
    width: 640; height: 480
    title: qsTr("Fanta App")

    StackView {
        id: rootStack
        anchors.fill: parent
        initialItem: mainPage
    }

    /* ---------- Home ---------- */
    Component {
        id: mainPage
        Page {
            background: Rectangle { color: "#101417" }
            Row {
                spacing: 24
                anchors.centerIn: parent

                IconButton {
                    width: 170; height: 190
                    iconSource: "qrc:/worker-money-time.png"
                    label: qsTr("Master")
                    onClicked: rootStack.push(masterFlow)
                }
                IconButton {
                    width: 170; height: 190
                    iconSource: "qrc:/man-with-money.png"
                    label: qsTr("Scommettitore")
                    onClicked: rootStack.push(slaveFlow)
                }
            }
        }
    }

    /* ---------- FLOW MASTER (StackView annidato) ---------- */
    Component {
        id: masterFlow
        Page {
            title: qsTr("Master")
            header: ToolBar {
                visible: masterStack.depth > 1
                RowLayout {
                    anchors.fill: parent
                    ToolButton {
                        text: "\u25C0"
                        onClicked: masterStack.pop()
                    }
                    Label { text: qsTr("Master"); Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                    Item { width: 40 } // spacer simmetrico
                }
            }
            StackView {
                id: masterStack
                anchors.fill: parent
                initialItem: MasterWaitingRoomPage {}   // la tua pagina iniziale del flusso master
            }
        }
    }

    /* ---------- FLOW SLAVE (StackView annidato) ---------- */
    Component {
        id: slaveFlow
        Page {
            title: qsTr("Scommettitore")
            header: ToolBar {
                visible: slaveStack.depth > 1
                RowLayout {
                    anchors.fill: parent
                    ToolButton {
                        text: "\u25C0"
                        onClicked: slaveStack.pop()
                    }
                    Label { text: qsTr("Scommettitore"); Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                    Item { width: 40 }
                }
            }
            StackView {
                id: slaveStack
                anchors.fill: parent
                initialItem: SlaveHowAreYouPage {}       // la tua pagina iniziale del flusso slave
            }
        }
    }
}
