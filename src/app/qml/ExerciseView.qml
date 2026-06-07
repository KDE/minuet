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

    readonly property real answerCardHorizontalPadding: Kirigami.Units.largeSpacing
    readonly property real answerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.2)
    readonly property real answerCardWidth: Math.max(1, answerGridView.cellWidth - answerCellSpacing)
    readonly property real answerCellHeight: Math.max(Kirigami.Units.gridUnit * 3.0, Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 2)
    readonly property real answerCellSpacing: Kirigami.Units.smallSpacing
    readonly property int answerColumnCount: {
        const availableAnswerCount = Math.max(1, availableAnswers.length);
        if (compactMode && availableAnswerCount >= 2) {
            return 2;
        }

        const availableWidth = Math.max(1, answerGridView.width);
        const fittedColumns = Math.max(1, Math.floor((availableWidth + answerCellSpacing) / (minimumAnswerCardWidth + answerCellSpacing)));
        return Math.max(1, Math.min(5, fittedColumns, availableAnswerCount));
    }
    readonly property var availableAnswers: Core.exerciseSessionController.availableAnswersModel(exerciseView.currentExercise || {})
    readonly property bool canEditUserAnswers: Core.exerciseSessionController.canEditUserAnswers(exerciseView.state, exerciseView.selectedOptionCount, animation.running)
    readonly property bool canShowPitchPreview: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] !== "rhythm" && exerciseView.state === "waitingForAnswer"
    readonly property bool compactMode: !applicationWindow().wideScreen || Kirigami.Settings.isMobile
    readonly property real contentPadding: Kirigami.Units.largeSpacing * 2
    property alias countIn: internal.countIn
    property var currentExercise
    property string currentExerciseIconName: ""
    readonly property bool exercisePlaying: Core.soundController !== null && Core.soundController.state === ISoundController.PlayingState
    readonly property int maximumExercises: Core.settingsController.testExerciseCount
    readonly property real minimumAnswerCardWidth: Kirigami.Units.gridUnit * 10
    readonly property bool musicViewsTabbed: !applicationWindow().wideScreen && exerciseView.height > exerciseView.width
    readonly property real rhythmAnswerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.0)
    readonly property real rhythmAnswerCardVerticalOffset: Math.round(rhythmAnswerCardTextSize * 0.22)
    readonly property real sectionPadding: Kirigami.Units.smallSpacing
    readonly property real selectedAnswerHeight: answerCellHeight
    readonly property int selectedOptionCount: Core.exerciseSessionController.selectedOptionCount(exerciseView.currentExercise || {}, Core.settingsController.rhythmPatternCount)
    readonly property color statusMessageColor: {
        if (exerciseView.exercisePlaying) {
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

    function canShowSubmittedAnswerCorrection(position: int): bool {
        return Core.exerciseSessionController.canShowSubmittedAnswerCorrection(position, exerciseView.currentExercise || {}, exerciseView.selectedOptionCount, Core.exerciseSessionController.selectedExerciseOptions);
    }
    function checkAnswers(): void {
        var rightAnswers = Core.exerciseSessionController.selectedExerciseOptions;
        internal.hoveredAvailableAnswer = null;
        var expectedAnswers = exerciseView.selectedOptionCount;
        Core.exerciseSessionController.checkAnswers(rightAnswers, expectedAnswers, exerciseView.maximumExercises);

        showUserAnswers();
        if (exerciseView.selectedOptionCount === 1)
            highlightRightAnswer();
        else
            exerciseView.state = "waitingForNewQuestion";
    }
    function chooseAnswer(answer: var, index: int): void {
        if (exerciseView.state !== "waitingForAnswer" || animation.running || Core.exerciseSessionController.currentAnswer >= exerciseView.selectedOptionCount) {
            return;
        }

        if (Core.exerciseSessionController.chooseAnswer(answer, index, exerciseView.selectedOptionCount, internal.colors)) {
            checkAnswers();
        }
    }
    function colorForAnswer(answer: var): color {
        return Core.exerciseSessionController.colorForAnswer(answer || {}, exerciseView.availableAnswers, internal.colors);
    }
    function colorForAnswerIndex(index: int): color {
        return Core.exerciseSessionController.colorForAnswerIndex(index, internal.colors);
    }
    function finishSingleAnswerFeedback(): void {
        exerciseView.state = Core.exerciseSessionController.isTest ? "waitingForAnswer" : "waitingForNewQuestion";
        if (Core.exerciseSessionController.isTest) {
            nextTestExercise();
            if (Core.exerciseSessionController.currentExercise === exerciseView.maximumExercises + 1)
                Core.exerciseSessionController.resetTest();
        }
    }
    function generateNewQuestion(): void {
        pianoView.clearAllMarks();
        sheetMusicView.clearAllMarks();
        internal.hoveredAvailableAnswer = null;
        Core.exerciseSessionController.beginQuestion(exerciseView.maximumExercises);
        Core.exerciseSessionController.randomlySelectExerciseOptions(exerciseView.selectedOptionCount);
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
        var rightAnswerIndex = Core.exerciseSessionController.answerIndexForName(exerciseView.availableAnswers, chosenExercises[0].name);
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
        if (exerciseView.canEditUserAnswers && Core.exerciseSessionController.removeLastUserAnswer()) {
            showUserAnswers();
        }
    }
    function restoreAvailableAnswerPreview(answerRectangle: Item): void {
        if (internal.hoveredAvailableAnswer !== answerRectangle) {
            return;
        }

        internal.hoveredAvailableAnswer = null;
        if (exerciseView.canShowPitchPreview) {
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
        const presentation = Core.exerciseSessionController.answerPresentation(answers, Core.exerciseSessionController.chosenRootNote, exerciseView.currentExercise || {}, exerciseView.availableAnswers, internal.colors);
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
        if (!exerciseView.canShowPitchPreview) {
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
    function toggleSubmittedAnswerCorrection(position: int): void {
        if (Core.exerciseSessionController.correctedAnswerPosition === position) {
            restoreSubmittedAnswerCorrection(position);
        } else {
            showSubmittedAnswerCorrection(position);
        }
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

    onCurrentExerciseChanged: {
        internal.countIn = 0;
        pianoView.clearAllMarks();
        sheetMusicView.clearAllMarks();
        internal.hoveredAvailableAnswer = null;
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

        source: "SheetMusicView/Bravura.otf"
    }
    QtObject {
        id: internal

        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        property int countIn: 0
        property Item hoveredAvailableAnswer
        property Item rightAnswerRectangle
    }
    Item {
        id: contentShell

        anchors.fill: parent

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: exerciseHeader

                Layout.fillWidth: true
                Layout.preferredHeight: headerLayout.implicitHeight + headerSeparator.implicitHeight
                color: Kirigami.Theme.alternateBackgroundColor

                RowLayout {
                    id: headerLayout

                    spacing: Kirigami.Units.smallSpacing

                    anchors {
                        bottom: headerSeparator.top
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    Kirigami.Icon {
                        id: exerciseIcon

                        readonly property real sideLength: visible ? headerCenter.implicitHeight : 0

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: sideLength * 0.75
                        Layout.preferredWidth: sideLength
                        source: exerciseView.currentExerciseIconName
                        visible: exerciseView.currentExerciseIconName.length > 0 && !exerciseView.compactMode
                    }
                    ColumnLayout {
                        id: headerCenter

                        Layout.fillWidth: true
                        spacing: 0

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            Layout.maximumHeight: implicitHeight
                            Layout.topMargin: 2 * Kirigami.Units.largeSpacing
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            level: exerciseView.musicViewsTabbed ? 3 : 2
                            text: {
                                if (exerciseView.currentExercise === undefined) {
                                    return "";
                                }
                                if (exerciseView.state === "waitingForAnswer") {
                                    return Core.exerciseSessionController.answerInstruction(exerciseView.selectedOptionCount);
                                }
                                return i18nc("technical term, do you have a musician friend?", exerciseView.currentExercise["userMessage"]);
                            }
                        }
                        Kirigami.Heading {
                            id: messageText

                            Layout.fillWidth: true
                            Layout.maximumHeight: implicitHeight
                            color: exerciseView.statusMessageColor
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            level: 3
                            text: exerciseView.exercisePlaying ? i18n("Playing…") : Core.exerciseSessionController.statusText
                        }
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.bottomMargin: 2 * Kirigami.Units.largeSpacing
                            Layout.fillWidth: true
                            Layout.preferredHeight: actionButtons.implicitHeight
                            Layout.topMargin: Kirigami.Units.smallSpacing

                            Row {
                                id: actionButtons

                                readonly property real buttonWidth: Math.max(playQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Kirigami.Units.smallSpacing

                                Button {
                                    id: playQuestionButton

                                    enabled: !animation.running && !exerciseView.exercisePlaying
                                    highlighted: exerciseView.state === "waitingForNewQuestion" || exerciseView.state === "waitingForAnswer"
                                    text: (exerciseView.state === "waitingForNewQuestion") ? i18n("New Question") : i18n("Play Question")
                                    width: actionButtons.buttonWidth

                                    onClicked: {
                                        if (exerciseView.state === "waitingForNewQuestion") {
                                            generateNewQuestion();
                                        }
                                        Core.soundController.play();
                                    }
                                }
                                Button {
                                    id: giveUpButton

                                    enabled: exerciseView.state === "waitingForAnswer" && !animation.running && !exerciseView.exercisePlaying
                                    text: i18n("Give Up")
                                    width: actionButtons.buttonWidth

                                    onClicked: {
                                        var rightAnswers = Core.exerciseSessionController.selectedExerciseOptions;
                                        Core.exerciseSessionController.giveUpWithCorrectAnswers(rightAnswers, exerciseView.availableAnswers, internal.colors, exerciseView.selectedOptionCount);
                                        checkAnswers();
                                    }
                                }
                                Button {
                                    id: testButton

                                    enabled: !exerciseView.exercisePlaying
                                    text: Core.exerciseSessionController.isTest ? i18n("Stop Test") : i18n("Start Test")
                                    width: actionButtons.buttonWidth

                                    onClicked: {
                                        if (!Core.exerciseSessionController.isTest) {
                                            Core.exerciseSessionController.startTest();
                                            generateNewQuestion();
                                            if (Core.exerciseSessionController.isTest)
                                                Core.soundController.play();
                                        } else {
                                            Core.exerciseSessionController.stopTest();
                                            exerciseView.state = "waitingForNewQuestion";
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        Layout.preferredHeight: 1
                        Layout.preferredWidth: exerciseIcon.sideLength
                    }
                }
                Kirigami.Separator {
                    id: headerSeparator

                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                }
            }
            Item {
                id: answerFrame

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.leftMargin: exerciseView.contentPadding
                Layout.minimumHeight: availableAnswersHeading.implicitHeight + Kirigami.Units.smallSpacing + exerciseView.answerCellHeight + exerciseView.sectionPadding * 2
                Layout.rightMargin: exerciseView.contentPadding
                Layout.topMargin: exerciseView.contentPadding

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
                            visible: answerGridView.contentHeight > answerGridView.height
                        }
                    }
                    Frame {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.minimumHeight: exerciseView.answerCellHeight + exerciseView.sectionPadding * 2
                        bottomPadding: 0
                        leftPadding: 0
                        padding: 0
                        rightPadding: 0
                        topPadding: 0

                        GridView {
                            id: answerGridView

                            boundsBehavior: Flickable.StopAtBounds
                            cellHeight: exerciseView.answerCellHeight + exerciseView.answerCellSpacing
                            cellWidth: Math.max(1, width / exerciseView.answerColumnCount)
                            clip: true
                            delegate: answerOption
                            flow: GridView.FlowLeftToRight
                            layoutDirection: Qt.LeftToRight
                            model: exerciseView.availableAnswers

                            ScrollIndicator.vertical: ScrollIndicator {
                                active: answerGridView.contentHeight > answerGridView.height
                            }

                            anchors {
                                fill: parent
                                margins: exerciseView.answerCellSpacing
                            }
                        }
                    }
                }
            }
            Item {
                id: selectedAnswersFrame

                Layout.bottomMargin: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] === "rhythm" ? exerciseView.contentPadding : 0
                Layout.fillWidth: true
                Layout.leftMargin: exerciseView.contentPadding
                Layout.preferredHeight: selectedAnswersLayout.implicitHeight
                Layout.rightMargin: exerciseView.contentPadding

                ColumnLayout {
                    id: selectedAnswersLayout

                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        id: selectedAnswersHeading

                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.largeSpacing

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 3
                            text: Core.exerciseSessionController.showingCorrectAnswers ? i18np("Correct answer", "Correct answers", exerciseView.selectedOptionCount) : i18np("Your answer", "Your answers", exerciseView.selectedOptionCount)
                        }
                        Label {
                            color: Kirigami.Theme.disabledTextColor
                            text: i18n("Scroll for more |")
                            visible: selectedAnswersFlickable.canScrollHorizontally
                        }
                        Label {
                            color: Kirigami.Theme.disabledTextColor
                            text: i18n("%1 / %2", Core.exerciseSessionController.currentAnswer, exerciseView.selectedOptionCount)
                        }
                        Button {
                            enabled: exerciseView.canEditUserAnswers
                            text: i18n("Backspace")
                            visible: exerciseView.currentExercise !== undefined && (exerciseView.currentExercise["playMode"] === "rhythm" || exerciseView.canEditUserAnswers)

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

                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            contentHeight: height
                            contentWidth: selectedAnswersRow.width
                            contentX: Math.max(0, (contentWidth - width) / 2)

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
                                margins: exerciseView.sectionPadding
                            }
                            Row {
                                id: selectedAnswersRow

                                height: selectedAnswersFlickable.height
                                spacing: Kirigami.Units.smallSpacing
                                x: Math.max(0, (selectedAnswersFlickable.width - width) / 2)

                                Repeater {
                                    delegate: selectedAnswerDelegate
                                    model: exerciseView.selectedOptionCount
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
                Layout.leftMargin: exerciseView.contentPadding
                Layout.maximumHeight: visible ? viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0) : 0
                Layout.preferredHeight: visible ? viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0) : 0
                Layout.rightMargin: exerciseView.contentPadding
                spacing: Kirigami.Units.smallSpacing
                visible: exerciseView.currentExercise !== undefined && exerciseView.currentExercise["playMode"] !== "rhythm"

                GridLayout {
                    id: musicViewsLayout

                    readonly property real musicViewWidth: tabbed ? width : (width - columnSpacing) / 2
                    readonly property bool tabbed: exerciseView.musicViewsTabbed

                    Layout.fillWidth: true
                    Layout.preferredHeight: musicPanel.viewHeight
                    columnSpacing: Kirigami.Units.largeSpacing * 2
                    columns: tabbed ? 1 : 2
                    rowSpacing: Kirigami.Units.largeSpacing
                    uniformCellWidths: !tabbed

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: musicPanel.viewHeight
                        Layout.preferredWidth: musicViewsLayout.musicViewWidth
                        visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 0

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
                        Layout.fillWidth: true
                        Layout.preferredHeight: musicPanel.viewHeight
                        Layout.preferredWidth: musicViewsLayout.musicViewWidth
                        clip: true
                        visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 1

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
                    visible: exerciseView.musicViewsTabbed

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
            readonly property real cardOffset: column * exerciseView.answerCellSpacing / exerciseView.answerColumnCount
            readonly property real cardWidth: Math.max(1, (GridView.view.width - exerciseView.answerCellSpacing * (exerciseView.answerColumnCount - 1)) / exerciseView.answerColumnCount)
            readonly property int column: index % exerciseView.answerColumnCount
            property bool dimmedByHighlight: Core.exerciseSessionController.highlightingSingleAnswer && model !== undefined && model.name !== Core.exerciseSessionController.highlightedAnswerName
            required property int index
            property bool longPressed: false
            property var model: modelData
            required property var modelData

            Accessible.name: model !== undefined && model.name !== undefined ? i18nc("technical term, do you have a musician friend?", model.name) : ""
            bottomInset: 0
            enabled: exerciseView.state === "waitingForAnswer" && !animation.running
            height: GridView.view.cellHeight - exerciseView.answerCellSpacing
            hoverEnabled: !Kirigami.Settings.isMobile
            implicitHeight: GridView.view.cellHeight - exerciseView.answerCellSpacing
            implicitWidth: GridView.view.cellWidth
            leftInset: cardOffset
            leftPadding: cardOffset
            opacity: dimmedByHighlight ? 0.25 : enabled ? 1 : 0.45
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
                    readonly property bool rhythmCard: exerciseView.currentExercise["playMode"] === "rhythm"

                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#202124"
                    elide: Text.ElideRight
                    height: implicitHeight
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    text: answerDelegate.model !== undefined && answerDelegate.model.name !== undefined ? i18nc("technical term, do you have a musician friend?", answerDelegate.model.name) : ""
                    width: Math.max(1, parent.width - exerciseView.answerCardHorizontalPadding * 2)
                    wrapMode: Text.WordWrap
                    y: Math.round((parent.height - height) / 2 + (rhythmCard ? exerciseView.rhythmAnswerCardVerticalOffset : 0))

                    font {
                        family: rhythmCard ? bravura.name : Kirigami.Theme.defaultFont.family
                        pixelSize: rhythmCard ? exerciseView.rhythmAnswerCardTextSize : exerciseView.answerCardTextSize
                    }
                }
            }

            onActiveFocusChanged: {
                if (activeFocus && exerciseView.canShowPitchPreview) {
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
                if (hovered && exerciseView.canShowPitchPreview) {
                    showAvailableAnswerPreview(answerDelegate);
                } else {
                    restoreAvailableAnswerPreview(answerDelegate);
                }
            }
            onPressAndHold: {
                if (exerciseView.canShowPitchPreview) {
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
            property bool submitted: Core.exerciseSessionController.currentAnswer >= exerciseView.selectedOptionCount
            property var submittedAnswer: index < Core.exerciseSessionController.userAnswers.length ? Core.exerciseSessionController.userAnswers[index] : undefined
            property bool wrongAnswer: filled && submitted && expectedAnswer !== undefined && submittedAnswer.name !== expectedAnswer.name

            Accessible.name: filled ? (displayedAnswer !== undefined && displayedAnswer.name !== undefined ? i18nc("technical term, do you have a musician friend?", displayedAnswer.name) : "") : i18n("Empty answer slot")
            bottomInset: 0
            enabled: filled
            height: selectedAnswersFlickable.height
            hoverEnabled: true
            leftInset: 0
            padding: 0
            rightInset: 0
            topInset: 0
            width: exerciseView.answerCardWidth

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
                    width: Math.max(1, parent.width - exerciseView.answerCardHorizontalPadding * 2)
                    wrapMode: Text.WordWrap
                    y: Math.round((parent.height - height) / 2 + (rhythmCard ? exerciseView.rhythmAnswerCardVerticalOffset : 0))

                    font {
                        family: rhythmCard ? bravura.name : Kirigami.Theme.defaultFont.family
                        pixelSize: rhythmCard ? exerciseView.rhythmAnswerCardTextSize : exerciseView.answerCardTextSize
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
        enabled: exerciseView.canEditUserAnswers
        sequence: "Backspace"

        onActivated: removeLastUserAnswer()
    }
    ParallelAnimation {
        id: animation

        loops: 2

        onStopped: {
            finishSingleAnswerFeedback();
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
            internal.countIn = count;
        }

        target: Core.soundController
    }
}
