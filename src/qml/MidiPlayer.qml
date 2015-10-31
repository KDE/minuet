import QtQuick 2.5
import QtQuick.Controls 1.4

Rectangle {
    width: menuBarWidth; height: 100
    anchors { left: parent.left; bottom: parent.bottom }
    color: "black"

    Item {
        id: item1

        width: parent.width / 2 - 8; height: childrenRect.height
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }

        Text {
            id: playbackTime

            width: item1.width;
            horizontalAlignment: Text.AlignHCenter
            text: "00:00:00"
            font.pointSize: 24
            color: "#008000"
        }
        MultimediaButton {
            id: item12

            anchors { top: playbackTime.bottom; horizontalCenter: playbackTime.horizontalCenter }
            source: "qrc:/images/multimedia-pause.png"
            text: "Pause"
        }
        MultimediaButton {
            anchors { top: playbackTime.bottom; right: item12.left; rightMargin: -2 }
            source: "qrc:/images/multimedia-play.png"
            text: "Play"
        }
        MultimediaButton {
            anchors { top: playbackTime.bottom; left: item12.right; leftMargin: -2 }
            source: "qrc:/images/multimedia-stop.png"
            text: "Stop"
        }
    }
    Item {
        id: item2

        width: parent.width / 2 - 15; height: item1.height
        anchors { right: parent.right; rightMargin: 15; verticalCenter: parent.verticalCenter }

        MultimediaSlider {
            id: volumeSlider
            anchors.right: parent.right
            source: "qrc:/images/multimedia-volume.png"
            maximumValue: 200
            value: 100
        }
        MultimediaSlider {
            anchors { right: volumeSlider.left; rightMargin: 8 }
            source: "qrc:/images/multimedia-speed.png"
            minimumValue: 50
            maximumValue: 200
            value: 100
        }
    }
}