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

import QtQuick 2.7
import QtQuick.Controls 2.0

Column {
    property var answers: [
        "exercise-images/current-rhythm.png",
        "exercise-images/unknown-rhythm.png",
        "exercise-images/unknown-rhythm.png",
        "exercise-images/unknown-rhythm.png"
    ]
    property int currentAnswer: 0
    property var correctAnswers
    property var correctColors: ["#ffffff", "#ffffff", "#ffffff", "#ffffff"]
    property ExerciseView exerciseView
    property var colors: ["#ffffff", "#ffffff", "#ffffff", "#ffffff"]

    signal answerCompleted(var answers)

    function answerClicked(answerImageSource, color) {
        var tempAnswers = answers
        tempAnswers[currentAnswer] = answerImageSource
        var tempColors = colors
        tempColors[currentAnswer] = color
        colors = tempColors
        currentAnswer++
        if (currentAnswer == 4) {
            answerCompleted(answers)
            correctColors = exerciseView.chosenColors
            for (var i = 0; i < 4; ++i)
                correctAnswerGrid.children[i].opacity = answers[i].toString().split("/").pop().split(".")[0] != correctAnswers[i] ? 1:0
        }
        else {
            tempAnswers[currentAnswer] = "exercise-images/current-rhythm.png"
        }
        answers = tempAnswers
    }
    function resetAnswers() {
        currentAnswer = 0
        answers = ["exercise-images/current-rhythm.png", "exercise-images/unknown-rhythm.png", "exercise-images/unknown-rhythm.png", "exercise-images/unknown-rhythm.png"]
        correctAnswers = undefined
        colors = ["#ffffff", "#ffffff", "#ffffff", "#ffffff"]
        correctColors = ["#ffffff", "#ffffff", "#ffffff", "#ffffff"]
        for (var i = 0; i < 4; ++i)
            correctAnswerGrid.children[i].opacity = 0
    }
    function showCorrectAnswer(chosenExercises, chosenColors) {
        var tempAnswers = answers
        for (var i = 0; i < 4; ++i)
            tempAnswers[i] = "exercise-images/" + chosenExercises[i] + ".png"
        answers = tempAnswers
        colors = chosenColors
        currentAnswer = 0
    }
    function fillCorrectAnswerGrid() {
        for (var i = 0; i < 4; ++i)
            correctAnswerGrid.children[i].opacity = 0
        correctAnswers = exerciseView.chosenExercises
    }

    spacing: 10

    Row {
        id: correctAnswerGrid

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Repeater {
            model: 4

            Rectangle {
                id: correctAnswerRectangle

                width: 119; height: 59
                color: correctColors[index]
                opacity: 0

                Image {
                    id: correctRhythmImage

                    anchors.centerIn: parent
                    source: (correctAnswers != undefined && core.exerciseController.currentExercise["playMode"] == "rhythm") ? "exercise-images/" + correctAnswers[index] + ".png":""
                    fillMode: Image.Pad
                }
            }
        }
    }

    Rectangle {
        id: answerRect

        color: "#475057"
        radius: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: answerGrid.width + 20; height: answerGrid.height + 20

        Row {
            id: answerGrid

            anchors.centerIn: parent
            spacing: 10
            Repeater {
                model: 4

                Rectangle {
                    id: answerRectangle

                    width: 119
                    height: 59
                    color: colors[index]

                    Text {
                        id: option

                        property string originalText

                        visible: false
                        width: parent.width
                        anchors.centerIn: parent
                        horizontalAlignment: Qt.AlignHCenter
                        color: "black"
                        wrapMode: Text.Wrap
                    }
                    Image {
                        id: rhythmImage
                        anchors.centerIn: parent

                        source: answers[index]
                        fillMode: Image.Pad
                    }
                }
            }
        }
    }
    Button {
        id: backspaceButton

        width: answerRect.width; height: 44
        anchors.horizontalCenter: parent.horizontalCenter
        text: i18n("backspace")
        enabled: currentAnswer > 0 && currentAnswer < 4
        onClicked: {
            if (currentAnswer > 0) {
                var tempAnswers = answers
                var tempColors = colors
                tempAnswers[currentAnswer] = "exercise-images/unknown-rhythm.png"
                currentAnswer--
                tempAnswers[currentAnswer] = "exercise-images/current-rhythm.png"
                tempColors[currentAnswer] = "#ffffff"
                answers = tempAnswers
                colors = tempColors
            }
        }
    }
    Connections {
        target: core.exerciseController
        onCurrentExerciseChanged: resetAnswers()
    }
}
