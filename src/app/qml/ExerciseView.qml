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
        property bool answersAreRight
        property bool giveUp
        property bool isTest: false
        property int correctAnswers: 0
        property int currentExercise: 0
        property int maximumExercises: 10

        onCurrentAnswerChanged: {
            for (var i = 0; i < yourAnswersParent.children.length; ++i)
                yourAnswersParent.children[i].destroy()
            yourAnswersParent.children = ""
            for (var i = 0; i < currentAnswer; ++i)
                answerOption.createObject(yourAnswersParent, {"model": userAnswers[i].model, "index": userAnswers[i].index, "position": i, "color": userAnswers[i].color, "border.width": 2})
        }
    }

    onCurrentExerciseChanged: {
        clearUserAnswers()
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
        answerGrid.children = ""
        if (currentExercise != undefined) {
            var currentExerciseOptions = currentExercise["options"];
            if (currentExerciseOptions != undefined) {
                var length = currentExerciseOptions.length
                for (var i = 0; i < length; ++i)
                    answerOption.createObject(answerGrid, {"model": currentExerciseOptions[i], "index": i, "color": internal.colors[i%24]})
            }
            sheetMusicView.spaced = (currentExercise["playMode"] == "chord") ? false:true
            messageText.text = i18n("Click 'New Question' to start!")
            exerciseView.state = "waitingForNewQuestion"
        }
    }

    function clearUserAnswers() {
        instrumentView.clearAllMarks()
        sheetMusicView.clearAllMarks()
        for (var i = 0; i < yourAnswersParent.children.length; ++i)
            yourAnswersParent.children[i].destroy()
        yourAnswersParent.children = ""
        internal.currentAnswer = 0
        internal.userAnswers = []
    }

    function checkAnswers() {
        var rightAnswers = core.exerciseController.selectedExerciseOptions
        internal.answersAreRight = true
        for (var i = 0; i < currentExercise.numberOfSelectedOptions; ++i) {
            if (internal.userAnswers[i].name != rightAnswers[i].name) {
                yourAnswersParent.children[i].border.color = "red"
                internal.answersAreRight = false
            }
            else {
                yourAnswersParent.children[i].border.color = "green"
                if (internal.isTest)
                    internal.correctAnswers++
            }
        }
        messageText.text = (internal.giveUp) ? i18n("Here is the answer") : (internal.answersAreRight) ? i18n("Congratulations, you answered correctly!"):i18n("Oops, not this time! Try again!")
        if (internal.currentExercise == internal.maximumExercises) {
            messageText.text = i18n("You answered correctly %1%", internal.correctAnswers * 100 / internal.maximumExercises)
            resetTest()
        }

        if (currentExercise.numberOfSelectedOptions == 1)
            highlightRightAnswer()
        else
            exerciseView.state = "waitingForNewQuestion"
        internal.giveUp = false
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
        var array = [core.exerciseController.chosenRootNote()]
        internal.rightAnswerRectangle.model.sequence.split(' ').forEach(function(note) {
            instrumentView.noteMark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, internal.rightAnswerRectangle.color)
            array.push(core.exerciseController.chosenRootNote() + parseInt(note))
        })
        sheetMusicView.model = array
        animation.start()
    }

    function resetTest() {
        internal.isTest = false
        internal.correctAnswers = 0
        internal.currentExercise = 0
    }

    function nextTestExercise() {
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].opacity = 1
        instrumentView.clearAllMarks()
        sheetMusicView.clearAllMarks()
        clearUserAnswers()
        generateNewQuestion(true)
        core.soundController.play()
    }

    function generateNewQuestion () {
        clearUserAnswers()
        if (internal.isTest)
            messageText.text = i18n("Question %1 out of %2", internal.currentExercise + 1, internal.maximumExercises)
        else
            messageText.text = ""
        core.exerciseController.randomlySelectExerciseOptions()
        var chosenExercises = core.exerciseController.selectedExerciseOptions
        core.soundController.prepareFromExerciseOptions(chosenExercises)
        if (currentExercise["playMode"] != "rhythm") {
            instrumentView.noteMark(0, core.exerciseController.chosenRootNote(), 0, "white")
            instrumentView.scrollToNote(core.exerciseController.chosenRootNote())
            sheetMusicView.model = [core.exerciseController.chosenRootNote()]
            sheetMusicView.clef.type = (core.exerciseController.chosenRootNote() >= 60) ? 0:1
        }
        exerciseView.state = "waitingForAnswer"
        if (internal.isTest)
            internal.currentExercise++
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
                text: (exerciseView.state == "waitingForNewQuestion") ? i18n("New Question"):i18n("Play Question")
                enabled: !animation.running

                onClicked: {
                    if (exerciseView.state == "waitingForNewQuestion") {
                        generateNewQuestion()
                    }
                    core.soundController.play()
                }
            }
            Button {
                id: giveUpButton

                width: 120; height: 40
                text: i18n("Give Up")
                enabled: exerciseView.state == "waitingForAnswer" && !animation.running

                onClicked: {
                    if (internal.isTest)
                        internal.correctAnswers--
                	internal.giveUp = true
                    var rightAnswers = core.exerciseController.selectedExerciseOptions
                    internal.userAnswers = []
                    for (var i = 0; i < currentExercise.numberOfSelectedOptions; ++i) {
                        for (var j = 0; j < answerGrid.children.length; ++j) {
                            if (answerGrid.children[j].model.name == rightAnswers[i].name) {
                                internal.userAnswers.push({"name": rightAnswers[i].name, "model": answerGrid.children[j].model, "index": j, "color": internal.colors[j]})
                                break
                            }
                        }
                    }
                    internal.currentAnswer = currentExercise.numberOfSelectedOptions
                    checkAnswers()
                }
            }
            Button {
                id: testButton

                width: 120; height: 40
                text: internal.isTest ? i18n("Stop Test") : i18n("Start Test")
                enabled: true

                onClicked: {
                    if (!internal.isTest) {
                        resetTest()
                        internal.isTest = true
                        generateNewQuestion()
                        if (internal.isTest)
                            core.soundController.play()
                    } else {
                        resetTest()
                        exerciseView.state = "waitingForNewQuestion"
                        messageText.text = i18n("Click 'New Question' to start")
                    }
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
                            property int position

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
                                        internal.userAnswers.push({"name": option.originalText, "model": answerRectangle.model, "index": answerRectangle.index, "color": answerRectangle.color})
                                        internal.currentAnswer++
                                        if (internal.currentAnswer == currentExercise.numberOfSelectedOptions)
                                            checkAnswers()
                                    }
                                }
                                hoverEnabled: Qt.platform.os != "android" && !animation.running
                                onEntered: {
                                    answerRectangle.color = Qt.darker(answerRectangle.color, 1.1)
                                    if (currentExercise["playMode"] != "rhythm" && exerciseView.state == "waitingForAnswer") {
                                        if (parent.parent == answerGrid) {
                                            var array = [core.exerciseController.chosenRootNote()]
                                            model.sequence.split(' ').forEach(function(note) {
                                                array.push(core.exerciseController.chosenRootNote() + parseInt(note))
                                                instrumentView.noteMark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, internal.colors[answerRectangle.index])
                                            })
                                            sheetMusicView.model = array
                                        }
                                    }
                                    else {
                                        var rightAnswers = core.exerciseController.selectedExerciseOptions
                                        if (parent.parent == yourAnswersParent && internal.userAnswers[position].name != rightAnswers[position].name) {
                                            parent.border.color = "green"
                                            for (var i = 0; i < answerGrid.children.length; ++i) {
                                                if (answerGrid.children[i].model.name == rightAnswers[position].name) {
                                                    parent.color = answerGrid.children[i].color
                                                    break
                                                }
                                            }
                                            rhythmImage.source = "exercise-images/" + rightAnswers[position].name + ".png"
                                        }
                                    }
                                }
                                onExited: {
                                    answerRectangle.color = internal.colors[answerRectangle.index]
                                    if (currentExercise["playMode"] != "rhythm") {
                                        if (parent.parent == answerGrid) {
                                            if (!animation.running)
                                                model.sequence.split(' ').forEach(function(note) {
                                                    instrumentView.noteUnmark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0)
                                                })
                                            sheetMusicView.model = [core.exerciseController.chosenRootNote()]
                                        }
                                    }
                                    else {
                                        var rightAnswers = core.exerciseController.selectedExerciseOptions
                                        if (parent.parent == yourAnswersParent && internal.userAnswers[position].name != rightAnswers[position].name) {
                                            parent.border.color = "red"
                                            parent.color = internal.userAnswers[position].color
                                            rhythmImage.source = "exercise-images/" + internal.userAnswers[position].name + ".png"
                                        }
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

            Flickable {
                width: (currentExercise != undefined) ? Math.min(parent.width, internal.currentAnswer*130):0; height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                contentWidth: (currentExercise != undefined) ? internal.currentAnswer*130:0
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Row {
                    id: yourAnswersParent
                    anchors.centerIn: parent
                    spacing: Screen.width >= 1024 ? 10:5
                }

                ScrollIndicator.horizontal: ScrollIndicator { active: true }
            }
        }
        Button {
            id: backspaceButton

            text: i18n("Backspace")
            anchors.horizontalCenter: parent.horizontalCenter
            visible: currentExercise != undefined && currentExercise["playMode"] == "rhythm"
            enabled: internal.currentAnswer > 0 && internal.currentAnswer < currentExercise.numberOfSelectedOptions
            onClicked: {
                internal.userAnswers.pop()
                internal.currentAnswer--
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            Layout.preferredWidth: parent.width
            spacing: (parent.width/2 - sheetMusicView.width)/2

            InstrumentView {
                id: instrumentView
                width: parent.width/2 - 10
                height: 150
                visible: currentExercise != undefined && currentExercise["playMode"] != "rhythm"
            }

            SheetMusicView {
                id: sheetMusicView

                height: instrumentView.height
                anchors { bottom: parent.bottom; bottomMargin: 15 }
                visible: currentExercise != undefined && currentExercise["playMode"] != "rhythm"
            }
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
            exerciseView.state = internal.isTest ? "waitingForAnswer" : "waitingForNewQuestion"
            if (internal.isTest) {
                nextTestExercise()
                if (internal.currentExercise == internal.maximumExercises+1)
                   internal.isTest = false
            }
        }
    }
    Connections {
        target: core.exerciseController
        onSelectedExerciseOptionsChanged: instrumentView.clearAllMarks()
    }
    Connections {
        target: core.exerciseController
        onSelectedExerciseOptionsChanged: sheetMusicView.clearAllMarks()
    }
}
