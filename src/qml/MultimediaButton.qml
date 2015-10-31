import QtQuick 2.5

Item {
    property alias source: buttonImage.source;
    property alias text: buttonText.text;

    width: playbackTime.contentWidth / 3; height: childrenRect.height

    Image {
        id: buttonImage

        width: 24; height: 24
        anchors.horizontalCenter: parent.horizontalCenter
    }
    Text {
        id: buttonText

        width: parent.width
        anchors.top: buttonImage.bottom
        font.pointSize: 8
        horizontalAlignment: Text.AlignHCenter
        color: "white"
    }
}