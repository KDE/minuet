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
    readonly property bool compactPortrait: exerciseView.width < Kirigami.Units.gridUnit * 38
        && exerciseView.height > exerciseView.width
    readonly property bool compact: exerciseView.width < Kirigami.Units.gridUnit * 52
    readonly property bool wide: exerciseView.width >= Kirigami.Units.gridUnit * 72
    readonly property real maximumContentWidth: Kirigami.Units.gridUnit * 86
    readonly property real answerCellSpacing: Kirigami.Units.smallSpacing
    readonly property real answerCellHeight: Math.max(Kirigami.Units.gridUnit * (compactPortrait ? 4.1 : 3.6), Kirigami.Units.iconSizes.large + Kirigami.Units.largeSpacing * 2)
    readonly property real selectedAnswerHeight: Math.max(Kirigami.Units.gridUnit * 3.4, Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 2)
    readonly property int answerColumnCount: {
        const availableWidth = Math.max(1, answerGridView.width)
        if (compactPortrait) {
            return 2
        }
        const preferredWidth = Kirigami.Units.gridUnit * (compact ? 9 : 13)
        const fittedColumns = Math.max(1, Math.floor(availableWidth / preferredWidth))
        return Math.max(1, Math.min(wide ? 5 : 4, fittedColumns))
    }

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
        property int correctedAnswerPosition: -1
        property bool highlightingSingleAnswer: false
        property string highlightedAnswerName: ""
        property string statusText: ""
    }

    onCurrentExerciseChanged: {
        internal.countIn = 0
        clearUserAnswers()
        if (exerciseView.currentExercise !== undefined) {
            sheetMusicView.spaced = exerciseView.currentExercise["playMode"] !== "chord"
            internal.statusText = i18n("Click 'New Question' to start!")
            exerciseView.state = "waitingForNewQuestion"
        }
    }

    function clearUserAnswers(): void {
        pianoView.clearAllMarks()
        sheetMusicView.clearAllMarks()
        internal.showingCorrectAnswers = false
        internal.correctedAnswerPosition = -1
        internal.highlightingSingleAnswer = false
        internal.highlightedAnswerName = ""
        internal.hoveredAvailableAnswer = null
        internal.currentAnswer = 0
        internal.userAnswers = []
    }

    function availableAnswersModel(): var {
        if (exerciseView.currentExercise === undefined || exerciseView.currentExercise.options === undefined) {
            return []
        }
        return exerciseView.currentExercise.options
    }

    function answerModel(answer: var): var {
        if (answer === undefined || answer === null) {
            return {}
        }
        return answer.model !== undefined ? answer.model : answer
    }

    function colorForAnswerIndex(index: int): color {
        if (!isFinite(index) || index < 0 || index >= internal.colors.length) {
            return "white"
        }
        return internal.colors[index % internal.colors.length]
    }

    function answerIndexForName(answerName: string): int {
        const answers = availableAnswersModel()
        for (var i = 0; i < answers.length; ++i) {
            if (answerModel(answers[i]).name === answerName) {
                return i
            }
        }
        return -1
    }

    function colorForAnswer(answer: var): color {
        if (answer.color !== undefined) {
            return answer.color
        }

        var model = answerModel(answer)
        var index = answerIndexForName(model.name)
        return index >= 0 ? colorForAnswerIndex(index) : "white"
    }

    function submittedAnswerFor(option: var): var {
        const index = answerIndexForName(option.name)
        return {
            "name": option.name,
            "model": option,
            "index": index,
            "color": index >= 0 ? colorForAnswerIndex(index) : "white"
        }
    }

    function showAnswers(answers: var): void {
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
            model.sequence.split(' ').forEach(function(note: string): void {
                var pitch = rootNote + parseInt(note)
                pianoView.noteMark(0, pitch, 0, color)
                sheetMusicModel.push(pitch)
            })
        }
        sheetMusicView.model = sheetMusicModel
    }

    function showUserAnswers(): void {
        showAnswers(internal.userAnswers)
    }

    function showCorrectAnswers(): void {
        showAnswers(Core.exerciseController.selectedExerciseOptions)
    }

    function correctAnswerAt(position: int): var {
        return Core.exerciseController.selectedExerciseOptions[position]
    }

    function isWrongSubmittedAnswer(position: int): bool {
        var rightAnswer = correctAnswerAt(position)
        return rightAnswer !== undefined
            && internal.userAnswers[position] !== undefined
            && internal.userAnswers[position].name !== rightAnswer.name
    }

    function canShowSubmittedAnswerCorrection(position: int): bool {
        return exerciseView.currentExercise !== undefined
            && internal.currentAnswer >= selectedOptionCount()
            && isWrongSubmittedAnswer(position)
    }

    function selectedOptionCount(): int {
        if (exerciseView.currentExercise === undefined) {
            return 0
        }
        if (exerciseView.currentExercise["playMode"] === "rhythm") {
            return Core.settingsController.rhythmPatternCount
        }
        return exerciseView.currentExercise.numberOfSelectedOptions
    }

    function maximumExercises(): int {
        return Core.settingsController.testExerciseCount
    }

    function answerInstruction(): string {
        const count = selectedOptionCount()
        return count === 1 ? i18n("Choose 1 answer") : i18n("Choose %1 answers", count)
    }

    function showQuestionRootOnPiano(): void {
        showAnswers([])
    }

    function showAvailableAnswerPreview(answerRectangle: Item): void {
        internal.hoveredAvailableAnswer = answerRectangle
        showAnswers([{
            "model": answerRectangle.model,
            "color": colorForAnswerIndex(answerRectangle.index)
        }])
    }

    function restoreAvailableAnswerPreview(answerRectangle: Item): void {
        if (internal.hoveredAvailableAnswer !== answerRectangle) {
            return
        }

        internal.hoveredAvailableAnswer = null
        showQuestionRootOnPiano()
    }

    function showSubmittedAnswerCorrection(position: int): void {
        if (!canShowSubmittedAnswerCorrection(position)) {
            return
        }

        internal.correctedAnswerPosition = position
        internal.showingCorrectAnswers = true
        showCorrectAnswers()
    }

    function restoreSubmittedAnswerCorrection(position: int): void {
        if (!canShowSubmittedAnswerCorrection(position)) {
            return
        }

        internal.correctedAnswerPosition = -1
        internal.showingCorrectAnswers = false
        showUserAnswers()
    }

    function toggleSubmittedAnswerCorrection(position: int): void {
        if (internal.correctedAnswerPosition === position) {
            restoreSubmittedAnswerCorrection(position)
        } else {
            showSubmittedAnswerCorrection(position)
        }
    }

    function chooseAnswer(answer: var, index: int): void {
        if (exerciseView.state !== "waitingForAnswer" || animation.running || internal.currentAnswer >= selectedOptionCount()) {
            return
        }

        internal.userAnswers = internal.userAnswers.concat([{
            "name": answer.name,
            "model": answer,
            "index": index,
            "color": colorForAnswerIndex(index)
        }])
        internal.currentAnswer++
        if (internal.currentAnswer === selectedOptionCount()) {
            checkAnswers()
        }
    }

    function canEditUserAnswers(): bool {
        return exerciseView.state === "waitingForAnswer"
            && internal.currentAnswer > 0
            && internal.currentAnswer < selectedOptionCount()
            && !animation.running
    }

    function removeUserAnswerAt(position: int): void {
        if (!canEditUserAnswers() || position < 0 || position >= internal.userAnswers.length) {
            return
        }
        var answers = internal.userAnswers.slice()
        answers.splice(position, 1)
        internal.userAnswers = answers
        internal.currentAnswer--
        showUserAnswers()
    }

    function removeLastUserAnswer(): void {
        removeUserAnswerAt(internal.userAnswers.length - 1)
    }

    function checkAnswers(): void {
        var rightAnswers = Core.exerciseController.selectedExerciseOptions
        internal.hoveredAvailableAnswer = null
        internal.answersAreRight = true
        var expectedAnswers = selectedOptionCount()
        for (var i = 0; i < expectedAnswers; ++i) {
            if (internal.userAnswers[i].name !== rightAnswers[i].name) {
                internal.answersAreRight = false
            } else {
                if (internal.isTest)
                    internal.correctAnswers++
            }
        }
        internal.statusText = (internal.giveUp) ? i18n("Here is the answer") : (internal.answersAreRight) ? i18n("Congratulations, you answered correctly!") : i18n("Oops, not this time! Try again!")
        if (internal.currentExercise === maximumExercises()) {
            internal.statusText = i18n("You answered correctly %1%", internal.correctAnswers * 100 / maximumExercises() / expectedAnswers)
            resetTest()
        }

        showUserAnswers()
        if (selectedOptionCount() === 1)
            highlightRightAnswer()
        else
            exerciseView.state = "waitingForNewQuestion"
        internal.giveUp = false
    }

    function highlightRightAnswer(): void {
        var chosenExercises = Core.exerciseController.selectedExerciseOptions
        var rightAnswerIndex = answerIndexForName(chosenExercises[0].name)
        internal.rightAnswerRectangle = null
        internal.highlightingSingleAnswer = true
        internal.highlightedAnswerName = chosenExercises[0].name
        if (rightAnswerIndex >= 0 && !internal.answersAreRight) {
            answerGridView.positionViewAtIndex(rightAnswerIndex, GridView.Contain)
        }
        for (var i = 0; i < answerGridView.count; ++i) {
            const answerItem = answerGridView.itemAtIndex(i)
            if (answerItem === null) {
                continue
            }
            if (answerItem.model.name === chosenExercises[0].name) {
                internal.rightAnswerRectangle = answerItem
                break
            }
        }
        if (internal.rightAnswerRectangle !== null) {
            animation.start()
        } else {
            finishSingleAnswerFeedback()
        }
    }

    function resetTest(): void {
        internal.isTest = false
        internal.correctAnswers = 0
        internal.currentExercise = 0
    }

    function finishSingleAnswerFeedback(): void {
        exerciseView.state = internal.isTest ? "waitingForAnswer" : "waitingForNewQuestion"
        if (internal.isTest) {
            nextTestExercise()
            if (internal.currentExercise === maximumExercises() + 1)
                internal.isTest = false
        }
    }

    function nextTestExercise(): void {
        for (var i = 0; i < answerGridView.count; ++i) {
            const answerItem = answerGridView.itemAtIndex(i)
            if (answerItem !== null) {
                answerItem.opacity = 1
            }
        }
        pianoView.clearAllMarks()
        sheetMusicView.clearAllMarks()
        clearUserAnswers()
        generateNewQuestion(true)
        Core.soundController.play()
    }

    function generateNewQuestion(): void {
        clearUserAnswers()
        if (internal.isTest)
            internal.statusText = i18n("Question %1 out of %2", internal.currentExercise + 1, maximumExercises())
        else
            internal.statusText = ""
        Core.exerciseController.randomlySelectExerciseOptions(selectedOptionCount())
        var chosenExercises = Core.exerciseController.selectedExerciseOptions
        Core.soundController.prepareFromExerciseOptions(chosenExercises)
        if (exerciseView.currentExercise["playMode"] !== "rhythm") {
            pianoView.noteMark(0, Core.exerciseController.chosenRootNote(), 0, "white")
            pianoView.scrollToNote(Core.exerciseController.chosenRootNote())
            sheetMusicView.model = [Core.exerciseController.chosenRootNote()]
        }
        exerciseView.state = "waitingForAnswer"
        if (internal.isTest)
            internal.currentExercise++
    }

    Flickable {
        id: pageFlickable

        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        clip: contentHeight > height
        contentWidth: width
        contentHeight: mainLayout.height
        interactive: contentHeight > height

        ColumnLayout {
            id: mainLayout

            width: pageFlickable.width
            height: Math.max(pageFlickable.height, implicitHeight)
            spacing: 0

            Item {
                id: contentShell

                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumWidth: exerciseView.maximumContentWidth
                implicitHeight: contentLayout.implicitHeight

                ColumnLayout {
                    id: contentLayout

                    anchors.fill: parent
                    spacing: exerciseView.compactPortrait ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Heading {
                            level: exerciseView.compactPortrait ? 3 : 2
                            Layout.fillWidth: true
                            Layout.maximumHeight: implicitHeight
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: {
                                if (exerciseView.currentExercise === undefined) {
                                    return ""
                                }
                                if (exerciseView.state === "waitingForAnswer") {
                                    return answerInstruction()
                                }
                                return i18nc("technical term, do you have a musician friend?", exerciseView.currentExercise["userMessage"])
                            }
                        }

                        Kirigami.Heading {
                            id: messageText

                            level: 3
                            Layout.fillWidth: true
                            Layout.maximumHeight: implicitHeight
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            color: exerciseView.exercisePlaying ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            text: exerciseView.exercisePlaying ? i18n("Playing...") : internal.statusText
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.preferredHeight: actionButtons.implicitHeight

                        Row {
                            id: actionButtons

                            readonly property real buttonWidth: Math.max(playQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Kirigami.Units.smallSpacing

                            Button {
                                id: playQuestionButton

                                width: actionButtons.buttonWidth
                                text: (exerciseView.state === "waitingForNewQuestion") ? i18n("New Question") : i18n("Play Question")
                                highlighted: exerciseView.state === "waitingForNewQuestion" || exerciseView.state === "waitingForAnswer"
                                enabled: !animation.running && !exerciseView.exercisePlaying

                                onClicked: {
                                    if (exerciseView.state === "waitingForNewQuestion") {
                                        generateNewQuestion()
                                    }
                                    Core.soundController.play()
                                }
                            }

                            Button {
                                id: giveUpButton

                                width: actionButtons.buttonWidth
                                text: i18n("Give Up")
                                enabled: exerciseView.state === "waitingForAnswer" && !animation.running && !exerciseView.exercisePlaying

                                onClicked: {
                                    if (internal.isTest)
                                        internal.correctAnswers--
                                    internal.giveUp = true
                                    var rightAnswers = Core.exerciseController.selectedExerciseOptions
                                    var userAnswers = []
                                    for (var i = 0; i < selectedOptionCount(); ++i) {
                                        userAnswers.push(submittedAnswerFor(rightAnswers[i]))
                                    }
                                    internal.userAnswers = userAnswers
                                    internal.currentAnswer = selectedOptionCount()
                                    checkAnswers()
                                }
                            }

                            Button {
                                id: testButton

                                width: actionButtons.buttonWidth
                                text: internal.isTest ? i18n("Stop Test") : i18n("Start Test")
                                enabled: !exerciseView.exercisePlaying

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
                                        internal.statusText = i18n("Click 'New Question' to start")
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: answerPanel

                        readonly property real maximumGridHeight: Math.max(
                            exerciseView.answerCellHeight * 2,
                            exerciseView.height * (exerciseView.compactPortrait ? 0.34 : 0.44)
                        )

                        Layout.fillWidth: true
                        Layout.preferredHeight: availableAnswersHeading.implicitHeight
                            + Kirigami.Units.smallSpacing
                            + Math.min(answerGridView.contentHeight, answerPanel.maximumGridHeight)
                        Layout.maximumHeight: availableAnswersHeading.implicitHeight
                            + Kirigami.Units.smallSpacing
                            + maximumGridHeight
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            id: availableAnswersHeading

                            Layout.fillWidth: true

                            Kirigami.Heading {
                                Layout.fillWidth: true
                                level: 3
                                text: i18n("Available Answers")
                            }

                            Label {
                                visible: answerGridView.contentHeight > answerGridView.height
                                text: i18n("Scroll for more")
                                color: Kirigami.Theme.disabledTextColor
                            }
                        }

                        GridView {
                            id: answerGridView

                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, answerPanel.maximumGridHeight)
                            Layout.minimumHeight: Math.min(contentHeight, exerciseView.answerCellHeight)
                            boundsBehavior: Flickable.StopAtBounds
                            cellWidth: Math.max(1, width / exerciseView.answerColumnCount)
                            cellHeight: exerciseView.answerCellHeight
                            clip: true
                            model: exerciseView.availableAnswersModel()
                            delegate: answerOption

                            ScrollIndicator.vertical: ScrollIndicator { active: answerGridView.contentHeight > answerGridView.height }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true

                            Kirigami.Heading {
                                Layout.fillWidth: true
                                level: 3
                                text: internal.showingCorrectAnswers ? i18n("Correct Answer(s)") : i18n("Your Answer(s)")
                            }

                            Label {
                                text: i18n("%1 / %2", internal.currentAnswer, selectedOptionCount())
                                color: Kirigami.Theme.disabledTextColor
                            }

                            Button {
                                text: i18n("Backspace")
                                visible: exerciseView.currentExercise !== undefined
                                    && exerciseView.currentExercise["playMode"] === "rhythm"
                                    || canEditUserAnswers()
                                enabled: canEditUserAnswers()
                                onClicked: removeLastUserAnswer()
                            }
                        }

                        Flickable {
                            id: selectedAnswersFlickable

                            Layout.fillWidth: true
                            Layout.preferredHeight: exerciseView.selectedAnswerHeight
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            contentWidth: selectedAnswersRow.width
                            contentHeight: height
                            contentX: Math.max(0, (contentWidth - width) / 2)

                            Row {
                                id: selectedAnswersRow

                                x: Math.max(0, (selectedAnswersFlickable.width - width) / 2)
                                height: selectedAnswersFlickable.height
                                spacing: Kirigami.Units.smallSpacing

                                Repeater {
                                    model: selectedOptionCount()
                                    delegate: selectedAnswerDelegate
                                }
                            }

                            ScrollIndicator.horizontal: ScrollIndicator { active: selectedAnswersFlickable.contentWidth > selectedAnswersFlickable.width }
                        }
                    }

                    ColumnLayout {
                        id: musicPanel

                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? (exerciseView.compactPortrait ? Kirigami.Units.gridUnit * 11 : Math.max(pianoView.implicitHeight, Kirigami.Units.gridUnit * 8)) : 0
                        Layout.maximumHeight: visible ? exerciseView.height * (exerciseView.compactPortrait ? 0.36 : 0.30) : 0
                        visible: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] !== "rhythm"
                        spacing: Kirigami.Units.smallSpacing

                        GridLayout {
                            id: musicViewsLayout

                            readonly property bool tabbed: exerciseView.compactPortrait
                            readonly property real musicViewWidth: tabbed ? width : (width - columnSpacing) / 2

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: tabbed ? 1 : 2
                            columnSpacing: Kirigami.Units.largeSpacing * 2
                            rowSpacing: Kirigami.Units.largeSpacing
                            uniformCellWidths: !tabbed

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: musicViewsLayout.musicViewWidth
                                Layout.minimumHeight: implicitHeight
                                visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 0

                                PianoView {
                                    id: pianoView

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: Math.min(implicitHeight, parent.height)
                                    ScrollIndicator.horizontal: ScrollIndicator { active: true }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: musicViewsLayout.musicViewWidth
                                Layout.minimumHeight: pianoView.implicitHeight
                                visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 1
                                clip: true

                                SheetMusicView {
                                    id: sheetMusicView

                                    anchors.fill: parent
                                }
                            }
                        }

                        TabBar {
                            id: musicTabs

                            Layout.fillWidth: true
                            visible: exerciseView.compactPortrait

                            TabButton {
                                text: i18n("Keyboard")
                            }

                            TabButton {
                                text: i18n("Staff")
                            }
                        }
                    }
                }
            }
        }

        ScrollIndicator.vertical: ScrollIndicator { active: pageFlickable.contentHeight > pageFlickable.height }
    }

    Component {
        id: answerOption

        ItemDelegate {
            id: answerDelegate

            required property int index
            required property var modelData

            property var model: modelData
            property color accentColor: colorForAnswerIndex(index)
            property bool longPressed: false
            property bool dimmedByHighlight: internal.highlightingSingleAnswer && model !== undefined && model.name !== internal.highlightedAnswerName

            width: GridView.view.cellWidth - exerciseView.answerCellSpacing
            height: GridView.view.cellHeight - exerciseView.answerCellSpacing
            opacity: dimmedByHighlight ? 0.25 : enabled ? 1 : 0.45
            hoverEnabled: Qt.platform.os !== "android"
            enabled: exerciseView.state === "waitingForAnswer" && !animation.running

            Accessible.name: model !== undefined && model.name !== undefined ? i18nc("technical term, do you have a musician friend?", model.name) : ""

            background: Rectangle {
                color: answerDelegate.accentColor
                border.color: answerDelegate.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                border.width: answerDelegate.activeFocus ? 2 : 1
                radius: Kirigami.Units.cornerRadius
            }

            contentItem: Text {
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                topPadding: exerciseView.currentExercise["playMode"] === "rhythm" ? Kirigami.Theme.defaultFont.pointSize * 0.7 : 0
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: answerDelegate.model !== undefined && answerDelegate.model.name !== undefined ? i18nc("technical term, do you have a musician friend?", answerDelegate.model.name) : ""
                color: "#202124"
                font.family: exerciseView.currentExercise["playMode"] !== "rhythm" ? Kirigami.Theme.defaultFont.family : bravura.name
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.4 * (exerciseView.currentExercise["playMode"] !== "rhythm" ? 1.0 : 2.0))
            }

            onHoveredChanged: {
                if (hovered && exerciseView.currentExercise["playMode"] !== "rhythm") {
                    showAvailableAnswerPreview(answerDelegate)
                } else {
                    restoreAvailableAnswerPreview(answerDelegate)
                }
            }

            onActiveFocusChanged: {
                if (activeFocus && exerciseView.currentExercise["playMode"] !== "rhythm") {
                    showAvailableAnswerPreview(answerDelegate)
                } else {
                    restoreAvailableAnswerPreview(answerDelegate)
                }
            }

            onPressAndHold: {
                if (exerciseView.currentExercise["playMode"] !== "rhythm") {
                    longPressed = true
                    showAvailableAnswerPreview(answerDelegate)
                }
            }

            onReleased: {
                if (longPressed) {
                    restoreAvailableAnswerPreview(answerDelegate)
                }
            }

            onClicked: {
                if (longPressed) {
                    longPressed = false
                    return
                }
                chooseAnswer(answerDelegate.model, answerDelegate.index)
            }
        }
    }

    Component {
        id: selectedAnswerDelegate

        ItemDelegate {
            id: selectedDelegate

            required property int index

            property var submittedAnswer: index < internal.userAnswers.length ? internal.userAnswers[index] : undefined
            property bool filled: submittedAnswer !== undefined
            property bool submitted: internal.currentAnswer >= selectedOptionCount()
            property bool wrongAnswer: filled && submitted && isWrongSubmittedAnswer(index)
            property bool correctAnswer: filled && submitted && !wrongAnswer
            property bool showingCorrection: internal.correctedAnswerPosition === index
            property var displayedAnswer: showingCorrection ? correctAnswerAt(index) : submittedAnswer
            property color accentColor: {
                if (!filled) {
                    return Kirigami.Theme.backgroundColor
                }
                if (showingCorrection) {
                    const correctAnswer = correctAnswerAt(index)
                    return correctAnswer !== undefined ? colorForAnswer(correctAnswer) : Kirigami.Theme.backgroundColor
                }
                return submittedAnswer.color !== undefined ? submittedAnswer.color : Kirigami.Theme.backgroundColor
            }

            width: Math.max(Kirigami.Units.gridUnit * 8, answerGridView.cellWidth - exerciseView.answerCellSpacing)
            height: selectedAnswersFlickable.height
            hoverEnabled: true
            enabled: filled

            Accessible.name: filled
                ? (displayedAnswer !== undefined && displayedAnswer.name !== undefined ? i18nc("technical term, do you have a musician friend?", displayedAnswer.name) : "")
                : i18n("Empty answer slot")

            background: Rectangle {
                color: selectedDelegate.filled ? selectedDelegate.accentColor : Kirigami.Theme.alternateBackgroundColor
                border.color: selectedDelegate.wrongAnswer
                    ? Kirigami.Theme.negativeTextColor
                    : selectedDelegate.correctAnswer
                        ? Kirigami.Theme.positiveTextColor
                        : selectedDelegate.activeFocus
                            ? Kirigami.Theme.highlightColor
                            : Kirigami.Theme.textColor
                border.width: selectedDelegate.activeFocus || selectedDelegate.wrongAnswer || selectedDelegate.correctAnswer ? 2 : 1
                radius: Kirigami.Units.cornerRadius
            }

            contentItem: ColumnLayout {
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: selectedDelegate.filled && selectedDelegate.displayedAnswer !== undefined && selectedDelegate.displayedAnswer.name !== undefined
                        ? i18nc("technical term, do you have a musician friend?", selectedDelegate.displayedAnswer.name)
                        : i18n("Answer %1", selectedDelegate.index + 1)
                    color: selectedDelegate.filled ? "#202124" : Kirigami.Theme.disabledTextColor
                    topPadding: selectedDelegate.filled && exerciseView.currentExercise["playMode"] === "rhythm" ? Kirigami.Theme.defaultFont.pointSize * 0.6 : 0
                    font.family: selectedDelegate.filled && exerciseView.currentExercise["playMode"] === "rhythm" ? bravura.name : Kirigami.Theme.defaultFont.family
                    font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.4 * (selectedDelegate.filled && exerciseView.currentExercise["playMode"] === "rhythm" ? 1.7 : 1.0))
                }
            }

            onClicked: {
                if (canShowSubmittedAnswerCorrection(index)) {
                    toggleSubmittedAnswerCorrection(index)
                }
            }
        }
    }

    Shortcut {
        sequence: "Backspace"
        enabled: canEditUserAnswers()
        onActivated: removeLastUserAnswer()
    }

    states: [
        State {
            name: "waitingForNewQuestion"
        },
        State {
            name: "waitingForAnswer"
            StateChangeScript {
                script: {
                    internal.highlightingSingleAnswer = false
                    internal.highlightedAnswerName = ""
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
            finishSingleAnswerFeedback()
        }
    }

    Connections {
        target: Core.exerciseController
        function onSelectedExerciseOptionsChanged(): void { pianoView.clearAllMarks() }
    }

    Connections {
        target: Core.exerciseController
        function onSelectedExerciseOptionsChanged(): void { sheetMusicView.clearAllMarks() }
    }

    Connections {
        target: Core.soundController
        function onCountInChanged(count: int): void {
            internal.countIn = count
        }
    }
}
