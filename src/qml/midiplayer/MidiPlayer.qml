import QtQuick 2.5
import QtQuick.Controls 1.4

Rectangle {
    function timeLabelChanged(timeLabel) { playbackTime.text = timeLabel }
    function volumeChanged(value) { volumeLabel.text = qsTr("Volume: %1\%").arg(value) }
    function tempoChanged(value) { tempoLabel.text = qsTr("Tempo: %1bpm").arg(value) }
    function pitchChanged(value) { pitchLabel.text = qsTr("Pitch: %1").arg(value) }
    
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
        anchors { right: parent.right; rightMargin: 15; verticalCenter: parent.verticalCenter }

        MultimediaSlider {
            id: volumeSlider
            anchors.right: parent.right
            source: "qrc:/images/multimedia-volume.png"
            maximumValue: 200
            value: 100
            onValueChanged: sequencer.setVolumeFactor(value)
        }
        MultimediaSlider {
            id: tempoSlider
            anchors { right: volumeSlider.left; rightMargin: 8 }
            source: "qrc:/images/multimedia-speed.png"
            maximumValue: 200
            minimumValue: 50
            value: 100
            onValueChanged: sequencer.setTempoFactor(value)
        }
        MultimediaSlider {
            anchors { right: tempoSlider.left; rightMargin: 8 }
            source: "qrc:/images/multimedia-pitch.png"
            maximumValue: 12
            minimumValue: -12
            value: 0
            onValueChanged: sequencer.setPitchShift(value)
        }
    }
    Component.onCompleted: {
        sequencer.timeLabelChanged.connect(timeLabelChanged)
        sequencer.volumeChanged.connect(volumeChanged)
        sequencer.tempoChanged.connect(tempoChanged)
        sequencer.pitchChanged.connect(pitchChanged)
    }
}
