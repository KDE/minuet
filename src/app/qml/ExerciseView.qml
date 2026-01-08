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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: exerciseView

    visible: currentExercise != undefined

    property var currentExercise

    FontLoader { id: bravura; source: "Bravura.otf" }

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
                answerOption.createObject(yourAnswersParent, { "model": userAnswers[i].model, "index": userAnswers[i].index, "position": i, "color": userAnswers[i].color  })
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
                    answerOption.createObject(answerGrid, {"model": currentExerciseOptions[i], "index": i, "color": internal.colors[i%internal.colors.length], "showClickFeedback": true})
            }
            sheetMusicView.spaced = (currentExercise["playMode"] == "chord") ? false:true
            messageText.text = i18n("Click 'New Question' to start!")
            exerciseView.state = "waitingForNewQuestion"
        }
    }

    function clearUserAnswers() {
        pianoView.clearAllMarks()
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
                yourAnswersParent.children[i].background.border.color = "red"
                yourAnswersParent.children[i].background.border.width = 3
                internal.answersAreRight = false
            }
            else {
                yourAnswersParent.children[i].background.border.color = "green"
                yourAnswersParent.children[i].background.border.width = 3
                if (internal.isTest)
                    internal.correctAnswers++
            }
        }
        messageText.text = (internal.giveUp) ? i18n("Here is the answer") : (internal.answersAreRight) ? i18n("Congratulations, you answered correctly!"):i18n("Oops, not this time! Try again!")
        if (internal.currentExercise == internal.maximumExercises) {
            messageText.text = i18n("You answered correctly %1%", internal.correctAnswers * 100 / internal.maximumExercises / currentExercise.numberOfSelectedOptions)
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
            pianoView.noteMark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, internal.rightAnswerRectangle.color)
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
        pianoView.clearAllMarks()
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
            pianoView.noteMark(0, core.exerciseController.chosenRootNote(), 0, "white")
            pianoView.scrollToNote(core.exerciseController.chosenRootNote())
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

        Kirigami.Heading {
            id: userMessage

            level: 1
            Layout.preferredWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: (currentExercise != undefined) ? i18nc("technical term, do you have a musician friend?", currentExercise["userMessage"]):""
        }
        Kirigami.Heading {
            id: messageText

            level: 2
            Layout.preferredWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing

            Button {
                id: newPlayQuestionButton

                text: (exerciseView.state == "waitingForNewQuestion") ? i18n("New Question") : i18n("Play Question")
                enabled: !animation.running
                Layout.preferredWidth: Math.max(newPlayQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

                onClicked: {
                    if (exerciseView.state == "waitingForNewQuestion") {
                        generateNewQuestion()
                    }
                    core.soundController.play()
                }
            }
            Button {
                id: giveUpButton

                text: i18n("Give Up")
                enabled: exerciseView.state == "waitingForAnswer" && !animation.running
                Layout.preferredWidth: Math.max(newPlayQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

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

                text: internal.isTest ? i18n("Stop Test") : i18n("Start Test")
                enabled: true
                Layout.preferredWidth: Math.max(newPlayQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

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

        Kirigami.Heading {
            text: i18n("Available Answers")
        }

        Flickable {
            Layout.preferredWidth: parent.width
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: answerGrid.height
            clip: true

            Kirigami.CardsLayout {
                id: answerGrid

                width: parent.width
                rowSpacing: Kirigami.Units.largeSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                maximumColumns: Math.max(1, Screen.width / (minimumColumnWidth + columnSpacing))
                minimumColumnWidth: 120

                Component {
                    id: answerOption

                    Kirigami.AbstractCard {
                        id: answerRectangle

                        property var model
                        property int index
                        property int position
                        property color color

                        Kirigami.Theme.backgroundColor: color

                        Layout.minimumWidth: answerGrid.minimumColumnWidth
                        Layout.minimumHeight: answerGrid.minimumColumnWidth / 2
                        Layout.maximumHeight: answerGrid.minimumColumnWidth / 2

                        Kirigami.Heading {
                            id: bravuraText

                            font {
                                family: currentExercise["playMode"] != "rhythm" ? Kirigami.Theme.defaultFont.family : bravura.name
                                pointSize: Kirigami.Theme.defaultFont.pointSize * (currentExercise["playMode"] != "rhythm" ? 1.15 : 2.3)
                            }
                            anchors {
                                centerIn: parent
                                verticalCenterOffset: currentExercise["playMode"] === "rhythm" ? font.pointSize * 0.35 : 0
                            }
                            width: parent.width
                            height: parent.height
                            padding: Kirigami.Units.smallSpacing
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            wrapMode: Text.Wrap
                            text: model.name

                            Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                            Kirigami.Theme.inherit: false
                            color: Kirigami.Theme.backgroundColor
                        }

                        onClicked: {
                            if (exerciseView.state == "waitingForAnswer" && !animation.running) {
                                internal.userAnswers.push({"name": bravuraText.text, "model": answerRectangle.model, "index": answerRectangle.index, "color": answerRectangle.color})
                                internal.currentAnswer++
                                if (internal.currentAnswer == currentExercise.numberOfSelectedOptions)
                                    checkAnswers()
                            }
                        }
                        hoverEnabled: Qt.platform.os != "android" && !animation.running
                        onHoveredChanged: {
                            if (hovered) {
                                if (currentExercise["playMode"] !== "rhythm" && exerciseView.state === "waitingForAnswer") {
                                    if (parent === answerGrid) {
                                        var array = [core.exerciseController.chosenRootNote()]
                                        model.sequence.split(' ').forEach(function(note) {
                                            array.push(core.exerciseController.chosenRootNote() + parseInt(note))
                                            pianoView.noteMark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0, internal.colors[answerRectangle.index%internal.colors.length])
                                        })
                                        sheetMusicView.model = array
                                    }
                                }
                                else {
                                    var rightAnswers = core.exerciseController.selectedExerciseOptions
                                    if (parent === yourAnswersParent && internal.userAnswers[position].name !== rightAnswers[position].name) {
                                        background.border.color = "green"
                                        for (var i = 0; i < answerGrid.children.length; ++i) {
                                            if (answerGrid.children[i].model.name == rightAnswers[position].name) {
                                                background.color = answerGrid.children[i].color
                                                break
                                            }
                                        }
                                        bravuraText.text = rightAnswers[position].name
                                    }
                                }
                            }
                            else {
                                if (currentExercise["playMode"] !== "rhythm") {
                                    if (parent === answerGrid) {
                                        if (!animation.running)
                                            model.sequence.split(' ').forEach(function(note) {
                                                pianoView.noteUnmark(0, core.exerciseController.chosenRootNote() + parseInt(note), 0)
                                            })
                                        sheetMusicView.model = [core.exerciseController.chosenRootNote()]
                                    }
                                }
                                var rightAnswers = core.exerciseController.selectedExerciseOptions
                                if (parent === yourAnswersParent && internal.userAnswers[position].name !== rightAnswers[position].name) {
                                    background.border.color = "red"
                                    background.color = internal.userAnswers[position].color
                                    bravuraText.text = internal.userAnswers[position].name
                                }
                            }
                        }
                    }
                }
            }
            ScrollIndicator.vertical: ScrollIndicator { active: true }
        }

        Kirigami.Heading {
            text: i18n("Your Answer(s)")
        }

        Flickable {
            Layout.preferredWidth: (currentExercise != undefined) ? Math.min(parent.width, internal.currentAnswer*130):0; height: parent.height
            Layout.preferredHeight: answerGrid.minimumColumnWidth / 2
            Layout.alignment: Qt.AlignHCenter
            contentWidth: (currentExercise != undefined) ? internal.currentAnswer*130:0
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            RowLayout {
                id: yourAnswersParent

                anchors.centerIn: parent
                spacing: Kirigami.Units.largeSpacing
            }

            ScrollIndicator.horizontal: ScrollIndicator { active: true }
        }

        Button {
            id: backspaceButton

            text: i18n("Backspace")
            Layout.alignment: Qt.AlignHCenter
            visible: currentExercise != undefined && currentExercise["playMode"] == "rhythm"
            enabled: internal.currentAnswer > 0 && internal.currentAnswer < currentExercise.numberOfSelectedOptions
            onClicked: {
                internal.userAnswers.pop()
                internal.currentAnswer--
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: window.wideScreen ? 2 : 1
            rowSpacing: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing * 2
            visible: currentExercise != undefined && currentExercise["playMode"] != "rhythm"

            PianoView {
                id: pianoView

                Layout.fillWidth: true
                Layout.minimumHeight: implicitHeight
                ScrollIndicator.horizontal: ScrollIndicator { active: true }
            }
            SheetMusicView {
                id: sheetMusicView

                Layout.preferredHeight: pianoView.height
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
        loops: 3

        SequentialAnimation {
            SequentialAnimation {
                loops: 3

                PropertyAnimation { target: internal.rightAnswerRectangle; property: "scale"; to: 1.1; duration: 150 }
                PropertyAnimation { target: internal.rightAnswerRectangle; property: "scale"; to: 1.0; duration: 150 }
            }
            PauseAnimation { duration: 500 }
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
        function onSelectedExerciseOptionsChanged() { pianoView.clearAllMarks() }
    }
    Connections {
        target: core.exerciseController
        function onSelectedExerciseOptionsChanged() { sheetMusicView.clearAllMarks() }
    }
}
