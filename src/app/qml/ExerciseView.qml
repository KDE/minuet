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
import QtQuick.Layouts 1.3
import QtQuick.Window 2.0

Item {
    id: exerciseView

    visible: currentExercise != undefined

    property var currentExercise
    
    QtObject {
        id: internal

        property int currentAnswer
        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        property Item rightAnswerRectangle
        property variant userAnswers: []
        property var answersAreRight
    }

    onCurrentExerciseChanged: {
        clearUserAnswers()
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
        if (currentExercise != undefined) {
            var currentExerciseOptions = currentExercise["options"];
            if (currentExerciseOptions != undefined) {
                var length = currentExerciseOptions.length
                for (var i = 0; i < length; ++i)
                    answerOption.createObject(answerGrid, {model: currentExerciseOptions[i], index: i, color: internal.colors[i%24]})
            }
            messageText.text = i18n("Click 'new question' to start!")
            exerciseView.state = "waitingForNewQuestion"
        }
    }

    function clearUserAnswers() {
        pianoView.clearAllMarks()
        for (var i = 0; i < yourAnswersParent.children.length; ++i)
            yourAnswersParent.children[i].destroy()
        internal.currentAnswer = 0
        internal.userAnswers = []
    }

    function checkAnswers() {
        var rightAnswers = core.exerciseController.selectedExerciseOptions
        internal.answersAreRight = true
        for (var i = 0; i < currentExercise.numberOfSelectedOptions; ++i) {
            if (internal.userAnswers[i] != rightAnswers[i].name) {
                internal.answersAreRight = false
                break
            }
        }
        messageText.text = (internal.answersAreRight) ? i18n("Congratulations, you answered correctly!"):i18n("Oops, not this time! Try again!")
        if (currentExercise.numberOfSelectedOptions == 1)
            highlightRightAnswer()
        else
            exerciseView.state = "waitingForNewQuestion"
    }
    
    function highlightRightAnswer() {
        var chosenExercises = core.exerciseController.selectedExerciseOptions
        for (var i = 0; i < answerGrid.children.length; ++i) {
            if (answerGrid.children[i].model.name != chosenExercises[0].name) {
                answerGrid.children[i].opacity = 0.25
            }
            else {
                internal.rightAnswerRectangle = answerGrid.children[i]
                answerGrid.children[i].opacity = 1
            }
        }
        internal.rightAnswerRectangle.model.sequence.split(' ').forEach(function(note) {
            pianoView.noteMark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, internal.rightAnswerRectangle.color)
        })
        animation.start()
    }


    ColumnLayout {
        anchors.fill: parent
        spacing: Screen.width >= 1024 ? 20:10

        Text {
            id: userMessage

            Layout.preferredWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Screen.width >= 1024 ? 18:14
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.WordWrap
            text: (currentExercise != undefined) ? i18nc("technical term, do you have a musician friend?", currentExercise["userMessage"]):""
        }
        Text {
            id: messageText

            font.pointSize: Screen.width >= 1024 ? 18:14
            Layout.preferredWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Button {
                id: newPlayQuestionButton

                width: 120; height: 40
                text: (exerciseView.state == "waitingForNewQuestion") ? i18n("new question"):i18n("play question")
                enabled: !animation.running

                onClicked: {
                    if (exerciseView.state == "waitingForNewQuestion") {
                        clearUserAnswers()
                        messageText.text = ""
                        core.exerciseController.randomlySelectExerciseOptions()
                        var chosenExercises = core.exerciseController.selectedExerciseOptions
                        core.soundController.prepareFromExerciseOptions(chosenExercises)
                        if (currentExercise["playMode"] != "rhythm")
                            pianoView.noteMark(0, core.exerciseController.chosenRootNote(), 0, "white")
                        exerciseView.state = "waitingForAnswer"
                    }
                    core.soundController.play()
                }
            }
            Button {
                id: giveUpButton

                width: 120; height: 40
                text: i18n("give up")
                enabled: exerciseView.state == "waitingForAnswer" && !animation.running

                onClicked: {
                    exerciseView.state = "waitingForNewQuestion"
                }
            }
        }
        GroupBox {
            id: availableAnswers

            title: i18n("Available Answers")
            anchors.horizontalCenter: parent.horizontalCenter
            Layout.preferredWidth: parent.width
            Layout.fillHeight: true

            Flickable {
                anchors.fill: parent
                contentHeight: answerGrid.height
                clip: true

                Grid {
                    id: answerGrid

                    anchors.centerIn: parent
                    spacing: 10

                    columns: Math.max(1, parent.width / (((currentExercise != undefined && currentExercise["playMode"] != "rhythm") ? 120:119) + spacing))

                    Component {
                        id: answerOption

                        Rectangle {
                            id: answerRectangle

                            property var model
                            property int index

                            width: (currentExercise != undefined && currentExercise["playMode"] != "rhythm") ? 120:119
                            height: (currentExercise != undefined && currentExercise["playMode"] != "rhythm") ? 40:59

                            Text {
                                id: option

                                property string originalText: model.name

                                visible: currentExercise != undefined && currentExercise["playMode"] != "rhythm"
                                text: i18nc("technical term, do you have a musician friend?", model.name)
                                width: parent.width - 4
                                anchors.centerIn: parent
                                horizontalAlignment: Qt.AlignHCenter
                                color: "black"
                                wrapMode: Text.Wrap
                            }
                            Image {
                                id: rhythmImage

                                anchors.centerIn: parent
                                visible: currentExercise != undefined && currentExercise["playMode"] == "rhythm"
                                source: (currentExercise != undefined && currentExercise["playMode"] == "rhythm") ? "exercise-images/" + model.name + ".png":""
                                fillMode: Image.Pad
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (exerciseView.state == "waitingForAnswer" && !animation.running) {
                                        onExited()
                                        internal.currentAnswer++
                                        internal.userAnswers.push(option.originalText)
                                        answerOption.createObject(yourAnswersParent, {model: answerRectangle.model, index: answerRectangle.index, color: answerRectangle.color})
                                        if (internal.currentAnswer == currentExercise.numberOfSelectedOptions)
                                            checkAnswers()
                                    }
                                }
                                hoverEnabled: Qt.platform.os != "android" &&
                                              currentExercise != undefined && currentExercise["playMode"] != "rhythm" &&
                                              !animation.running
                                onEntered: {
                                    answerRectangle.color = Qt.darker(answerRectangle.color, 1.1)
                                    if (currentExercise["playMode"] != "rhythm") {
                                        model.sequence.split(' ').forEach(function(note) {
                                            pianoView.noteMark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, internal.colors[answerRectangle.index])
                                        })
                                    }
                                }
                                onExited: {
                                    answerRectangle.color = internal.colors[answerRectangle.index]
                                    if (currentExercise["playMode"] != "rhythm") {
                                        if (!animation.running)
                                            model.sequence.split(' ').forEach(function(note) {
                                                pianoView.noteUnmark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0)
                                            })
                                    }
                                }
                            }
                        }
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator { active: true }
            }
        }
        GroupBox {
            id: yourAnswers

            title: i18n("Your Answer(s)")
            Layout.preferredWidth: parent.width
            anchors.horizontalCenter: parent.horizontalCenter

            contentHeight: ((currentExercise != undefined && currentExercise["playMode"] != "rhythm") ? 40:59)

            Row {
                id: yourAnswersParent
                anchors.centerIn: parent
                spacing: Screen.width >= 1024 ? 10:5
            }
        }
        Button {
            id: backspaceButton

            text: i18n("backspace")
            anchors.horizontalCenter: parent.horizontalCenter
            visible: currentExercise != undefined && currentExercise["playMode"] == "rhythm"
            enabled: internal.currentAnswer > 0 && internal.currentAnswer < 4
            onClicked: {
                internal.currentAnswer--
            }
        }
        PianoView {
            id: pianoView
            visible: currentExercise != undefined && currentExercise["playMode"] != "rhythm"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    states: [
        State {
            name: "waitingForNewQuestion"
        },
        State {
            name: "waitingForAnswer"
            StateChangeScript {
                script: {
                    for (var i = 0; i < answerGrid.children.length; ++i) {
                        answerGrid.children[i].opacity = 1
                    }
                }
            }
        }
    ]
    ParallelAnimation {
        id: animation
        
        loops: 2

        SequentialAnimation {
            PropertyAnimation { target: internal.rightAnswerRectangle; property: "rotation"; to: -45; duration: 200 }
            PropertyAnimation { target: internal.rightAnswerRectangle; property: "rotation"; to:  45; duration: 200 }
            PropertyAnimation { target: internal.rightAnswerRectangle; property: "rotation"; to:   0; duration: 200 }
        }
        SequentialAnimation {
            PropertyAnimation { target: internal.rightAnswerRectangle; property: "scale"; to: 1.2; duration: 300 }
            PropertyAnimation { target: internal.rightAnswerRectangle; property: "scale"; to: 1.0; duration: 300 }
        }

        onStopped: {
            exerciseView.state = "waitingForNewQuestion"
        }
    }
    Connections {
        target: core.exerciseController
        onSelectedExerciseOptionsChanged: pianoView.clearAllMarks()
    }
}
