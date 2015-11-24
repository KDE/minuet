import QtQuick 2.4

Rectangle {
    function timeLabelChanged(timeLabel) { playbackTime.text = timeLabel }
    function volumeChanged(value) { volumeLabel.text = qsTr("Volume: %1\%").arg(value) }
    function tempoChanged(value) { tempoLabel.text = qsTr("Tempo: %1 bpm").arg(value) }
    function pitchChanged(value) { pitchLabel.text = qsTr("Pitch: %1").arg(value) }

    height: childrenRect.height + 15
    anchors { left: parent.left; bottom: parent.bottom }
    color: "black"

    Rectangle {
        id: labels

        width: parent.width; height: 20
        anchors.top: parent.top
        color: "#343434"
        Row {
            width: parent.width
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 15 }
            Text {
                id: tempoLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: "white"
                text: qsTr("Tempo:")
            }
            Text {
                id: volumeLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: "white"
                text: qsTr("Volume: 100%")
            }
            Text {
                id: pitchLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: "white"
                text: qsTr("Pitch: 0")
            }
        }
    }    
    Item {
        id: item1

        width: parent.width / 2 - 8; height: childrenRect.height
        anchors { left: parent.left; leftMargin: 8; top: labels.bottom; topMargin: 10 }

        Text {
            id: playbackTime

            width: item1.width
            horizontalAlignment: Text.AlignHCenter
            text: "00:00.00"
            font.pointSize: 24
            color: "#008000"
        }
        MultimediaButton {
            id: item12

            anchors { top: playbackTime.bottom; horizontalCenter: playbackTime.horizontalCenter }
            source: "qrc:/images/multimedia-pause.png"
            text: qsTr("Pause")
            onActivated: sequencer.pause()
        }
        MultimediaButton {
            anchors { top: playbackTime.bottom; right: item12.left; rightMargin: -2 }
            source: "qrc:/images/multimedia-play.png"
            text: qsTr("Play")
            onActivated: sequencer.play()
        }
        MultimediaButton {
            anchors { top: playbackTime.bottom; left: item12.right; leftMargin: -2 }
            source: "qrc:/images/multimedia-stop.png"
            text: qsTr("Stop")
            onActivated: sequencer.stop()
        }
    }
    Item {
        id: item2

        width: parent.width / 2 - 15; height: item1.height
        anchors { right: parent.right; rightMargin: 15; verticalCenter: item1.verticalCenter }

        Row {
            height: parent.height
            anchors.right: parent.right
            spacing: 8
            MultimediaSlider {
                source: "qrc:/images/multimedia-pitch.png"
                maximumValue: 12; minimumValue: -12; value: 0
                onValueChanged: sequencer.setPitchShift(value)
            }
            MultimediaSlider {
                source: "qrc:/images/multimedia-speed.png"
                maximumValue: 200; minimumValue: 50; value: 100
                onValueChanged: sequencer.setTempoFactor(value)
            }
            MultimediaSlider {
                source: "qrc:/images/multimedia-volume.png"
                maximumValue: 200; value: 100
                onValueChanged: sequencer.setVolumeFactor(value)
            }
        }
    }
}
