import QtQuick 2.3
import QtQuick.Controls 1.2

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello KWorld")

    Label {
        text: qsTr("Hello KWorld")
        anchors.centerIn: parent
    }
}

