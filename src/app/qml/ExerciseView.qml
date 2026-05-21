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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: exerciseView

    visible: exerciseView.currentExercise !== undefined

    property var currentExercise
    property alias countIn: internal.countIn
    readonly property bool exercisePlaying: Core.soundController !== null
        && Core.soundController.state === ISoundController.PlayingState

    FontLoader { id: bravura; source: "SheetMusicView/Bravura.otf" }

    QtObject {
        id: internal

        property int currentAnswer
        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        property Item rightAnswerRectangle
        property var userAnswers: []
        property bool answersAreRight
        property bool giveUp
        property bool isTest: false
        property int correctAnswers: 0
        property int currentExercise: 0
        property int countIn: 0
        property bool showingCorrectAnswers: false
        property Item hoveredAvailableAnswer

        onCurrentAnswerChanged: {
            for (var i = 0; i < yourAnswersParent.children.length; ++i)
                yourAnswersParent.children[i].destroy()
            yourAnswersParent.children = ""
            for (var i = 0; i < currentAnswer; ++i)
                answerOption.createObject(yourAnswersParent, { "model": userAnswers[i].model, "index": userAnswers[i].index, "position": i, "color": userAnswers[i].color  })
        }
    }

    onCurrentExerciseChanged: {
        internal.countIn = 0
        clearUserAnswers()
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
        answerGrid.children = ""
        if (exerciseView.currentExercise !== undefined) {
            var currentExerciseOptions = exerciseView.currentExercise["options"];
            if (currentExerciseOptions !== undefined) {
                var length = currentExerciseOptions.length
                for (var i = 0; i < length; ++i)
                    answerOption.createObject(answerGrid, {"model": currentExerciseOptions[i], "index": i, "color": internal.colors[i%internal.colors.length], "showClickFeedback": true})
            }
            sheetMusicView.spaced = (exerciseView.currentExercise["playMode"] === "chord") ? false:true
            messageText.text = i18n("Click 'New Question' to start!")
            exerciseView.state = "waitingForNewQuestion"
        }
    }

    function clearUserAnswers() {
        pianoView.clearAllMarks()
        sheetMusicView.clearAllMarks()
        internal.showingCorrectAnswers = false
        internal.hoveredAvailableAnswer = null
        for (var i = 0; i < yourAnswersParent.children.length; ++i)
            yourAnswersParent.children[i].destroy()
        yourAnswersParent.children = ""
        internal.currentAnswer = 0
        internal.userAnswers = []
    }

    function answerModel(answer) {
        return answer.model !== undefined ? answer.model : answer
    }

    function colorForAnswer(answer) {
        if (answer.color !== undefined) {
            return answer.color
        }

        var model = answerModel(answer)
        for (var i = 0; i < answerGrid.children.length; ++i) {
            if (answerGrid.children[i].model.name === model.name) {
                return answerGrid.children[i].color
            }
        }
        return "white"
    }

    function showAnswers(answers) {
        if (exerciseView.currentExercise["playMode"] === "rhythm") {
            return
        }

        var rootNote = Core.exerciseController.chosenRootNote()
        var sheetMusicModel = [rootNote]
        pianoView.clearAllMarks()
        pianoView.noteMark(0, rootNote, 0, "white")
        pianoView.scrollToNote(rootNote)

        for (var i = 0; i < answers.length; ++i) {
            var model = answerModel(answers[i])
            var color = colorForAnswer(answers[i])
            model.sequence.split(' ').forEach(function(note) {
                var pitch = rootNote + parseInt(note)
                pianoView.noteMark(0, pitch, 0, color)
                sheetMusicModel.push(pitch)
            })
        }
        sheetMusicView.model = sheetMusicModel
    }

    function showUserAnswers() {
        showAnswers(internal.userAnswers)
    }

    function showCorrectAnswers() {
        showAnswers(Core.exerciseController.selectedExerciseOptions)
    }

    function correctAnswerAt(position) {
        return Core.exerciseController.selectedExerciseOptions[position]
    }

    function isWrongSubmittedAnswer(position) {
        var rightAnswer = correctAnswerAt(position)
        return rightAnswer !== undefined
            && internal.userAnswers[position] !== undefined
            && internal.userAnswers[position].name !== rightAnswer.name
    }

    function canShowSubmittedAnswerCorrection(position) {
        return exerciseView.currentExercise !== undefined
            && internal.currentAnswer >= selectedOptionCount()
            && isWrongSubmittedAnswer(position)
    }

    function selectedOptionCount() {
        if (exerciseView.currentExercise === undefined) {
            return 0
        }
        if (exerciseView.currentExercise["playMode"] === "rhythm") {
            return Core.settingsController.rhythmPatternCount
        }
        return exerciseView.currentExercise.numberOfSelectedOptions
    }

    function maximumExercises() {
        return Core.settingsController.testExerciseCount
    }

    function showQuestionRootOnPiano() {
        showAnswers([])
    }

    function showAvailableAnswerPreview(answerRectangle) {
        internal.hoveredAvailableAnswer = answerRectangle
        showAnswers([{
            "model": answerRectangle.model,
            "color": internal.colors[answerRectangle.index % internal.colors.length]
        }])
    }

    function restoreAvailableAnswerPreview(answerRectangle) {
        if (internal.hoveredAvailableAnswer !== answerRectangle) {
            return
        }

        internal.hoveredAvailableAnswer = null
        showQuestionRootOnPiano()
    }

    function showSubmittedAnswerCorrection(answerRectangle) {
        if (!canShowSubmittedAnswerCorrection(answerRectangle.position)) {
            return
        }

        internal.showingCorrectAnswers = true
        showCorrectAnswers()
    }

    function restoreSubmittedAnswerCorrection(answerRectangle) {
        if (!canShowSubmittedAnswerCorrection(answerRectangle.position)) {
            return
        }

        internal.showingCorrectAnswers = false
        showUserAnswers()
    }

    function checkAnswers() {
        var rightAnswers = Core.exerciseController.selectedExerciseOptions
        internal.hoveredAvailableAnswer = null
        internal.answersAreRight = true
        var expectedAnswers = selectedOptionCount()
        for (var i = 0; i < expectedAnswers; ++i) {
            if (internal.userAnswers[i].name !== rightAnswers[i].name) {
                yourAnswersParent.children[i].borderColor = "red"
                yourAnswersParent.children[i].borderWidth = 3
                internal.answersAreRight = false
            }
            else {
                yourAnswersParent.children[i].borderColor = "green"
                yourAnswersParent.children[i].borderWidth = 3
                if (internal.isTest)
                    internal.correctAnswers++
            }
        }
        messageText.text = (internal.giveUp) ? i18n("Here is the answer") : (internal.answersAreRight) ? i18n("Congratulations, you answered correctly!"):i18n("Oops, not this time! Try again!")
        if (internal.currentExercise === maximumExercises()) {
            messageText.text = i18n("You answered correctly %1%", internal.correctAnswers * 100 / maximumExercises() / expectedAnswers)
            resetTest()
        }

        showUserAnswers()
        if (selectedOptionCount() === 1)
            highlightRightAnswer()
        else
            exerciseView.state = "waitingForNewQuestion"
        internal.giveUp = false
    }
    
    function highlightRightAnswer() {
        var chosenExercises = Core.exerciseController.selectedExerciseOptions
        for (var i = 0; i < answerGrid.children.length; ++i) {
            if (answerGrid.children[i].model.name !== chosenExercises[0].name) {
                answerGrid.children[i].opacity = 0.25
            }
            else {
                internal.rightAnswerRectangle = answerGrid.children[i]
                answerGrid.children[i].opacity = 1
            }
        }
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
        Core.soundController.play()
    }

    function generateNewQuestion () {
        clearUserAnswers()
        if (internal.isTest)
            messageText.text = i18n("Question %1 out of %2", internal.currentExercise + 1, maximumExercises())
        else
            messageText.text = ""
        Core.exerciseController.randomlySelectExerciseOptions(selectedOptionCount())
        var chosenExercises = Core.exerciseController.selectedExerciseOptions
        Core.soundController.prepareFromExerciseOptions(chosenExercises)
        if (exerciseView.currentExercise["playMode"] !== "rhythm") {
            pianoView.noteMark(0, Core.exerciseController.chosenRootNote(), 0, "white")
            pianoView.scrollToNote(Core.exerciseController.chosenRootNote())
            sheetMusicView.model = [Core.exerciseController.chosenRootNote()]
            sheetMusicView.activeClef.clefType = Core.exerciseController.chosenRootNote() >= 60 ? 0 : 1
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
            text: (exerciseView.currentExercise !== undefined) ? i18nc("technical term, do you have a musician friend?", exerciseView.currentExercise["userMessage"]):""
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
            enabled: !exerciseView.exercisePlaying
            spacing: Kirigami.Units.smallSpacing

            Button {
                id: newPlayQuestionButton

                text: (exerciseView.state === "waitingForNewQuestion") ? i18n("New Question") : i18n("Play Question")
                enabled: !animation.running
                Layout.preferredWidth: Math.max(newPlayQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

                onClicked: {
                    if (exerciseView.state === "waitingForNewQuestion") {
                        generateNewQuestion()
                    }
                    Core.soundController.play()
                }
            }
            Button {
                id: giveUpButton

                text: i18n("Give Up")
                enabled: exerciseView.state === "waitingForAnswer" && !animation.running
                Layout.preferredWidth: Math.max(newPlayQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

                onClicked: {
                    if (internal.isTest)
                        internal.correctAnswers--
                    internal.giveUp = true
                    var rightAnswers = Core.exerciseController.selectedExerciseOptions
                    internal.userAnswers = []
                    for (var i = 0; i < selectedOptionCount(); ++i) {
                        for (var j = 0; j < answerGrid.children.length; ++j) {
                            if (answerGrid.children[j].model.name === rightAnswers[i].name) {
                                internal.userAnswers.push({"name": rightAnswers[i].name, "model": answerGrid.children[j].model, "index": j, "color": internal.colors[j]})
                                break
                            }
                        }
                    }
                    internal.currentAnswer = selectedOptionCount()
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
                            Core.soundController.play()
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
                        property color borderColor: "transparent"
                        property int borderWidth: 0
                        property bool submittedAnswer: parent === yourAnswersParent
                        property bool wrongSubmittedAnswer: submittedAnswer && isWrongSubmittedAnswer(position)
                        property bool showCorrectAnswer: submittedAnswer && hoverArea.containsMouse && canShowSubmittedAnswerCorrection(position)
                        property string answerText: {
                            if (showCorrectAnswer) {
                                return i18nc("technical term, do you have a musician friend?", correctAnswerAt(position).name)
                            }
                            return i18nc("technical term, do you have a musician friend?", model.name)
                        }
                        property color displayColor: {
                            if (showCorrectAnswer) {
                                return colorForAnswer(correctAnswerAt(position))
                            }
                            return color
                        }

	                        Kirigami.Theme.backgroundColor: displayColor
                        background: Rectangle {
                            color: answerRectangle.displayColor
                            border.color: answerRectangle.borderColor
                            border.width: answerRectangle.borderWidth
                            radius: Kirigami.Units.cornerRadius
                        }

                        Layout.minimumWidth: answerGrid.minimumColumnWidth
                        Layout.minimumHeight: answerGrid.minimumColumnWidth / 2
                        Layout.maximumHeight: answerGrid.minimumColumnWidth / 2

                        onShowCorrectAnswerChanged: {
                            if (showCorrectAnswer) {
                                borderColor = "green"
                                showSubmittedAnswerCorrection(answerRectangle)
                            } else if (wrongSubmittedAnswer) {
                                borderColor = "red"
                                restoreSubmittedAnswerCorrection(answerRectangle)
                            }
                        }

                        function chooseAnswer() {
                            if (parent === answerGrid && exerciseView.state === "waitingForAnswer" && !animation.running) {
                                internal.userAnswers.push({"name": model.name, "model": answerRectangle.model, "index": answerRectangle.index, "color": answerRectangle.color})
                                internal.currentAnswer++
                                if (internal.currentAnswer === selectedOptionCount()) {
                                    checkAnswers()
                                }
                            }
                        }

                        Kirigami.Heading {
                            id: bravuraText

                            font {
                                family: exerciseView.currentExercise["playMode"] !== "rhythm" ? Kirigami.Theme.defaultFont.family : bravura.name
                                pointSize: Kirigami.Theme.defaultFont.pointSize * (exerciseView.currentExercise["playMode"] !== "rhythm" ? 1.15 : 2.3)
                            }
                            anchors {
                                centerIn: parent
                                verticalCenterOffset: exerciseView.currentExercise["playMode"] === "rhythm" ? font.pointSize * 0.35 : 0
                            }
                            width: parent.width
                            height: parent.height
                            padding: Kirigami.Units.smallSpacing
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            wrapMode: Text.Wrap
                            text: answerRectangle.answerText

                            Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                            Kirigami.Theme.inherit: false
                            color: Kirigami.Theme.backgroundColor
                        }

                        function handleHover(isHovered) {
                            if (isHovered) {
                                if (exerciseView.currentExercise["playMode"] !== "rhythm" && exerciseView.state === "waitingForAnswer") {
                                    if (parent === answerGrid && !animation.running) {
                                        showAvailableAnswerPreview(answerRectangle)
                                    }
                                } else if (parent === yourAnswersParent) {
                                    showSubmittedAnswerCorrection(answerRectangle)
                                }
                            } else {
                                if (exerciseView.currentExercise["playMode"] !== "rhythm" && exerciseView.state === "waitingForAnswer") {
                                    if (parent === answerGrid) {
                                        restoreAvailableAnswerPreview(answerRectangle)
                                    }
                                }
                                if (parent === yourAnswersParent) {
                                    restoreSubmittedAnswerCorrection(answerRectangle)
                                }
                            }
                        }

                        MouseArea {
                            id: hoverArea

                            anchors.fill: parent
                            z: 1
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: Qt.platform.os != "android"
                            onClicked: answerRectangle.chooseAnswer()
                            onContainsMouseChanged: answerRectangle.handleHover(containsMouse)
                        }
                    }
                }
            }
            ScrollIndicator.vertical: ScrollIndicator { active: true }
        }

        Kirigami.Heading {
            id: yourAnswersHeading

            text: internal.showingCorrectAnswers ? i18n("Correct Answer(s)") : i18n("Your Answer(s)")
        }

        Flickable {
            Layout.preferredWidth: (exerciseView.currentExercise !== undefined) ? Math.min(parent.width, internal.currentAnswer*130):0
            Layout.preferredHeight: answerGrid.minimumColumnWidth / 2
            Layout.alignment: Qt.AlignHCenter
            contentWidth: (exerciseView.currentExercise !== undefined) ? internal.currentAnswer*130:0
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
            visible: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] === "rhythm"
            enabled: internal.currentAnswer > 0 && internal.currentAnswer < selectedOptionCount()
            onClicked: {
                internal.userAnswers.pop()
                internal.currentAnswer--
            }
        }
        GridLayout {
            id: musicViewsLayout

            readonly property bool stacked: width < Kirigami.Units.gridUnit * 45
            readonly property real musicViewWidth: stacked ? width : (width - columnSpacing) / 2

            Layout.fillWidth: true
            columns: stacked ? 1 : 2
            columnSpacing: Kirigami.Units.largeSpacing * 2
            rowSpacing: stacked ? columnSpacing * 2 : columnSpacing
            uniformCellWidths: true
            visible: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] !== "rhythm"

            PianoView {
                id: pianoView

                Layout.fillWidth: true
                Layout.preferredWidth: musicViewsLayout.musicViewWidth
                Layout.minimumHeight: implicitHeight
                ScrollIndicator.horizontal: ScrollIndicator { active: true }
            }
            SheetMusicView {
                id: sheetMusicView

                Layout.fillWidth: true
                Layout.preferredWidth: musicViewsLayout.musicViewWidth
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
        loops: 2

        SequentialAnimation {
            SequentialAnimation {
                loops: 2

                PropertyAnimation { target: internal.rightAnswerRectangle; property: "scale"; to: 0.9; duration: 150 }
                PropertyAnimation { target: internal.rightAnswerRectangle; property: "scale"; to: 1.0; duration: 150 }
            }
            PauseAnimation { duration: 200 }
        }

        onStopped: {
            exerciseView.state = internal.isTest ? "waitingForAnswer" : "waitingForNewQuestion"
            if (internal.isTest) {
                nextTestExercise()
                if (internal.currentExercise === maximumExercises()+1)
                    internal.isTest = false
            }
        }
    }
    Connections {
        target: Core.exerciseController
        function onSelectedExerciseOptionsChanged() { pianoView.clearAllMarks() }
    }
    Connections {
        target: Core.exerciseController
        function onSelectedExerciseOptionsChanged() { sheetMusicView.clearAllMarks() }
    }
    Connections {
        target: Core.soundController
        function onCountInChanged(count) {
            internal.countIn = count
        }
    }
}
