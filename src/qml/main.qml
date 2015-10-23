import QtQuick 2.5

Rectangle {
    visible: true

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Qt.quit();
        }
    }

    Text {
        text: qsTr("Hello Minuet")
        anchors.centerIn: parent
    }
}
