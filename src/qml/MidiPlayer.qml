import QtQuick 2.5
import QtQuick.Controls 1.4

Rectangle {
    width: menuBarWidth; height: 100
    color: "black"
    anchors { left: parent.left; bottom: parent.bottom }
    Item {
        id: item1
        width: parent.width / 2; height: parent.height
        anchors { left: parent.left; bottom: parent.bottom }
        Text {
            id: playbackTime
            width: item1.width
            horizontalAlignment: Text.AlignHCenter
            text: "00:00:00"
            font.pointSize: 24
            color: "#008000"
        }
        Item {
            id: item11
            width: item1.width / 3
            anchors { top: playbackTime.bottom }
            Image {
                id: playImage
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/images/multimedia-play.png"
                width: 24; height: 24
            }
            Text { id: playText; text: "Play"; color: "white"; width: item11.width; horizontalAlignment: Text.AlignHCenter; anchors.top: playImage.bottom }
        }
        Item {
            id: item12
            width: item1.width / 3
            anchors { top: playbackTime.bottom; left: item11.right }
            Image {
                id: pauseImage
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/images/multimedia-pause.png"
                width: 24; height: 24
            }
            Text { id: pauseText; text: "Pause"; color: "white"; width: item11.width; horizontalAlignment: Text.AlignHCenter; anchors.top: pauseImage.bottom }
        }
        Item {
            id: item13
            width: item1.width / 3
            anchors { top: playbackTime.bottom; left: item12.right }
            Image {
                id: stopImage
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/images/multimedia-stop.png"
                width: 24; height: 24
            }
            Text { id: stopText; text: "Stop"; color: "white"; width: item11.width; horizontalAlignment: Text.AlignHCenter; anchors.top: stopImage.bottom }
        }
    }
    Item {
        width: parent.width / 2; height: parent.height
        anchors { right: parent.right; bottom: parent.bottom }
        Column {
            anchors.centerIn: parent
            spacing: 10
            Text { text: "Tempo: 120.00 bpm"; color: "white" }
            Text { text: "Volume: 100%"; color: "white" }
            Row {
                Text { id: pitch; text: "Pitch: "; color: "white" }
                SpinBox { anchors.verticalCenter: pitch.verticalCenter; id: spinbox }
            }
        }
    }
}