import QtQuick 2.4

Item {
    id: item

    property alias source: buttonImage.source
    property alias text: buttonText.text

    signal activated

    width: playbackTime.contentWidth / 3; height: childrenRect.height

    Image {
        id: buttonImage

        width: 24; height: 24
        anchors.horizontalCenter: parent.horizontalCenter
        MouseArea { anchors.fill: parent; onClicked: item.activated() }
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
