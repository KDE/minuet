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

Item {
    id: exerciseView

    property var chosenExercises
    property var chosenColors: [4]
    property Item answerRectangle
    property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]

    signal answerHoverEnter(var chan, var pitch, var vel, var color)
    signal answerHoverExit(var chan, var pitch, var vel)
    signal answerClicked(var answerImageSource, var color)
    signal showCorrectAnswer(var chosenExercises, var chosenColors)

    function clearExerciseGrid() {
        exerciseView.visible = false
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
    }
    function highlightRightAnswer() {
        for (var i = 0; i < answerGrid.children.length; ++i) {
            answerGrid.children[i].enabled = false
            if (answerGrid.children[i].model.name != chosenExercises[0])
                answerGrid.children[i].opacity = 0.25
            else
                answerRectangle = answerGrid.children[i]
        }
        answerRectangle.model.sequence.split(' ').forEach(function(note) {
            answerHoverEnter(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, answerRectangle.color)
        })
        animation.start()
    }
    function setCurrentExercise() {
        var currentExercise = core.exerciseController.currentExercise
        clearExerciseGrid()
        var currentExerciseOptions = currentExercise["options"];
        if (currentExerciseOptions != undefined) {
            var length = currentExerciseOptions.length
            answerGrid.columns = Math.min(6, length)
            answerGrid.rows = Math.ceil(length/6)
            for (var i = 0; i < length; ++i)
                answerOption.createObject(answerGrid, {model: currentExerciseOptions[i], index: i, color: colors[i%24]})
            exerciseView.visible = true
        }
        exerciseView.state = "initial"
    }
    function checkAnswers(answers) {
        var answersOk = true
        for(var i = 0; i < 4; ++i) {
            if (answers[i].toString().split("/").pop().split(".")[0] != chosenExercises[i])
                answersOk = false
        }
        if (answersOk)
            messageText.text = i18n("Congratulations!<br/>You answered correctly!")
        else
            messageText.text = i18n("Oops, not this time!<br/>Try again!")
        exerciseView.state = "nextQuestion"
    }

    visible: false

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            id: messageText

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 18
            textFormat: Text.RichText
        }
        Row {
            anchors { horizontalCenter: parent.horizontalCenter }
            spacing: 20

            Button {
                id: newQuestionButton

                width: 124; height: 44
                text: i18n("new question")
                onClicked: {
                    exerciseView.state = "waitingForAnswer"
                    var playMode = core.exerciseController.currentExercise["playMode"]
                    core.exerciseController.randomlySelectExerciseOptions()
                    var selectedExerciseOptions = core.exerciseController.selectedExerciseOptions
                    core.soundBackend.playMode = playMode
                    core.soundBackend.prepareFromExerciseOptions(selectedExerciseOptions)
                    var newChosenExercises = [];
                    for (var i = 0; i < selectedExerciseOptions.length; ++i)
                        newChosenExercises.push(selectedExerciseOptions[i].name);
                    chosenExercises = newChosenExercises
                    for (var i = 0; i < chosenExercises.length; ++i)
                        for (var j = 0; j < answerGrid.children.length; ++j)
                            if (answerGrid.children[j].children[0].originalText == chosenExercises[i]) {
                                chosenColors[i] = answerGrid.children[j].color
                                break
                            }
                    if (playMode != "rhythm")
                        answerHoverEnter(0, core.exerciseController.chosenRootNote(), 0, "white")
                    core.soundBackend.play()
                }
            }
            Button {
                id: playQuestionButton

                width: 124; height: 44
                text: i18n("play question")
                onClicked: core.soundBackend.play()
            }
            Button {
                id: giveUpButton

                width: 124; height: 44
                text: i18n("give up")
                onClicked: {
                    if (core.exerciseController.currentExercise["playMode"] != "rhythm") {
                        highlightRightAnswer()
                    }
                    else {
                        showCorrectAnswer(chosenExercises, chosenColors)
                        exerciseView.state = "nextQuestion"
                    }
                }
            }
        }
        Rectangle {
            color: "#475057"
            radius: 5
            anchors.horizontalCenter: parent.horizontalCenter
            width: answerGrid.width + 20
            height: answerGrid.height + 20

            Grid {
                id: answerGrid

                anchors.centerIn: parent
                spacing: 10; columns: 2; rows: 1
                Component {
                    id: answerOption

                    Rectangle {
                        id: answerRectangle

                        property var model
                        property int index

                        width: (core.exerciseController.currentExercise["playMode"] != "rhythm") ? 120:119
                        height: (core.exerciseController.currentExercise["playMode"] != "rhythm") ? 40:59

                        Text {
                            id: option

                            property string originalText: model.name

                            visible: core.exerciseController.currentExercise["playMode"] != "rhythm"
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
                            visible: core.exerciseController.currentExercise["playMode"] == "rhythm"
                            source: (core.exerciseController.currentExercise["playMode"] == "rhythm") ? "exercise-images/" + model.name + ".png":""
                            fillMode: Image.Pad
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (core.exerciseController.currentExercise["playMode"] != "rhythm") {
                                    onExited()
                                    if (option.originalText == chosenExercises[0])
                                        messageText.text = i18n("Congratulations!<br/>You answered correctly!")
                                    else
                                        messageText.text = i18n("Oops, not this time!<br/>Try again!")
                                    answerHoverExit(0, core.exerciseController.chosenRootNote() + parseInt(model.sequence), 0)
                                    highlightRightAnswer()
                                }
                                else {
                                    answerClicked(rhythmImage.source, colors[answerRectangle.index])
                                }
                            }
                            hoverEnabled: true
                            onEntered: {
                                answerRectangle.color = Qt.darker(answerRectangle.color, 1.1)
                                if (core.exerciseController.currentExercise["playMode"] != "rhythm") {
                                    model.sequence.split(' ').forEach(function(note) {
                                        answerHoverEnter(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, colors[answerRectangle.index])
                                    })
                                }
                            }
                            onExited: {
                                answerRectangle.color = colors[answerRectangle.index]
                                if (core.exerciseController.currentExercise["playMode"] != "rhythm") {
                                    if (!animation.running)
                                        model.sequence.split(' ').forEach(function(note) {
                                            answerHoverExit(0, core.exerciseController.chosenRootNote() + parseInt(note), 0)
                                        })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    states: [
        State {
            name: "initial"
            StateChangeScript {
                script: {
                    newQuestionButton.enabled = true
                    playQuestionButton.enabled = false
                    giveUpButton.enabled = false
                    answerGrid.enabled = false
                    answerGrid.opacity = 0.25
                    messageText.text = i18n("%1<br/>Click 'play question' if you want to hear again!",
                                       i18nc("technical term, do you have a musician friend?", core.exerciseController.currentExercise["userMessage"]))
                }
            }
        },
        State {
            name: "waitingForAnswer"
            StateChangeScript {
                script: {
                    for (var i = 0; i < answerGrid.children.length; ++i) {
                        answerGrid.children[i].opacity = 1
                        answerGrid.children[i].enabled = true
                    }
                    newQuestionButton.enabled = false
                    playQuestionButton.enabled = true
                    giveUpButton.enabled = true
                    answerGrid.enabled = true
                    answerGrid.opacity = 1
                    messageText.text = i18n("%1<br/>Click 'play question' if you want to hear again!",
                                       i18nc("technical term, do you have a musician friend?", core.exerciseController.currentExercise["userMessage"]))
                }
            }
        },
        State {
            name: "nextQuestion"
            StateChangeScript {
                script: {
                    newQuestionButton.enabled = true
                    playQuestionButton.enabled = false
                    giveUpButton.enabled = false
                    answerGrid.enabled = false
                }
            }
        }
    ]
    ParallelAnimation {
        id: animation
        
        loops: 2

        SequentialAnimation {
            PropertyAnimation { target: answerRectangle; property: "rotation"; to: -45; duration: 200 }
            PropertyAnimation { target: answerRectangle; property: "rotation"; to:  45; duration: 200 }
            PropertyAnimation { target: answerRectangle; property: "rotation"; to:   0; duration: 200 }
        }
        SequentialAnimation {
            PropertyAnimation { target: answerRectangle; property: "scale"; to: 1.2; duration: 300 }
            PropertyAnimation { target: answerRectangle; property: "scale"; to: 1.0; duration: 300 }
        }
        
        onStopped: exerciseView.state = "nextQuestion"
    }
    Connections {
        target: core.exerciseController
        onCurrentExerciseChanged: setCurrentExercise()
    }
}
