// SubPage.qml
import QtQuick 2.12
import QtQuick.Controls 2.5

Page {
    id: root
    property var someParam: null
    property string pageTitle: "Sub Page"

    title: pageTitle   // usa la tua property per alimentare il titolo

    background: Rectangle { color: "#0f1921" }

    Label {
        anchors.centerIn: parent
        text: "Sub page aperta! Param = " + someParam
        color: "white"
        font.pixelSize: 20
    }
}
