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
import QtQuick.Controls 1.3

Item {
    id: exerciseView

    property string chosenExercise
    property string selectedType: "exercise"
    property Item answerRectangle

    signal answerHoverEnter(var chan, var pitch, var vel, var color)
    signal answerHoverExit(var chan, var pitch, var vel)

    function clearExerciseGrid() {
        exerciseView.visible = false
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
    }
    function highlightRightAnswer() {
        for (var i = 0; i < answerGrid.children.length; ++i) {
            answerGrid.children[i].enabled = false
            if (answerGrid.children[i].model.name != chosenExercise)
                answerGrid.children[i].opacity = 0.25
            else
                answerRectangle = answerGrid.children[i]
        }
        answerRectangle.model.sequenceFromRoot.split(' ').forEach(function(note) {
            answerHoverEnter(0, exerciseController.chosenRootNote() + parseInt(note), 0, answerRectangle.color)
        })
        animation.start()
    }
    function itemChanged(model) {
        sequencer.allNotesOff()
        clearExerciseGrid()
        var length = model.length
        answerGrid.columns = Math.min(6, length)
        answerGrid.rows = Math.ceil(length/6)
        var colors = ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        for (var i = 0; i < length; ++i)
            answerOption.createObject(answerGrid, {model: model[i], color: colors[i%24]})
        exerciseView.visible = true
        exerciseView.state = "initial"
    }
    function typeSelected(type) {
        selectedType = type
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
            text: i18n("Hear the %1 and then choose an answer from options below!<br/>Click 'play question' if you want to hear again!", selectedType)
        }
        Row {
            anchors { horizontalCenter: parent.horizontalCenter }
            spacing: 20
            Button {
                id: newQuestionButton

                width: 124; height: 44
                text: i18n("new question")
                onClicked: {
                    chosenExercise = exerciseController.randomlyChooseExercise()
                    messageText.text = i18n("Hear the interval and then choose an answer from options below!<br/>Click 'play question' if you want to hear again!")
                    exerciseView.state = "waitingForAnswer"
                    answerHoverEnter(0, exerciseController.chosenRootNote(), 0, "white")
                    exerciseController.playChoosenExercise()
                }
            }
            Button {
                id: playQuestionButton

                width: 124; height: 44
                text: i18n("play question")
                onClicked: exerciseController.playChoosenExercise()
            }
            Button {
                id: giveUpButton

                width: 124; height: 44
                text: i18n("give up")
                onClicked: highlightRightAnswer()
            }
        }
        Rectangle {
            width: answerGrid.columns*130+10; height: answerGrid.rows*50+10
            color: "#475057"
            radius: 5
            anchors.horizontalCenter: parent.horizontalCenter
            Grid {
                id: answerGrid

                anchors.centerIn: parent
                spacing: 10; columns: 2; rows: 1
                Component {
                    id: answerOption

                    Rectangle {
                        id: answerRectangle

                        property var model

                        width: 120; height: 40
                        Text {
                            id: option

                            property string originalText: model.name;

                            text: i18nc("technical term, do you have a musician friend?", model.name)
                            width: parent.width
                            anchors.centerIn: parent
                            horizontalAlignment: Qt.AlignHCenter
                            color: "black"
                            wrapMode: Text.Wrap
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                onExited()
                                if (option.originalText == chosenExercise)
                                    messageText.text = i18n("Congratulations!<br/>You answered correctly!")
                                else
                                    messageText.text = i18n("Oops, not this time!<br/>Try again!")
                                answerHoverExit(0, exerciseController.chosenRootNote() + parseInt(model.sequenceFromRoot), 0)
                                highlightRightAnswer()
                            }
                            hoverEnabled: true
                            onEntered: {
                                model.sequenceFromRoot.split(' ').forEach(function(note) {
                                    answerHoverEnter(0, exerciseController.chosenRootNote() + parseInt(note), 0, color)
                                })
                            }
                            onExited: {
                                if (!animation.running)
                                    model.sequenceFromRoot.split(' ').forEach(function(note) {
                                        answerHoverExit(0, exerciseController.chosenRootNote() + parseInt(note), 0)
                                    })
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
                }
            }
        },
        State {
            name: "waitingForAnswer"
            StateChangeScript {
                script: {
                    sequencer.allNotesOff()
                    for (var i = 0; i < answerGrid.children.length; ++i) {
                        answerGrid.children[i].opacity = 1
                        answerGrid.children[i].enabled = true
                    }
                    newQuestionButton.enabled = false
                    playQuestionButton.enabled = true
                    giveUpButton.enabled = true
                    answerGrid.enabled = true
                    answerGrid.opacity = 1
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
}
