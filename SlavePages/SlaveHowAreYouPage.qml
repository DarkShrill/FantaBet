import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQml 2.12
import QtQuick.Controls 2.12

Component {
    id: slaveHowAreYouPage
    Page {
        title: qsTr("Classifiche")
        background: Rectangle { color: "#0f1921" }
        Label {
            anchors.centerIn: parent
            text: qsTr("How Are yoy")
            color: "white"
            font.pixelSize: 22
        }
    }
}
