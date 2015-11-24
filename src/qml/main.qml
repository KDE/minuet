import QtQuick 2.4

Item {
    property int menuBarWidth: 280

    MinuetMenu {
        id: minuetMenu

        width: menuBarWidth; height: parent.height - midiPlayer.height
        anchors { left: parent.left; top: parent.top }
    }
    MidiPlayer {
        id: midiPlayer
        
        width: menuBarWidth
    }
    Image {
        id: background

        width: parent.width - menuBarWidth; height: parent.height
        anchors.right: parent.right
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
        clip: true

        PianoView {
            id: pianoView
            anchors { bottom: parent.bottom; bottomMargin: 5; horizontalCenter: parent.horizontalCenter }
        }
        ExerciseView {
            id: exerciseView
            
            width: background.width; height: minuetMenu.height + 20
            anchors { top: background.top; horizontalCenter: background.horizontalCenter }
        }
    }

    Component.onCompleted: {
        minuetMenu.onBackspacePressed.connect(exerciseView.clearExerciseGrid)
        minuetMenu.onItemChanged.connect(exerciseView.itemChanged)

        sequencer.noteOn.connect(pianoView.noteOn)
        sequencer.noteOff.connect(pianoView.noteOff)
        sequencer.noteHighlight.connect(pianoView.noteHighlight)
        sequencer.allNotesOff.connect(pianoView.allNotesOff)

        sequencer.timeLabelChanged.connect(midiPlayer.timeLabelChanged)
        sequencer.volumeChanged.connect(midiPlayer.volumeChanged)
        sequencer.tempoChanged.connect(midiPlayer.tempoChanged)
        sequencer.pitchChanged.connect(midiPlayer.pitchChanged)

        exerciseView.answerHoverEnter.connect(pianoView.noteHighlight)
        exerciseView.answerHoverExit.connect(pianoView.noteOff)
    }
}
