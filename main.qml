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
    title: qsTr("FantaBet App")

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
                background: Rectangle {
                    color: "#0f1921"
                    border.color: "#22323f"
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Pulsante indietro
                    ToolButton {
                        Layout.preferredWidth: 44
                        text: "\u25C0"
                        font.pixelSize: 20
                        contentItem: Label {
                            text: "\u25C0"
                            color: "white"             // bianco di default
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: "transparent"
                            border.color: "transparent"
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                cursorShape: Qt.PointingHandCursor   // mano al passaggio
                                onEntered: parent.color = "#1f2a33" // highlight scuro
                                onExited: parent.color = "transparent"
                            }
                        }

                        onClicked: masterStack.pop()
                    }

                    // Titolo centrato
                    Label {
                        text: qsTr("Master")
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    // Spacer simmetrico
                    Item { Layout.preferredWidth: 44 }
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
                visible: false //slaveStack.depth > 1
                background: Rectangle {
                    color: "#0f1921"
                    border.color: "#22323f"
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Pulsante indietro
                    ToolButton {
                        Layout.preferredWidth: 44
                        text: "\u25C0"
                        font.pixelSize: 20
                        contentItem: Label {
                            text: "\u25C0"
                            color: "white"             // bianco di default
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: "transparent"
                            border.color: "transparent"
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                cursorShape: Qt.PointingHandCursor   // mano al passaggio
                                onEntered: parent.color = "#1f2a33" // highlight scuro
                                onExited: parent.color = "transparent"
                            }
                        }

                        onClicked: slaveStack.pop()
                    }

                    // Titolo centrato
                    Label {
                        text: qsTr("Scommettitore")
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    // Spacer simmetrico
                    Item { Layout.preferredWidth: 44 }
                }
            }
            StackView {
                id: slaveStack
                anchors.fill: parent
                initialItem: SlaveAddPersonPage {}       // la tua pagina iniziale del flusso slave
            }
        }
    }
}
