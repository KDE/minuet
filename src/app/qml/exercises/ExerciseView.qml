// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.onboarding

ExerciseContent {
    id: exerciseView

    function canShowSubmittedAnswerCorrection(position: int): bool {
        return Core.exerciseSessionController.canShowSubmittedAnswerCorrection(position, exerciseView.currentExercise || {}, internal.selectedOptionCount, Core.exerciseSessionController.selectedExerciseOptions);
    }
    function checkAnswers(): void {
        var rightAnswers = Core.exerciseSessionController.selectedExerciseOptions;
        internal.hoveredAvailableAnswer = null;
        var expectedAnswers = internal.selectedOptionCount;
        Core.exerciseSessionController.checkAnswers(rightAnswers, expectedAnswers, internal.maximumExercises);

        showUserAnswers();
        if (internal.selectedOptionCount === 1) {
            highlightRightAnswer();
        } else {
            exerciseView.state = "waitingForNewQuestion";
            if (Core.exerciseSessionController.isTest) {
                testFeedbackTimer.restart();
            }
        }
    }
    function chooseAnswer(answer: var, index: int): void {
        if (exerciseView.state !== "waitingForAnswer" || animation.running || Core.exerciseSessionController.currentAnswer >= internal.selectedOptionCount) {
            return;
        }

        if (Core.exerciseSessionController.chooseAnswer(answer, index, internal.selectedOptionCount, internal.colors)) {
            checkAnswers();
        }
    }
    function clearCurrentRun(): void {
        testFeedbackTimer.stop();
        internal.stoppingActivity = true;
        exerciseView.stopRhythmPlaybackCount();
        if (animation.running) {
            animation.stop();
        }
        if (internal.rightAnswerRectangle !== null) {
            internal.rightAnswerRectangle.scale = 1;
        }
        internal.countIn = 0;
        internal.hoveredAvailableAnswer = null;
        internal.rightAnswerRectangle = null;
        exerciseView.state = "waitingForNewQuestion";
        if (Core.soundController !== null) {
            Core.soundController.stop();
        }
        internal.stoppingActivity = false;
    }
    function colorForAnswer(answer: var): color {
        return Core.exerciseSessionController.colorForAnswer(answer || {}, internal.availableAnswers, internal.colors);
    }
    function colorForAnswerIndex(index: int): color {
        return Core.exerciseSessionController.colorForAnswerIndex(index, internal.colors);
    }
    function finishSingleAnswerFeedback(): void {
        exerciseView.state = Core.exerciseSessionController.isTest ? "waitingForAnswer" : "waitingForNewQuestion";
        if (Core.exerciseSessionController.isTest) {
            nextTestExercise();
            if (Core.exerciseSessionController.currentExercise === internal.maximumExercises + 1)
                Core.exerciseSessionController.resetTest();
        }
    }
    function generateNewQuestion(): void {
        pianoView.clearAllMarks();
        sheetMusicView.clearAllMarks();
        internal.hoveredAvailableAnswer = null;
        Core.exerciseSessionController.beginQuestion(internal.maximumExercises);
        Core.exerciseSessionController.randomlySelectExerciseOptions(internal.selectedOptionCount);
        var chosenExercises = Core.exerciseSessionController.selectedExerciseOptions;
        Core.soundController.prepareFromExerciseOptions(chosenExercises);
        if (exerciseView.currentExercise["playMode"] !== "rhythm") {
            pianoView.noteMark(0, Core.exerciseSessionController.chosenRootNote, 0, "white");
            pianoView.scrollToMarkedKeys();
            sheetMusicView.model = [Core.exerciseSessionController.chosenRootNote];
        }
        exerciseView.state = "waitingForAnswer";
        Core.exerciseSessionController.finishQuestionGeneration();
    }
    function highlightRightAnswer(): void {
        var chosenExercises = Core.exerciseSessionController.selectedExerciseOptions;
        var rightAnswerIndex = Core.exerciseSessionController.answerIndexForName(internal.availableAnswers, chosenExercises[0].name);
        internal.rightAnswerRectangle = null;
        Core.exerciseSessionController.setSingleAnswerHighlight(chosenExercises[0].name);
        if (rightAnswerIndex >= 0 && !Core.exerciseSessionController.answersAreRight) {
            answerGridView.positionViewAtIndex(rightAnswerIndex, GridView.Contain);
        }
        for (var i = 0; i < answerGridView.count; ++i) {
            const answerItem = answerGridView.itemAtIndex(i);
            if (answerItem === null) {
                continue;
            }
            if (answerItem.model.name === chosenExercises[0].name) {
                internal.rightAnswerRectangle = answerItem;
                break;
            }
        }
        if (internal.rightAnswerRectangle !== null) {
            animation.start();
        } else {
            finishSingleAnswerFeedback();
        }
    }
    function nextTestExercise(): void {
        for (var i = 0; i < answerGridView.count; ++i) {
            const answerItem = answerGridView.itemAtIndex(i);
            if (answerItem !== null) {
                answerItem.opacity = 1;
            }
        }
        generateNewQuestion();
        Core.soundController.play();
    }
    function removeLastUserAnswer(): void {
        if (internal.canEditUserAnswers && Core.exerciseSessionController.removeLastUserAnswer()) {
            showUserAnswers();
        }
    }
    function restoreAvailableAnswerPreview(answerRectangle: Item): void {
        if (internal.hoveredAvailableAnswer !== answerRectangle) {
            return;
        }

        internal.hoveredAvailableAnswer = null;
        if (internal.canShowPitchPreview) {
            showAnswers([]);
        }
    }
    function restoreSubmittedAnswerCorrection(position: int): void {
        if (!canShowSubmittedAnswerCorrection(position)) {
            return;
        }

        Core.exerciseSessionController.restoreSubmittedAnswerCorrection();
        showUserAnswers();
    }
    function showAnswers(answers: var): void {
        const presentation = Core.exerciseSessionController.answerPresentation(answers, Core.exerciseSessionController.chosenRootNote, exerciseView.currentExercise || {}, internal.availableAnswers, internal.colors);
        if (presentation.isRhythm) {
            return;
        }

        pianoView.clearAllMarks();
        for (const mark of presentation.pianoMarks) {
            pianoView.noteMark(0, mark.pitch, 0, mark.color);
        }
        pianoView.scrollToMarkedKeys();
        sheetMusicView.model = presentation.sheetMusicModel;
    }
    function showAvailableAnswerPreview(answerRectangle: Item): void {
        if (!internal.canShowPitchPreview) {
            return;
        }

        internal.hoveredAvailableAnswer = answerRectangle;
        showAnswers([
            {
                "model": answerRectangle.model,
                "color": colorForAnswerIndex(answerRectangle.index)
            }
        ]);
    }
    function showCorrectAnswers(): void {
        showAnswers(Core.exerciseSessionController.selectedExerciseOptions);
    }
    function showSubmittedAnswerCorrection(position: int): void {
        if (!canShowSubmittedAnswerCorrection(position)) {
            return;
        }

        Core.exerciseSessionController.showSubmittedAnswerCorrection(position);
        showCorrectAnswers();
    }
    function showUserAnswers(): void {
        showAnswers(Core.exerciseSessionController.userAnswers);
    }
    function startRhythmPlaybackCount(): void {
        if (!internal.rhythmicExercise || internal.selectedOptionCount <= 0) {
            return;
        }
        internal.rhythmPlaybackCounting = true;
        internal.rhythmPlaybackSubdivision = 0;
        internal.countIn = 1;
        rhythmPlaybackCountTimer.restart();
    }
    function stopExerciseActivity(): void {
        clearCurrentRun();
        exerciseView.currentExercise = undefined;
    }
    function stopRhythmPlaybackCount(): void {
        rhythmPlaybackCountTimer.stop();
        internal.rhythmPlaybackCounting = false;
        internal.rhythmPlaybackSubdivision = 0;
        internal.countIn = 0;
    }
    function toggleSubmittedAnswerCorrection(position: int): void {
        if (Core.exerciseSessionController.correctedAnswerPosition === position) {
            restoreSubmittedAnswerCorrection(position);
        } else {
            showSubmittedAnswerCorrection(position);
        }
    }

    countIn: internal.countIn
    countInOverlayInitial: internal.rhythmicExercise && (onboardingCountIn > 0 || (!internal.rhythmPlaybackCounting && internal.countIn > 0))
    countInOverlaySize: Math.ceil(countInMeterProbe.implicitWidth)
    countInOverlayX: {
        const margin = Kirigami.Units.smallSpacing;
        const cardGroupCenter = answerGridView.mapToItem(exerciseView, answerGridView.width / 2, 0).x;
        return Math.max(margin, Math.min(width - countInOverlaySize - margin, cardGroupCenter - countInOverlaySize / 2));
    }
    countInOverlayY: {
        const margin = Kirigami.Units.smallSpacing;
        const cardGroupTop = answerGridView.mapToItem(exerciseView, 0, answerGridView.topMargin).y;
        return Math.max(margin, Math.min(height - countInOverlaySize - margin, cardGroupTop - countInOverlaySize / 2));
    }
    visible: exerciseView.currentExercise !== undefined

    states: [
        State {
            name: "waitingForNewQuestion"
        },
        State {
            name: "waitingForAnswer"

            StateChangeScript {
                script: {
                    Core.exerciseSessionController.clearSingleAnswerHighlight();
                }
            }
        }
    ]

    Onboarding.onAboutToStart: {
        if (!internal.onboardingMusicTabCaptured) {
            internal.onboardingInitialMusicTabIndex = musicTabs.currentIndex;
            internal.onboardingMusicTabCaptured = true;
        }
    }
    Onboarding.onFinished: {
        if (internal.onboardingMusicTabCaptured && internal.onboardingInitialMusicTabIndex >= 0) {
            musicTabs.currentIndex = internal.onboardingInitialMusicTabIndex;
        }
        internal.onboardingInitialMusicTabIndex = -1;
        internal.onboardingMusicTabCaptured = false;
    }
    onCurrentExerciseChanged: {
        clearCurrentRun();
        pianoView.clearAllMarks();
        sheetMusicView.clearAllMarks();
        if (exerciseView.currentExercise !== undefined) {
            Core.exerciseSessionController.resetForExercise();
            sheetMusicView.spaced = exerciseView.currentExercise["playMode"] !== "chord";
            exerciseView.state = "waitingForNewQuestion";
        } else {
            Core.exerciseSessionController.clearUserAnswers();
        }
    }

    FontLoader {
        id: bravura

        source: "../sheetmusicview/Bravura.otf"
    }
    GraphicalMeter {
        id: countInMeterProbe

        meterKind: "onset"
        visible: false
    }
    QtObject {
        id: internal

        readonly property real answerCardHorizontalPadding: Kirigami.Units.largeSpacing
        readonly property real answerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.2)
        readonly property real answerCardsHeight: Math.ceil(internal.availableAnswers.length / internal.answerColumnCount) * answerGridView.cellHeight
        readonly property bool answerCardsOverflowing: internal.answerCardsHeight > answerGridView.height
        readonly property real answerCellHeight: Math.max(Kirigami.Units.gridUnit * 3.0, Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 2)
        readonly property real answerCellSpacing: Kirigami.Units.smallSpacing
        readonly property int answerColumnCount: {
            const availableAnswerCount = Math.max(1, internal.availableAnswers.length);
            if (internal.compactMode && availableAnswerCount >= 2) {
                return 2;
            }
            const availableWidth = Math.max(1, answerGridView.width);
            const fittedColumns = Math.max(1, Math.floor((availableWidth + internal.answerCellSpacing) / (Kirigami.Units.gridUnit * 10 + internal.answerCellSpacing)));
            return Math.max(1, Math.min(5, fittedColumns, availableAnswerCount));
        }
        readonly property var availableAnswers: Core.exerciseSessionController.availableAnswersModel(exerciseView.currentExercise || {})
        readonly property bool canEditUserAnswers: Core.exerciseSessionController.canEditUserAnswers(exerciseView.state, internal.selectedOptionCount, animation.running)
        readonly property bool canShowPitchPreview: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] !== "rhythm" && exerciseView.state === "waitingForAnswer"
        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        readonly property bool compactMode: !applicationWindow().wideScreen || Kirigami.Settings.isMobile
        readonly property real contentPadding: Kirigami.Units.largeSpacing * 2
        property int countIn: 0
        readonly property bool exercisePlaying: Core.soundController !== null && Core.soundController.state === ISoundController.PlayingState
        property Item hoveredAvailableAnswer
        readonly property int maximumExercises: Core.settingsController.testExerciseCount
        readonly property bool musicViewsTabbed: !applicationWindow().wideScreen && exerciseView.height > exerciseView.width
        property int onboardingInitialMusicTabIndex: -1
        property bool onboardingMusicTabCaptured: false
        readonly property real rhythmAnswerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.0)
        readonly property real rhythmAnswerCardVerticalOffset: Math.round(internal.rhythmAnswerCardTextSize * 0.22)
        property bool rhythmPlaybackCounting: false
        readonly property int rhythmPlaybackSubTickInterval: Core.soundController === null ? 250 : Math.max(1, Math.round(60000 / Core.soundController.tempo / internal.rhythmPlaybackSubdivisionCount))
        property int rhythmPlaybackSubdivision: 0
        readonly property int rhythmPlaybackSubdivisionCount: Core.soundController === null ? 1 : Math.max(1, Core.soundController.rhythmCountInSubdivisions)
        readonly property bool rhythmicExercise: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] === "rhythm"
        property Item rightAnswerRectangle
        readonly property real sectionPadding: Kirigami.Units.smallSpacing
        readonly property int selectedOptionCount: Core.exerciseSessionController.selectedOptionCount(exerciseView.currentExercise || {}, Core.settingsController.rhythmPatternCount)
        property bool stoppingActivity: false
    }
    Item {
        id: contentShell

        anchors.fill: parent

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            spacing: 0

            ExerciseHeader {
                id: exerciseHeader

                actionButtonWidth: Math.max(playQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)
                actionOnboardingTexts: [i18n("Use the first button to hear or replace the question, Give Up to reveal its answer, and Start Test for a scored series."), i18n("Use the first button to hear or replace the rhythm, Give Up to reveal its answer, and Start Test for a scored series.")]
                compactMode: internal.compactMode
                iconName: exerciseView.currentExerciseIconName
                onboardingGroups: ["melodic", "rhythmic"]
                onboardingTexts: [i18n("These messages explain the question and show its status."), i18n("These messages explain the question and show its status.")]
                subtitle: internal.exercisePlaying ? i18n("Playing…") : Core.exerciseSessionController.statusText
                subtitleColor: {
                    if (internal.exercisePlaying) {
                        return Kirigami.Theme.highlightColor;
                    }
                    switch (Core.exerciseSessionController.statusRole) {
                    case ExerciseSessionController.PositiveStatus:
                        return Kirigami.Theme.positiveTextColor;
                    case ExerciseSessionController.NegativeStatus:
                        return Kirigami.Theme.negativeTextColor;
                    default:
                        return Kirigami.Theme.textColor;
                    }
                }
                title: exerciseView.currentExercise === undefined ? "" : exerciseView.state === "waitingForAnswer" ? Core.exerciseSessionController.answerInstruction(internal.selectedOptionCount) : i18nc("technical term, do you have a musician friend?", exerciseView.currentExercise["userMessage"])

                Button {
                    id: playQuestionButton

                    Layout.preferredWidth: exerciseHeader.actionButtonWidth
                    enabled: !animation.running && !testFeedbackTimer.running && !internal.exercisePlaying
                    text: exerciseView.state === "waitingForNewQuestion" ? i18n("New Question") : i18n("Play Question")

                    onClicked: {
                        if (exerciseView.state === "waitingForNewQuestion") {
                            generateNewQuestion();
                        }
                        Core.soundController.play();
                    }
                }
                Button {
                    id: giveUpButton

                    Layout.preferredWidth: exerciseHeader.actionButtonWidth
                    enabled: exerciseView.state === "waitingForAnswer" && !Core.exerciseSessionController.isTest && !animation.running && !internal.exercisePlaying
                    text: i18n("Give Up")

                    onClicked: {
                        const rightAnswers = Core.exerciseSessionController.selectedExerciseOptions;
                        Core.exerciseSessionController.giveUpWithCorrectAnswers(rightAnswers, internal.availableAnswers, internal.colors, internal.selectedOptionCount);
                        checkAnswers();
                    }
                }
                Button {
                    id: testButton

                    Layout.preferredWidth: exerciseHeader.actionButtonWidth
                    enabled: !internal.exercisePlaying
                    text: Core.exerciseSessionController.isTest ? i18n("Stop Test") : i18n("Start Test")

                    onClicked: {
                        if (!Core.exerciseSessionController.isTest) {
                            testFeedbackTimer.stop();
                            Core.exerciseSessionController.startTest();
                            generateNewQuestion();
                            if (Core.exerciseSessionController.isTest) {
                                Core.soundController.play();
                            }
                        } else {
                            clearCurrentRun();
                            Core.exerciseSessionController.stopTest();
                        }
                    }
                }
            }
            Item {
                id: answerFrame

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.leftMargin: internal.contentPadding
                Layout.minimumHeight: availableAnswersHeading.implicitHeight + Kirigami.Units.smallSpacing + internal.answerCellHeight + internal.sectionPadding * 2
                Layout.rightMargin: internal.contentPadding
                Layout.topMargin: internal.contentPadding
                Onboarding.groups: ["melodic", "rhythmic"]
                Onboarding.texts: [i18n("Choose an answer here. Hover, or press and hold, to preview it below."), i18n("Choose each rhythm part from these available answers.")]

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        id: availableAnswersHeading

                        Layout.fillWidth: true

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 3
                            text: i18n("Available answers")
                        }
                        Label {
                            color: Kirigami.Theme.disabledTextColor
                            text: i18n("Scroll for more")
                            visible: internal.answerCardsOverflowing
                        }
                    }
                    Frame {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.minimumHeight: internal.answerCellHeight + internal.sectionPadding * 2
                        bottomPadding: 0
                        leftPadding: 0
                        padding: 0
                        rightPadding: 0
                        topPadding: 0

                        GridView {
                            id: answerGridView

                            bottomMargin: answerGridView.topMargin
                            boundsBehavior: Flickable.StopAtBounds
                            cellHeight: internal.answerCellHeight + internal.answerCellSpacing
                            cellWidth: Math.max(1, width / internal.answerColumnCount)
                            clip: true
                            delegate: answerOption
                            flow: GridView.FlowLeftToRight
                            layoutDirection: Qt.LeftToRight
                            model: internal.availableAnswers
                            opacity: exerciseView.onboardingCardsHidden ? 0 : 1
                            topMargin: internal.rhythmicExercise && !internal.answerCardsOverflowing ? Math.max(0, Math.round((height - internal.answerCardsHeight) / 2)) : 0

                            ScrollIndicator.vertical: ScrollIndicator {
                                active: internal.answerCardsOverflowing
                            }

                            anchors {
                                fill: parent
                                margins: internal.answerCellSpacing
                            }
                        }
                    }
                }
            }
            Item {
                id: selectedAnswersFrame

                Layout.bottomMargin: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] === "rhythm" ? internal.contentPadding : 0
                Layout.fillWidth: true
                Layout.leftMargin: internal.contentPadding
                Layout.preferredHeight: selectedAnswersLayout.implicitHeight
                Layout.rightMargin: internal.contentPadding
                Layout.topMargin: internal.contentPadding
                Onboarding.groups: ["melodic", "rhythmic"]
                Onboarding.texts: [i18n("Your selected answer appears here."), i18n("Build your rhythm answer here, one part at a time.")]

                ColumnLayout {
                    id: selectedAnswersLayout

                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        id: selectedAnswersHeading

                        Layout.fillWidth: true

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 3
                            text: Core.exerciseSessionController.showingCorrectAnswers ? i18np("Correct answer", "Correct answers", internal.selectedOptionCount) : i18np("Your answer", "Your answers", internal.selectedOptionCount)
                        }
                        Label {
                            color: Kirigami.Theme.disabledTextColor
                            text: i18n("Scroll for more |")
                            visible: selectedAnswersFlickable.canScrollHorizontally
                        }
                        Label {
                            color: Kirigami.Theme.disabledTextColor
                            text: i18n("%1 / %2", Core.exerciseSessionController.currentAnswer, internal.selectedOptionCount)
                        }
                        Button {
                            enabled: internal.canEditUserAnswers
                            text: i18n("Backspace")
                            visible: exerciseView.currentExercise !== undefined && (exerciseView.currentExercise["playMode"] === "rhythm" || internal.canEditUserAnswers)

                            onClicked: removeLastUserAnswer()
                        }
                    }
                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: internal.answerCellHeight + internal.sectionPadding * 2
                        padding: 0

                        Flickable {
                            id: selectedAnswersFlickable

                            readonly property bool canScrollHorizontally: contentWidth > width

                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            contentHeight: height
                            contentWidth: selectedAnswersRow.width
                            contentX: Math.max(0, (contentWidth - width) / 2)
                            opacity: exerciseView.onboardingCardsHidden ? 0 : 1

                            ScrollIndicator.horizontal: ScrollIndicator {
                                id: selectedAnswersScrollIndicator

                                active: selectedAnswersFlickable.canScrollHorizontally
                                visible: selectedAnswersFlickable.canScrollHorizontally

                                contentItem: Rectangle {
                                    color: selectedAnswersScrollIndicator.palette.mid
                                    implicitHeight: 2
                                    implicitWidth: 2
                                    opacity: 0.75
                                    visible: selectedAnswersScrollIndicator.visible && selectedAnswersScrollIndicator.size < 1.0
                                }
                            }

                            anchors {
                                fill: parent
                                margins: internal.sectionPadding
                            }
                            Row {
                                id: selectedAnswersRow

                                height: selectedAnswersFlickable.height
                                spacing: Kirigami.Units.smallSpacing
                                x: Math.max(0, (selectedAnswersFlickable.width - width) / 2)

                                Repeater {
                                    delegate: selectedAnswerDelegate
                                    model: internal.selectedOptionCount
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
                Layout.leftMargin: internal.contentPadding
                Layout.maximumHeight: visible ? viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0) : 0
                Layout.preferredHeight: visible ? viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0) : 0
                Layout.rightMargin: internal.contentPadding
                Layout.topMargin: internal.contentPadding
                spacing: Kirigami.Units.smallSpacing
                visible: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] !== "rhythm"

                GridLayout {
                    id: musicViewsLayout

                    readonly property real musicViewWidth: tabbed ? width : (width - columnSpacing) / 2
                    readonly property bool tabbed: internal.musicViewsTabbed

                    Layout.fillWidth: true
                    Layout.preferredHeight: musicPanel.viewHeight
                    columnSpacing: Kirigami.Units.largeSpacing * 2
                    columns: tabbed ? 1 : 2
                    rowSpacing: Kirigami.Units.largeSpacing
                    uniformCellWidths: !tabbed

                    Item {
                        id: pianoViewContainer

                        Layout.fillWidth: true
                        Layout.preferredHeight: musicPanel.viewHeight
                        Layout.preferredWidth: musicViewsLayout.musicViewWidth
                        visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 0

                        Item {
                            id: pianoViewOnboardingTarget

                            Onboarding.groups: ["melodic"]
                            Onboarding.texts: [i18n("The keyboard shows the notes in the question or preview.")]
                            height: musicViewsLayout.tabbed ? musicPanel.height : parent.height
                            width: musicViewsLayout.tabbed ? musicPanel.width : parent.width
                            x: musicViewsLayout.tabbed ? -pianoViewContainer.x - musicViewsLayout.x : 0
                            y: musicViewsLayout.tabbed ? -pianoViewContainer.y - musicViewsLayout.y : 0
                            z: -1

                            Onboarding.onAboutToShow: {
                                if (musicViewsLayout.tabbed) {
                                    musicTabs.currentIndex = 0;
                                }
                            }
                        }
                        PianoView {
                            id: pianoView

                            height: Math.min(sheetMusicView.staffGroupHeight, parent.height)

                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    Item {
                        id: sheetMusicViewContainer

                        Layout.fillWidth: true
                        Layout.preferredHeight: musicPanel.viewHeight
                        Layout.preferredWidth: musicViewsLayout.musicViewWidth
                        clip: true
                        visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 1

                        Item {
                            id: sheetMusicViewOnboardingTarget

                            Onboarding.groups: ["melodic"]
                            Onboarding.texts: [i18n("The staff shows the same notes in music notation.")]
                            height: musicViewsLayout.tabbed ? musicPanel.height : parent.height
                            width: musicViewsLayout.tabbed ? musicPanel.width : parent.width
                            x: musicViewsLayout.tabbed ? -sheetMusicViewContainer.x - musicViewsLayout.x : 0
                            y: musicViewsLayout.tabbed ? -sheetMusicViewContainer.y - musicViewsLayout.y : 0
                            z: -1

                            Onboarding.onAboutToShow: {
                                if (musicViewsLayout.tabbed) {
                                    musicTabs.currentIndex = 1;
                                }
                            }
                        }
                        SheetMusicView {
                            id: sheetMusicView

                            anchors.fill: parent
                        }
                    }
                }
                TabBar {
                    id: musicTabs

                    Layout.fillWidth: true
                    position: TabBar.Footer
                    visible: internal.musicViewsTabbed

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

            property color accentColor: colorForAnswerIndex(index)
            readonly property real cardOffset: (index % internal.answerColumnCount) * internal.answerCellSpacing / internal.answerColumnCount
            readonly property real cardWidth: Math.max(1, (GridView.view.width - internal.answerCellSpacing * (internal.answerColumnCount - 1)) / internal.answerColumnCount)
            required property int index
            property bool longPressed: false
            property var model: modelData
            required property var modelData

            bottomInset: 0
            enabled: exerciseView.state === "waitingForAnswer" && !animation.running
            height: GridView.view.cellHeight - internal.answerCellSpacing
            hoverEnabled: !Kirigami.Settings.isMobile
            implicitHeight: GridView.view.cellHeight - internal.answerCellSpacing
            implicitWidth: GridView.view.cellWidth
            leftInset: cardOffset
            leftPadding: cardOffset
            opacity: Core.exerciseSessionController.highlightingSingleAnswer && model !== undefined && model.name !== Core.exerciseSessionController.highlightedAnswerName ? 0.25 : enabled ? 1 : 0.45
            padding: 0
            rightInset: width - cardOffset - cardWidth
            rightPadding: width - cardOffset - cardWidth
            topInset: 0
            width: GridView.view.cellWidth

            background: Rectangle {
                color: answerDelegate.accentColor
                radius: Kirigami.Units.cornerRadius

                border {
                    color: answerDelegate.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    width: answerDelegate.activeFocus ? 2 : 1
                }
            }
            contentItem: Item {
                Text {
                    readonly property bool rhythmCard: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] === "rhythm"

                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#202124"
                    elide: Text.ElideRight
                    height: implicitHeight
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    text: answerDelegate.model !== undefined && answerDelegate.model.name !== undefined ? i18nc("technical term, do you have a musician friend?", answerDelegate.model.name) : ""
                    width: Math.max(1, parent.width - internal.answerCardHorizontalPadding * 2)
                    wrapMode: Text.WordWrap
                    y: Math.round((parent.height - height) / 2 + (rhythmCard ? internal.rhythmAnswerCardVerticalOffset : 0))

                    font {
                        family: rhythmCard ? bravura.name : Kirigami.Theme.defaultFont.family
                        pixelSize: rhythmCard ? internal.rhythmAnswerCardTextSize : internal.answerCardTextSize
                    }
                }
            }

            onActiveFocusChanged: {
                if (activeFocus && internal.canShowPitchPreview) {
                    showAvailableAnswerPreview(answerDelegate);
                } else {
                    restoreAvailableAnswerPreview(answerDelegate);
                }
            }
            onClicked: {
                if (longPressed) {
                    longPressed = false;
                    return;
                }
                chooseAnswer(answerDelegate.model, answerDelegate.index);
            }
            onHoveredChanged: {
                if (hovered && internal.canShowPitchPreview) {
                    showAvailableAnswerPreview(answerDelegate);
                } else {
                    restoreAvailableAnswerPreview(answerDelegate);
                }
            }
            onPressAndHold: {
                if (internal.canShowPitchPreview) {
                    longPressed = true;
                    showAvailableAnswerPreview(answerDelegate);
                }
            }
            onReleased: {
                if (longPressed) {
                    restoreAvailableAnswerPreview(answerDelegate);
                }
            }
        }
    }
    Component {
        id: selectedAnswerDelegate

        ItemDelegate {
            id: selectedDelegate

            property color accentColor: {
                if (!filled) {
                    return Kirigami.Theme.backgroundColor;
                }
                if (showingCorrection) {
                    return expectedAnswer !== undefined ? colorForAnswer(expectedAnswer) : Kirigami.Theme.backgroundColor;
                }
                return submittedAnswer.color !== undefined ? submittedAnswer.color : Kirigami.Theme.backgroundColor;
            }
            property bool correctAnswer: filled && submitted && !wrongAnswer
            property var displayedAnswer: showingCorrection ? expectedAnswer : submittedAnswer
            property var expectedAnswer: Core.exerciseSessionController.selectedExerciseOptions[index]
            property bool filled: submittedAnswer !== undefined
            required property int index
            property bool showingCorrection: Core.exerciseSessionController.correctedAnswerPosition === index
            property bool submitted: Core.exerciseSessionController.currentAnswer >= internal.selectedOptionCount
            property var submittedAnswer: index < Core.exerciseSessionController.userAnswers.length ? Core.exerciseSessionController.userAnswers[index] : undefined
            property bool wrongAnswer: filled && submitted && expectedAnswer !== undefined && submittedAnswer.name !== expectedAnswer.name

            bottomInset: 0
            enabled: filled
            height: selectedAnswersFlickable.height
            hoverEnabled: true
            leftInset: 0
            padding: 0
            rightInset: 0
            topInset: 0
            width: Math.max(1, answerGridView.cellWidth - internal.answerCellSpacing)

            background: Rectangle {
                color: selectedDelegate.filled ? selectedDelegate.accentColor : Kirigami.Theme.alternateBackgroundColor
                radius: Kirigami.Units.cornerRadius

                border {
                    color: selectedDelegate.showingCorrection ? Kirigami.Theme.positiveTextColor : selectedDelegate.wrongAnswer ? Kirigami.Theme.negativeTextColor : selectedDelegate.correctAnswer ? Kirigami.Theme.positiveTextColor : selectedDelegate.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    width: selectedDelegate.activeFocus || selectedDelegate.wrongAnswer || selectedDelegate.correctAnswer || selectedDelegate.showingCorrection ? 2 : 1
                }
            }
            contentItem: Item {
                anchors.fill: parent

                Text {
                    readonly property bool rhythmCard: selectedDelegate.filled && exerciseView.currentExercise["playMode"] === "rhythm"

                    anchors.horizontalCenter: parent.horizontalCenter
                    color: selectedDelegate.filled ? "#202124" : Kirigami.Theme.disabledTextColor
                    elide: Text.ElideRight
                    height: implicitHeight
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    text: selectedDelegate.filled && selectedDelegate.displayedAnswer !== undefined && selectedDelegate.displayedAnswer.name !== undefined ? i18nc("technical term, do you have a musician friend?", selectedDelegate.displayedAnswer.name) : i18n("Answer %1", selectedDelegate.index + 1)
                    width: Math.max(1, parent.width - internal.answerCardHorizontalPadding * 2)
                    wrapMode: Text.WordWrap
                    y: Math.round((parent.height - height) / 2 + (rhythmCard ? internal.rhythmAnswerCardVerticalOffset : 0))

                    font {
                        family: rhythmCard ? bravura.name : Kirigami.Theme.defaultFont.family
                        pixelSize: rhythmCard ? internal.rhythmAnswerCardTextSize : internal.answerCardTextSize
                    }
                }
            }

            onClicked: {
                if (canShowSubmittedAnswerCorrection(index)) {
                    toggleSubmittedAnswerCorrection(index);
                }
            }
        }
    }
    Shortcut {
        enabled: internal.canEditUserAnswers
        sequence: "Backspace"

        onActivated: removeLastUserAnswer()
    }
    Timer {
        id: rhythmPlaybackCountTimer

        interval: internal.rhythmPlaybackSubTickInterval
        repeat: true

        onTriggered: {
            ++internal.rhythmPlaybackSubdivision;
            if (internal.rhythmPlaybackSubdivision < internal.rhythmPlaybackSubdivisionCount) {
                exerciseView.countInSubTickRequested();
                return;
            }

            internal.rhythmPlaybackSubdivision = 0;
            if (internal.countIn < internal.selectedOptionCount) {
                ++internal.countIn;
            } else {
                rhythmPlaybackCountTimer.stop();
            }
        }
    }
    Timer {
        id: testFeedbackTimer

        interval: 1600

        onTriggered: {
            if (Core.exerciseSessionController.isTest) {
                nextTestExercise();
            }
        }
    }
    ParallelAnimation {
        id: animation

        loops: 2

        onStopped: {
            if (!internal.stoppingActivity) {
                finishSingleAnswerFeedback();
            }
        }

        SequentialAnimation {
            SequentialAnimation {
                loops: 2

                PropertyAnimation {
                    duration: 150
                    property: "scale"
                    target: internal.rightAnswerRectangle
                    to: 0.9
                }
                PropertyAnimation {
                    duration: 150
                    property: "scale"
                    target: internal.rightAnswerRectangle
                    to: 1.0
                }
            }
            PauseAnimation {
                duration: 200
            }
        }
    }
    Connections {
        function onSelectedExerciseOptionsChanged(): void {
            pianoView.clearAllMarks();
        }

        target: Core.exerciseSessionController
    }
    Connections {
        function onSelectedExerciseOptionsChanged(): void {
            sheetMusicView.clearAllMarks();
        }

        target: Core.exerciseSessionController
    }
    Connections {
        function onCountInChanged(count: int): void {
            if (internal.rhythmicExercise && count === 0 && internal.countIn > 0 && !internal.stoppingActivity && Core.soundController.state === ISoundController.PlayingState) {
                exerciseView.startRhythmPlaybackCount();
            } else if (!internal.rhythmPlaybackCounting) {
                internal.countIn = count;
            }
        }
        function onStateChanged(state: ISoundController.State): void {
            if (state === ISoundController.StoppedState && internal.rhythmPlaybackCounting) {
                exerciseView.stopRhythmPlaybackCount();
            }
        }

        target: Core.soundController
    }
}
