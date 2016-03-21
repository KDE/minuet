/****************************************************************************
**
** Copyright (C) 2016 by Sandro S. Andrade <sandroandrade@kde.org>
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation; either version 2 of
** the License or (at your option) version 3 or any later version
** accepted by the membership of KDE e.V. (or its successor approved
** by the membership of KDE e.V.), which shall act as a proxy 
** defined in Section 14 of version 3 of the license.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

import QtQuick 2.4
import "pianoview"
import "midiplayer"

Item {
    id: mainItem

    property int menuBarWidth: 280

    function exerciseTypeChanged(type) {
        pianoView.visible = (type != "rhythm" && type != "exercise")
        rhythmAnswerView.visible = (type == "rhythm")
    }
    function exerciseViewStateChanged(state) {
        if (state == "waitingForAnswer")
            rhythmAnswerView.resetAnswers()
    }

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
        source: "images/minuet-background.png"
        fillMode: Image.Tile
        clip: true

        PianoView {
            id: pianoView
            anchors { bottom: parent.bottom; bottomMargin: 5; horizontalCenter: parent.horizontalCenter }

            visible: false
        }
        RhythmAnswerView {
            id: rhythmAnswerView
            anchors { bottom: parent.bottom; bottomMargin: 5; horizontalCenter: parent.horizontalCenter }

            visible: false
        }
        ExerciseView {
            id: exerciseView
            
            width: background.width; height: minuetMenu.height + 20
            anchors { top: background.top; horizontalCenter: background.horizontalCenter }
        }
    }

    Component.onCompleted: {
        minuetMenu.breadcrumbPressed.connect(exerciseView.clearExerciseGrid)
        minuetMenu.breadcrumbPressed.connect(rhythmAnswerView.resetAnswers)
        minuetMenu.itemChanged.connect(exerciseView.itemChanged)
        minuetMenu.exerciseTypeChanged.connect(exerciseView.changeExerciseType)
        minuetMenu.exerciseTypeChanged.connect(mainItem.exerciseTypeChanged)

        sequencer.noteOn.connect(pianoView.noteOn)
        sequencer.noteOff.connect(pianoView.noteOff)
        sequencer.allNotesOff.connect(pianoView.allNotesOff)

        sequencer.timeLabelChanged.connect(midiPlayer.timeLabelChanged)
        sequencer.volumeChanged.connect(midiPlayer.volumeChanged)
        sequencer.tempoChanged.connect(midiPlayer.tempoChanged)
        sequencer.pitchChanged.connect(midiPlayer.pitchChanged)

        exerciseView.answerHoverEnter.connect(pianoView.noteMark)
        exerciseView.answerHoverExit.connect(pianoView.noteUnmark)
        exerciseView.answerClicked.connect(rhythmAnswerView.answerClicked)
        exerciseView.onStateChanged.connect(mainItem.exerciseViewStateChanged)
        exerciseView.showCorrectAnswer.connect(rhythmAnswerView.showCorrectAnswer)

        rhythmAnswerView.answerCompleted.connect(exerciseView.checkAnswers)
    }
}
