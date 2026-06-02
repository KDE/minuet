// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

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
    readonly property bool musicViewsTabbed: !applicationWindow().wideScreen
        && exerciseView.height > exerciseView.width
    readonly property real answerCellSpacing: Kirigami.Units.smallSpacing
    readonly property real answerCellHeight: Math.max(Kirigami.Units.gridUnit * 3.0, Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 2)
    readonly property real answerCardWidth: Math.max(1, answerGridView.cellWidth - answerCellSpacing)
    readonly property real answerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.2)
    readonly property real rhythmAnswerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.0)
    readonly property real rhythmAnswerCardVerticalOffset: Math.round(rhythmAnswerCardTextSize * 0.22)
    readonly property real answerCardHorizontalPadding: Kirigami.Units.largeSpacing
    readonly property real minimumAnswerCardWidth: Kirigami.Units.gridUnit * 10
    readonly property real selectedAnswerHeight: answerCellHeight
    readonly property real sectionPadding: Kirigami.Units.smallSpacing
    readonly property int answerColumnCount: {
        const availableWidth = Math.max(1, answerGridView.width)
        const fittedColumns = Math.max(1, Math.floor((availableWidth + answerCellSpacing) / (minimumAnswerCardWidth + answerCellSpacing)))
        const availableAnswerCount = Math.max(1, availableAnswers.length)
        return Math.max(1, Math.min(5, fittedColumns, availableAnswerCount))
    }
    readonly property var availableAnswers: Core.exerciseSessionController.availableAnswersModel(exerciseView.currentExercise || {})
    readonly property int selectedOptionCount: Core.exerciseSessionController.selectedOptionCount(exerciseView.currentExercise || {}, Core.settingsController.rhythmPatternCount)
    readonly property int maximumExercises: Core.settingsController.testExerciseCount
    readonly property bool canShowPitchPreview: exerciseView.currentExercise !== undefined
        && exerciseView.currentExercise["playMode"] !== "rhythm"
        && exerciseView.state === "waitingForAnswer"
    readonly property bool canEditUserAnswers: Core.exerciseSessionController.canEditUserAnswers(
        exerciseView.state,
        exerciseView.selectedOptionCount,
        animation.running
    )

    FontLoader { id: bravura; source: "SheetMusicView/Bravura.otf" }

    QtObject {
        id: internal

        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        property Item rightAnswerRectangle
        property int countIn: 0
        property Item hoveredAvailableAnswer
    }

    onCurrentExerciseChanged: {
        internal.countIn = 0
        pianoView.clearAllMarks()
        sheetMusicView.clearAllMarks()
        internal.hoveredAvailableAnswer = null
        if (exerciseView.currentExercise !== undefined) {
            Core.exerciseSessionController.resetForExercise()
            sheetMusicView.spaced = exerciseView.currentExercise["playMode"] !== "chord"
            exerciseView.state = "waitingForNewQuestion"
        } else {
            Core.exerciseSessionController.clearUserAnswers()
        }
    }

    function colorForAnswerIndex(index: int): color {
        return Core.exerciseSessionController.colorForAnswerIndex(index, internal.colors)
    }

    function colorForAnswer(answer: var): color {
        return Core.exerciseSessionController.colorForAnswer(answer || {}, exerciseView.availableAnswers, internal.colors)
    }

    function showAnswers(answers: var): void {
        const presentation = Core.exerciseSessionController.answerPresentation(
            answers,
            Core.exerciseSessionController.chosenRootNote,
            exerciseView.currentExercise || {},
            exerciseView.availableAnswers,
            internal.colors
        )
        if (presentation.isRhythm) {
            return
        }

        pianoView.clearAllMarks()
        for (const mark of presentation.pianoMarks) {
            pianoView.noteMark(0, mark.pitch, 0, mark.color)
        }
        pianoView.scrollToMarkedKeys()
        sheetMusicView.model = presentation.sheetMusicModel
    }

    function showUserAnswers(): void {
        showAnswers(Core.exerciseSessionController.userAnswers)
    }

    function showCorrectAnswers(): void {
        showAnswers(Core.exerciseSessionController.selectedExerciseOptions)
    }

    function canShowSubmittedAnswerCorrection(position: int): bool {
        return Core.exerciseSessionController.canShowSubmittedAnswerCorrection(
            position,
            exerciseView.currentExercise || {},
            exerciseView.selectedOptionCount,
            Core.exerciseSessionController.selectedExerciseOptions
        )
    }

    function showAvailableAnswerPreview(answerRectangle: Item): void {
        if (!exerciseView.canShowPitchPreview) {
            return
        }

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
        if (exerciseView.canShowPitchPreview) {
            showAnswers([])
        }
    }

    function showSubmittedAnswerCorrection(position: int): void {
        if (!canShowSubmittedAnswerCorrection(position)) {
            return
        }

        Core.exerciseSessionController.showSubmittedAnswerCorrection(position)
        showCorrectAnswers()
    }

    function restoreSubmittedAnswerCorrection(position: int): void {
        if (!canShowSubmittedAnswerCorrection(position)) {
            return
        }

        Core.exerciseSessionController.restoreSubmittedAnswerCorrection()
        showUserAnswers()
    }

    function toggleSubmittedAnswerCorrection(position: int): void {
        if (Core.exerciseSessionController.correctedAnswerPosition === position) {
            restoreSubmittedAnswerCorrection(position)
        } else {
            showSubmittedAnswerCorrection(position)
        }
    }

    function chooseAnswer(answer: var, index: int): void {
        if (exerciseView.state !== "waitingForAnswer" || animation.running || Core.exerciseSessionController.currentAnswer >= exerciseView.selectedOptionCount) {
            return
        }

        if (Core.exerciseSessionController.chooseAnswer(answer, index, exerciseView.selectedOptionCount, internal.colors)) {
            checkAnswers()
        }
    }

    function removeLastUserAnswer(): void {
        if (exerciseView.canEditUserAnswers && Core.exerciseSessionController.removeLastUserAnswer()) {
            showUserAnswers()
        }
    }

    function checkAnswers(): void {
        var rightAnswers = Core.exerciseSessionController.selectedExerciseOptions
        internal.hoveredAvailableAnswer = null
        var expectedAnswers = exerciseView.selectedOptionCount
        Core.exerciseSessionController.checkAnswers(rightAnswers, expectedAnswers, exerciseView.maximumExercises)

        showUserAnswers()
        if (exerciseView.selectedOptionCount === 1)
            highlightRightAnswer()
        else
            exerciseView.state = "waitingForNewQuestion"
    }

    function highlightRightAnswer(): void {
        var chosenExercises = Core.exerciseSessionController.selectedExerciseOptions
        var rightAnswerIndex = Core.exerciseSessionController.answerIndexForName(exerciseView.availableAnswers, chosenExercises[0].name)
        internal.rightAnswerRectangle = null
        Core.exerciseSessionController.setSingleAnswerHighlight(chosenExercises[0].name)
        if (rightAnswerIndex >= 0 && !Core.exerciseSessionController.answersAreRight) {
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

    function finishSingleAnswerFeedback(): void {
        exerciseView.state = Core.exerciseSessionController.isTest ? "waitingForAnswer" : "waitingForNewQuestion"
        if (Core.exerciseSessionController.isTest) {
            nextTestExercise()
            if (Core.exerciseSessionController.currentExercise === exerciseView.maximumExercises + 1)
                Core.exerciseSessionController.resetTest()
        }
    }

    function nextTestExercise(): void {
        for (var i = 0; i < answerGridView.count; ++i) {
            const answerItem = answerGridView.itemAtIndex(i)
            if (answerItem !== null) {
                answerItem.opacity = 1
            }
        }
        generateNewQuestion()
        Core.soundController.play()
    }

    function generateNewQuestion(): void {
        pianoView.clearAllMarks()
        sheetMusicView.clearAllMarks()
        internal.hoveredAvailableAnswer = null
        Core.exerciseSessionController.beginQuestion(exerciseView.maximumExercises)
        Core.exerciseSessionController.randomlySelectExerciseOptions(exerciseView.selectedOptionCount)
        var chosenExercises = Core.exerciseSessionController.selectedExerciseOptions
        Core.soundController.prepareFromExerciseOptions(chosenExercises)
        if (exerciseView.currentExercise["playMode"] !== "rhythm") {
            pianoView.noteMark(0, Core.exerciseSessionController.chosenRootNote, 0, "white")
            pianoView.scrollToMarkedKeys()
            sheetMusicView.model = [Core.exerciseSessionController.chosenRootNote]
        }
        exerciseView.state = "waitingForAnswer"
        Core.exerciseSessionController.finishQuestionGeneration()
    }

    Item {
        id: contentShell

        anchors.fill: parent

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Kirigami.Heading {
                    level: exerciseView.musicViewsTabbed ? 3 : 2
                    Layout.fillWidth: true
                    Layout.maximumHeight: implicitHeight
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: {
                        if (exerciseView.currentExercise === undefined) {
                            return ""
                        }
                        if (exerciseView.state === "waitingForAnswer") {
                            return Core.exerciseSessionController.answerInstruction(exerciseView.selectedOptionCount)
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
                    elide: Text.ElideRight
                    color: exerciseView.exercisePlaying ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    text: exerciseView.exercisePlaying ? i18n("Playing…") : Core.exerciseSessionController.statusText
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
                            var rightAnswers = Core.exerciseSessionController.selectedExerciseOptions
                            Core.exerciseSessionController.giveUpWithCorrectAnswers(rightAnswers, exerciseView.availableAnswers, internal.colors, exerciseView.selectedOptionCount)
                            checkAnswers()
                        }
                    }

                    Button {
                        id: testButton

                        width: actionButtons.buttonWidth
                        text: Core.exerciseSessionController.isTest ? i18n("Stop Test") : i18n("Start Test")
                        enabled: !exerciseView.exercisePlaying

                        onClicked: {
                            if (!Core.exerciseSessionController.isTest) {
                                Core.exerciseSessionController.startTest()
                                generateNewQuestion()
                                if (Core.exerciseSessionController.isTest)
                                    Core.soundController.play()
                            } else {
                                Core.exerciseSessionController.stopTest()
                                exerciseView.state = "waitingForNewQuestion"
                            }
                        }
                    }
                }
            }

            Item {
                id: answerFrame

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: availableAnswersHeading.implicitHeight + Kirigami.Units.smallSpacing + exerciseView.answerCellHeight + exerciseView.sectionPadding * 2

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        id: availableAnswersHeading

                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.largeSpacing

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 3
                            text: i18n("Available answers")
                        }

                        Label {
                            visible: answerGridView.contentHeight > answerGridView.height
                            text: i18n("Scroll for more")
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }

                    Frame {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: exerciseView.answerCellHeight + exerciseView.sectionPadding * 2
                        padding: 0

                        GridView {
                            id: answerGridView

                            anchors.fill: parent
                            anchors.margins: exerciseView.answerCellSpacing
                            boundsBehavior: Flickable.StopAtBounds
                            flow: GridView.FlowLeftToRight
                            layoutDirection: Qt.LeftToRight
                            cellWidth: Math.max(1, width / exerciseView.answerColumnCount)
                            cellHeight: exerciseView.answerCellHeight + exerciseView.answerCellSpacing
                            clip: true
                            model: exerciseView.availableAnswers
                            delegate: answerOption

                            ScrollIndicator.vertical: ScrollIndicator { active: answerGridView.contentHeight > answerGridView.height }
                        }
                    }
                }
            }

            Item {
                id: selectedAnswersFrame

                Layout.fillWidth: true
                Layout.preferredHeight: selectedAnswersHeading.implicitHeight + Kirigami.Units.smallSpacing + exerciseView.selectedAnswerHeight + exerciseView.sectionPadding * 2

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        id: selectedAnswersHeading

                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.largeSpacing

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 3
                            text: Core.exerciseSessionController.showingCorrectAnswers
                                ? i18np("Correct answer", "Correct answers", exerciseView.selectedOptionCount)
                                : i18np("Your answer", "Your answers", exerciseView.selectedOptionCount)
                        }

                        Label {
                            visible: selectedAnswersFlickable.canScrollHorizontally
                            text: i18n("Scroll for more |")
                            color: Kirigami.Theme.disabledTextColor
                        }

                        Label {
                            text: i18n("%1 / %2", Core.exerciseSessionController.currentAnswer, exerciseView.selectedOptionCount)
                            color: Kirigami.Theme.disabledTextColor
                        }

                        Button {
                            text: i18n("Backspace")
                            visible: exerciseView.currentExercise !== undefined
                                && (exerciseView.currentExercise["playMode"] === "rhythm" || exerciseView.canEditUserAnswers)
                            enabled: exerciseView.canEditUserAnswers
                            onClicked: removeLastUserAnswer()
                        }
                    }

                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: exerciseView.selectedAnswerHeight + exerciseView.sectionPadding * 2
                        padding: 0

                        Flickable {
                            id: selectedAnswersFlickable

                            readonly property bool canScrollHorizontally: contentWidth > width

                            anchors.fill: parent
                            anchors.margins: exerciseView.sectionPadding
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
                                    model: exerciseView.selectedOptionCount
                                    delegate: selectedAnswerDelegate
                                }
                            }

                            ScrollIndicator.horizontal: ScrollIndicator {
                                id: selectedAnswersScrollIndicator

                                active: selectedAnswersFlickable.canScrollHorizontally
                                visible: selectedAnswersFlickable.canScrollHorizontally

                                contentItem: Rectangle {
                                    implicitWidth: 2
                                    implicitHeight: 2
                                    color: selectedAnswersScrollIndicator.palette.mid
                                    opacity: 0.75
                                    visible: selectedAnswersScrollIndicator.visible && selectedAnswersScrollIndicator.size < 1.0
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: musicPanel

                readonly property real viewHeight: Math.max(sheetMusicView.implicitHeight, pianoView.implicitHeight)

                Layout.fillWidth: true
                Layout.preferredHeight: visible ? viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0) : 0
                Layout.maximumHeight: visible ? viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0) : 0
                visible: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] !== "rhythm"
                spacing: Kirigami.Units.smallSpacing

                GridLayout {
                    id: musicViewsLayout

                    readonly property bool tabbed: exerciseView.musicViewsTabbed
                    readonly property real musicViewWidth: tabbed ? width : (width - columnSpacing) / 2

                    Layout.fillWidth: true
                    Layout.preferredHeight: musicPanel.viewHeight
                    columns: tabbed ? 1 : 2
                    columnSpacing: Kirigami.Units.largeSpacing * 2
                    rowSpacing: Kirigami.Units.largeSpacing
                    uniformCellWidths: !tabbed

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: musicPanel.viewHeight
                        Layout.preferredWidth: musicViewsLayout.musicViewWidth
                        visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 0

                        PianoView {
                            id: pianoView

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: Math.min(sheetMusicView.staffGroupHeight, parent.height)
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: musicPanel.viewHeight
                        Layout.preferredWidth: musicViewsLayout.musicViewWidth
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
                    visible: exerciseView.musicViewsTabbed
                    position: TabBar.Footer

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

    Component {
        id: answerOption

        ItemDelegate {
            id: answerDelegate

            required property int index
            required property var modelData

            property var model: modelData
            property color accentColor: colorForAnswerIndex(index)
            property bool longPressed: false
            property bool dimmedByHighlight: Core.exerciseSessionController.highlightingSingleAnswer && model !== undefined && model.name !== Core.exerciseSessionController.highlightedAnswerName

            width: GridView.view.cellWidth - (index % exerciseView.answerColumnCount === exerciseView.answerColumnCount - 1 ? 0 : exerciseView.answerCellSpacing)
            height: GridView.view.cellHeight - exerciseView.answerCellSpacing
            opacity: dimmedByHighlight ? 0.25 : enabled ? 1 : 0.45
            hoverEnabled: !Kirigami.Settings.isMobile
            enabled: exerciseView.state === "waitingForAnswer" && !animation.running
            padding: 0
            leftInset: 0
            rightInset: 0
            topInset: 0
            bottomInset: 0

            Accessible.name: model !== undefined && model.name !== undefined ? i18nc("technical term, do you have a musician friend?", model.name) : ""

            background: Rectangle {
                color: answerDelegate.accentColor
                border.color: answerDelegate.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                border.width: answerDelegate.activeFocus ? 2 : 1
                radius: Kirigami.Units.cornerRadius
            }

            contentItem: Item {
                anchors.fill: parent

                Text {
                    readonly property bool rhythmCard: exerciseView.currentExercise["playMode"] === "rhythm"

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(1, parent.width - exerciseView.answerCardHorizontalPadding * 2)
                    height: implicitHeight
                    y: Math.round((parent.height - height) / 2 + (rhythmCard ? exerciseView.rhythmAnswerCardVerticalOffset : 0))
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: answerDelegate.model !== undefined && answerDelegate.model.name !== undefined ? i18nc("technical term, do you have a musician friend?", answerDelegate.model.name) : ""
                    color: "#202124"
                    font.family: rhythmCard ? bravura.name : Kirigami.Theme.defaultFont.family
                    font.pixelSize: rhythmCard ? exerciseView.rhythmAnswerCardTextSize : exerciseView.answerCardTextSize
                }
            }

            onHoveredChanged: {
                if (hovered && exerciseView.canShowPitchPreview) {
                    showAvailableAnswerPreview(answerDelegate)
                } else {
                    restoreAvailableAnswerPreview(answerDelegate)
                }
            }

            onActiveFocusChanged: {
                if (activeFocus && exerciseView.canShowPitchPreview) {
                    showAvailableAnswerPreview(answerDelegate)
                } else {
                    restoreAvailableAnswerPreview(answerDelegate)
                }
            }

            onPressAndHold: {
                if (exerciseView.canShowPitchPreview) {
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

            property var submittedAnswer: index < Core.exerciseSessionController.userAnswers.length ? Core.exerciseSessionController.userAnswers[index] : undefined
            property var expectedAnswer: Core.exerciseSessionController.selectedExerciseOptions[index]
            property bool filled: submittedAnswer !== undefined
            property bool submitted: Core.exerciseSessionController.currentAnswer >= exerciseView.selectedOptionCount
            property bool wrongAnswer: filled
                && submitted
                && expectedAnswer !== undefined
                && submittedAnswer.name !== expectedAnswer.name
            property bool correctAnswer: filled && submitted && !wrongAnswer
            property bool showingCorrection: Core.exerciseSessionController.correctedAnswerPosition === index
            property var displayedAnswer: showingCorrection ? expectedAnswer : submittedAnswer
            property color accentColor: {
                if (!filled) {
                    return Kirigami.Theme.backgroundColor
                }
                if (showingCorrection) {
                    return expectedAnswer !== undefined ? colorForAnswer(expectedAnswer) : Kirigami.Theme.backgroundColor
                }
                return submittedAnswer.color !== undefined ? submittedAnswer.color : Kirigami.Theme.backgroundColor
            }

            width: exerciseView.answerCardWidth
            height: selectedAnswersFlickable.height
            hoverEnabled: true
            enabled: filled
            padding: 0
            leftInset: 0
            rightInset: 0
            topInset: 0
            bottomInset: 0

            Accessible.name: filled
                ? (displayedAnswer !== undefined && displayedAnswer.name !== undefined ? i18nc("technical term, do you have a musician friend?", displayedAnswer.name) : "")
                : i18n("Empty answer slot")

            background: Rectangle {
                color: selectedDelegate.filled ? selectedDelegate.accentColor : Kirigami.Theme.alternateBackgroundColor
                border.color: selectedDelegate.showingCorrection
                    ? Kirigami.Theme.positiveTextColor
                    : selectedDelegate.wrongAnswer
                        ? Kirigami.Theme.negativeTextColor
                        : selectedDelegate.correctAnswer
                        ? Kirigami.Theme.positiveTextColor
                        : selectedDelegate.activeFocus
                            ? Kirigami.Theme.highlightColor
                            : Kirigami.Theme.textColor
                border.width: selectedDelegate.activeFocus || selectedDelegate.wrongAnswer || selectedDelegate.correctAnswer || selectedDelegate.showingCorrection ? 2 : 1
                radius: Kirigami.Units.cornerRadius
            }

            contentItem: Item {
                anchors.fill: parent

                Text {
                    readonly property bool rhythmCard: selectedDelegate.filled && exerciseView.currentExercise["playMode"] === "rhythm"

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(1, parent.width - exerciseView.answerCardHorizontalPadding * 2)
                    height: implicitHeight
                    y: Math.round((parent.height - height) / 2 + (rhythmCard ? exerciseView.rhythmAnswerCardVerticalOffset : 0))
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: selectedDelegate.filled && selectedDelegate.displayedAnswer !== undefined && selectedDelegate.displayedAnswer.name !== undefined
                        ? i18nc("technical term, do you have a musician friend?", selectedDelegate.displayedAnswer.name)
                        : i18n("Answer %1", selectedDelegate.index + 1)
                    color: selectedDelegate.filled ? "#202124" : Kirigami.Theme.disabledTextColor
                    font.family: rhythmCard ? bravura.name : Kirigami.Theme.defaultFont.family
                    font.pixelSize: rhythmCard ? exerciseView.rhythmAnswerCardTextSize : exerciseView.answerCardTextSize
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
        enabled: exerciseView.canEditUserAnswers
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
                    Core.exerciseSessionController.clearSingleAnswerHighlight()
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
        target: Core.exerciseSessionController
        function onSelectedExerciseOptionsChanged(): void { pianoView.clearAllMarks() }
    }

    Connections {
        target: Core.exerciseSessionController
        function onSelectedExerciseOptionsChanged(): void { sheetMusicView.clearAllMarks() }
    }

    Connections {
        target: Core.soundController
        function onCountInChanged(count: int): void {
            internal.countIn = count
        }
    }
}
