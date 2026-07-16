// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.onboarding

ExerciseContent {
    id: root

    function applyMicrophoneSettings(): void {
        if (!internal.microphone) {
            return;
        }
        internal.microphone.analysisMode = IMicrophoneInputController.ClappingOnsetOnly;
        internal.microphone.preset = IMicrophoneInputController.Clapping;
        internal.microphone.onsetMethod = Core.settingsController.clappingOnsetMethod;
        internal.microphone.onsetThreshold = Core.settingsController.clappingOnsetThreshold;
        internal.microphone.inputGateLevel = Core.settingsController.clappingInputGateLevel;
        internal.microphone.minimumOnsetStrength = Core.settingsController.clappingMinimumOnsetStrength;
    }
    function beginMicrophoneCapture(): void {
        if (!internal.microphone) {
            return;
        }
        internal.microphone.stop();
        internal.microphone.start();
    }
    function centerAllFigureCards(): void {
        if (internal.displayedFigureStates.length === 0 || rhythmViewport.width <= 0) {
            return;
        }

        rhythmViewport.contentX = rhythmContent.cardsOverflowing ? Math.max(0, (rhythmViewport.contentWidth - rhythmViewport.width) / 2) : 0;
    }
    function centerCurrentFigureCard(): void {
        if (internal.displayedFigureStates.length === 0 || rhythmViewport.width <= 0) {
            return;
        }
        if (!rhythmContent.cardsOverflowing) {
            rhythmViewport.contentX = 0;
            return;
        }
        if (internal.viewState !== "listening" || internal.countPhase !== "input") {
            root.centerAllFigureCards();
            return;
        }

        const cardIndex = Math.max(0, Math.min(internal.displayedFigureStates.length - 1, internal.countInOverlayAnchorIndex));
        const cardCenter = rhythmRow.x + cardIndex * (internal.rhythmCardWidth + rhythmRow.spacing) + internal.rhythmCardWidth / 2;
        rhythmViewport.contentX = Math.max(0, Math.min(rhythmViewport.contentWidth - rhythmViewport.width, cardCenter - rhythmViewport.width / 2));
    }
    function clampCountInOverlayX(value: real): real {
        const margin = Kirigami.Units.smallSpacing;
        const maximum = Math.max(margin, root.width - root.countInOverlaySize - margin);
        return Math.max(margin, Math.min(maximum, isFinite(value) ? value : margin));
    }
    function clampCountInOverlayY(value: real): real {
        const margin = Kirigami.Units.smallSpacing;
        const maximum = Math.max(margin, root.height - root.countInOverlaySize - margin);
        return Math.max(margin, Math.min(maximum, isFinite(value) ? value : margin));
    }
    function clearCurrentRun(): void {
        testNextQuestionTimer.stop();
        progressTimer.stop();
        timelineTimer.stop();
        finishTimer.stop();
        root.countIn = 0;
        internal.countInOverlayAnchorIndex = -1;
        internal.countPhase = "idle";
        internal.countInStarted = false;
        internal.inputTimingArmed = false;
        internal.inputTimingStarted = false;
        internal.listeningStartSeconds = -1;
        internal.performedOnsets = [];
        internal.viewState = "idle";
        if (internal.microphone) {
            internal.microphone.stop();
        }
        if (Core.soundController) {
            Core.soundController.stop();
        }
    }
    function completeExercise(): void {
        if (internal.viewState !== "analyzing") {
            return;
        }
        const evaluation = Core.clappingExerciseController.evaluate(internal.expectedOnsets, internal.figureStates, internal.performedOnsets, Core.clappingExerciseController.totalDurationMs(internal.figureStates) + internal.toleranceMs + 1, internal.toleranceMs);
        internal.figureStates = evaluation.figureStates;
        internal.score = evaluation.score;
        internal.viewState = "finished";
        Qt.callLater(root.centerAllFigureCards);
        finishScoredQuestion();
    }
    function countInOverlayTargetX(): real {
        if (internal.countPhase !== "input") {
            return root.clampCountInOverlayX(root.rhythmRowCenterX() - root.countInOverlaySize / 2);
        }
        const cardIndex = Math.max(0, Math.min(internal.displayedFigureStates.length - 1, internal.countInOverlayAnchorIndex));
        return root.clampCountInOverlayX(root.rhythmCardCenterX(cardIndex) - root.countInOverlaySize / 2);
    }
    function countInOverlayTargetY(): real {
        const cardY = rhythmFrame.y + rhythmViewport.y + rhythmRow.y;
        return root.clampCountInOverlayY(cardY - root.countInOverlaySize / 2);
    }
    function failInputAnalysis(message: string): void {
        if (internal.viewState !== "counting" && internal.viewState !== "listening" && internal.viewState !== "analyzing") {
            return;
        }
        progressTimer.stop();
        timelineTimer.stop();
        finishTimer.stop();
        root.countIn = 0;
        internal.countInOverlayAnchorIndex = -1;
        internal.countPhase = "idle";
        internal.countInStarted = false;
        internal.inputTimingArmed = false;
        internal.inputTimingStarted = false;
        internal.inputErrorMessage = message;
        internal.viewState = "ready";
        if (Core.soundController) {
            Core.soundController.stop();
        }
        Qt.callLater(root.centerAllFigureCards);
    }
    function finishExercise(): void {
        if (internal.viewState !== "listening") {
            return;
        }
        progressTimer.stop();
        timelineTimer.stop();
        finishTimer.stop();
        internal.viewState = "analyzing";
        root.countIn = 0;
        internal.countInOverlayAnchorIndex = -1;
        internal.countPhase = "idle";
        internal.countInStarted = false;
        if (Core.soundController) {
            Core.soundController.stop();
        }
        if (internal.microphone) {
            internal.microphone.finalizeInputAnalysis();
        } else {
            root.completeExercise();
        }
    }
    function finishScoredQuestion(): void {
        if (!Core.exerciseSessionController.isTest) {
            return;
        }

        const finalScore = Core.exerciseSessionController.recordTestScore(internal.score, Core.settingsController.testExerciseCount);
        if (finalScore >= 0) {
            internal.score = finalScore;
        } else {
            testNextQuestionTimer.restart();
        }
    }
    function generateQuestion(): void {
        Core.exerciseSessionController.beginQuestion(Core.settingsController.testExerciseCount);
        Core.exerciseSessionController.randomlySelectExerciseOptions(internal.selectedOptionCount);
        const question = Core.clappingExerciseController.createQuestion(Core.exerciseSessionController.selectedExerciseOptions, internal.beatMs);
        internal.expectedOnsets = question.expectedOnsets;
        internal.figureStates = question.figureStates;
        internal.performedOnsets = [];
        internal.score = -1;
        internal.viewState = "ready";
        Qt.callLater(root.centerAllFigureCards);
        Core.exerciseSessionController.finishQuestionGeneration();
    }
    function handleOnset(seconds: real): void {
        if (internal.viewState !== "listening" && internal.viewState !== "analyzing") {
            return;
        }
        if (!internal.inputTimingStarted || internal.listeningStartSeconds < 0) {
            return;
        }
        const elapsedMs = (seconds - internal.listeningStartSeconds) * 1000;
        root.updateInputTimeline(elapsedMs);
        if (elapsedMs < -internal.toleranceMs || elapsedMs > Core.clappingExerciseController.totalDurationMs(internal.figureStates) + internal.toleranceMs) {
            return;
        }
        internal.performedOnsets = Core.clappingExerciseController.addPerformedOnset(internal.performedOnsets, elapsedMs);
        refreshFigureStates(elapsedMs);
    }
    function mapRhythmRowX(localX: real): real {
        const geometryDependency = rhythmFrame.x + rhythmViewport.x + rhythmViewport.contentX + rhythmContent.x + rhythmRow.x + rhythmRow.implicitWidth;
        return rhythmRow.mapToItem(root, localX + geometryDependency * 0, 0).x;
    }
    function refreshFigureStates(elapsedMs: real): var {
        const evaluation = Core.clappingExerciseController.evaluate(internal.expectedOnsets, internal.figureStates, internal.performedOnsets, elapsedMs, internal.toleranceMs);
        internal.figureStates = evaluation.figureStates;
        return evaluation.figureStates;
    }
    function rhythmCardCenterX(index: int): real {
        return root.mapRhythmRowX(index * (internal.rhythmCardWidth + rhythmRow.spacing) + internal.rhythmCardWidth / 2);
    }
    function rhythmRowCenterX(): real {
        if (internal.displayedFigureStates.length <= 0) {
            return rhythmFrame.x + rhythmViewport.x + rhythmViewport.width / 2;
        }
        return root.mapRhythmRowX(rhythmRow.implicitWidth / 2);
    }
    function startExercise(): void {
        if (root.currentExercise === undefined || internal.viewState === "counting" || internal.viewState === "listening" || internal.viewState === "analyzing") {
            return;
        }
        if (internal.expectedOnsets.length === 0) {
            generateQuestion();
        }
        applyMicrophoneSettings();
        internal.inputErrorMessage = "";
        internal.performedOnsets = [];
        internal.countPhase = "preparation";
        internal.countInStarted = false;
        root.countIn = 0;
        internal.countInOverlayAnchorIndex = -1;
        internal.viewState = "counting";
        if (Core.soundController) {
            Core.soundController.playCountIn(4);
        }
    }
    function startInputTiming(): void {
        if (!internal.inputTimingArmed || internal.inputTimingStarted) {
            return;
        }
        if (internal.microphone) {
            internal.microphone.resetInputAnalysisState();
        }
        internal.listeningStartSeconds = internal.microphone ? internal.microphone.captureTimeSeconds : 0;
        internal.inputTimingStarted = true;
        internal.inputTimingArmed = false;
        root.updateInputTimeline(0);
        timelineTimer.restart();
        progressTimer.restart();
        finishTimer.restart();
    }
    function startListening(): void {
        if (internal.microphone && !internal.microphone.running) {
            beginMicrophoneCapture();
        }
        internal.countPhase = "input";
        internal.countInStarted = false;
        root.countIn = 0;
        internal.countInOverlayAnchorIndex = 0;
        internal.inputTimingArmed = true;
        internal.inputTimingStarted = false;
        internal.listeningStartSeconds = -1;
        internal.performedOnsets = [];
        internal.viewState = "listening";
        Qt.callLater(root.centerCurrentFigureCard);
        finishTimer.interval = Core.clappingExerciseController.totalDurationMs(internal.figureStates) + internal.toleranceMs + internal.beatMs;
        if (Core.soundController) {
            Core.soundController.playSilentCountIn(internal.selectedOptionCount);
        } else {
            root.startInputTiming();
        }
    }
    function startTest(): void {
        Core.exerciseSessionController.startTest();
        generateQuestion();
        startExercise();
    }
    function stateBorderColor(state: string): color {
        if (state === "correct") {
            return Kirigami.Theme.positiveTextColor;
        }
        if (state === "wrong") {
            return Kirigami.Theme.negativeTextColor;
        }
        return Kirigami.Theme.textColor;
    }
    function stopExerciseActivity(): void {
        clearCurrentRun();
        root.currentExercise = undefined;
    }
    function stopTest(): void {
        clearCurrentRun();
        Core.exerciseSessionController.stopTest();
        internal.viewState = internal.expectedOnsets.length > 0 ? "ready" : "idle";
        Qt.callLater(root.centerAllFigureCards);
    }
    function updateInputTimeline(elapsedMs: real): void {
        if (internal.countPhase !== "input" || internal.figureStates.length === 0) {
            return;
        }
        const index = Core.clappingExerciseController.timelineIndex(internal.figureStates, elapsedMs, internal.toleranceMs);
        const indexChanged = internal.countInOverlayAnchorIndex !== index;
        internal.countInOverlayAnchorIndex = index;
        root.countIn = index + 1;
        if (indexChanged) {
            root.centerCurrentFigureCard();
        }
    }

    countInOverlayInitial: internal.countPhase === "preparation" || root.onboardingCountIn > 0
    countInOverlaySize: Math.ceil(onsetMeterProbe.implicitWidth)
    countInOverlayX: root.countInOverlayTargetX()
    countInOverlayY: root.countInOverlayTargetY()
    visible: root.currentExercise !== undefined

    onCurrentExerciseChanged: {
        clearCurrentRun();
        internal.expectedOnsets = [];
        internal.figureStates = [];
        internal.performedOnsets = [];
        internal.score = -1;
        internal.viewState = "idle";
        if (root.currentExercise !== undefined) {
            Core.exerciseSessionController.resetForExercise();
        }
    }

    QtObject {
        id: internal

        readonly property real beatMs: 60000 / (Core.soundController ? Core.soundController.tempo : Core.settingsController.rhythmTempo)
        readonly property real cardHorizontalPadding: Kirigami.Units.largeSpacing * 2
        readonly property real contentPadding: Kirigami.Units.largeSpacing * 2
        property int countInOverlayAnchorIndex: -1
        property bool countInStarted: false
        property string countPhase: "idle"
        readonly property var displayedFigureStates: internal.figureStates.length > 0 ? internal.figureStates : root.onboardingPreviewActive ? [
            {
                "state": "pending",
                "onsets": [],
                "startMs": 0,
                "endMs": internal.beatMs,
                "name": "\uE1F0",
                "meterValue": 0,
                "meterAccuracy": 0,
                "meterText": i18n("Ready")
            }
        ] : []
        property var expectedOnsets: []
        property var figureStates: []
        property string inputErrorMessage: ""
        property bool inputTimingArmed: false
        property bool inputTimingStarted: false
        property real listeningStartSeconds: -1
        readonly property var microphone: Core.microphoneInputController
        readonly property bool microphoneReady: internal.microphone !== null && internal.microphone.inputDeviceAvailable
        property var performedOnsets: []
        readonly property real rhythmAnswerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.0)
        readonly property real rhythmCardWidth: Math.ceil(Math.max(Kirigami.Units.gridUnit * 4, onsetMeterProbe.implicitWidth) + internal.cardHorizontalPadding)
        property int score: -1
        readonly property int selectedOptionCount: Core.settingsController.rhythmPatternCount
        readonly property real toleranceMs: Math.min(180, internal.beatMs * Core.settingsController.clappingCorrectnessTolerancePercent / 100)
        property string viewState: "idle"
    }
    FontLoader {
        id: bravura

        source: "../sheetmusicview/Bravura.otf"
    }
    GraphicalMeter {
        id: onsetMeterProbe

        meterKind: "onset"
        visible: false
    }
    Timer {
        id: progressTimer

        interval: 50
        repeat: true

        onTriggered: {
            if (internal.viewState === "listening" && internal.microphone && internal.inputTimingStarted && internal.listeningStartSeconds >= 0) {
                root.refreshFigureStates(Math.max(0, (internal.microphone.captureTimeSeconds - internal.listeningStartSeconds) * 1000));
            }
        }
    }
    Timer {
        id: timelineTimer

        interval: 20
        repeat: true

        onTriggered: {
            if (internal.viewState === "listening" && internal.microphone && internal.inputTimingStarted && internal.listeningStartSeconds >= 0) {
                root.updateInputTimeline((internal.microphone.captureTimeSeconds - internal.listeningStartSeconds) * 1000);
            }
        }
    }
    Timer {
        id: finishTimer

        onTriggered: root.finishExercise()
    }
    Timer {
        id: testNextQuestionTimer

        interval: internal.beatMs

        onTriggered: {
            root.generateQuestion();
            root.startExercise();
        }
    }
    Connections {
        function onInputAnalysisFailed(message: string): void {
            root.failInputAnalysis(message);
        }
        function onInputAnalysisFinished(): void {
            root.completeExercise();
        }
        function onOnsetDetected(seconds: real, strength: real): void {
            root.handleOnset(seconds);
        }

        target: internal.microphone
    }
    Connections {
        function onCountInChanged(count: int): void {
            if (root.currentExercise === undefined) {
                return;
            }
            if (internal.countPhase === "preparation") {
                root.countIn = count;
                if (count > 0) {
                    internal.countInStarted = true;
                }
                if (count >= 4) {
                    root.beginMicrophoneCapture();
                } else if (count === 0 && internal.countInStarted) {
                    root.startListening();
                }
            } else if (internal.countPhase === "input") {
                if (count === 1) {
                    root.startInputTiming();
                }
            }
        }

        target: Core.soundController
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ExerciseHeader {
            id: exerciseHeader

            actionButtonWidth: Math.max(startQuestionButton.implicitWidth, testButton.implicitWidth)
            actionOnboardingTexts: [i18n("Use New Question or Start for one exercise, or Start Test for a scored series.")]
            compactMode: !applicationWindow().wideScreen || Kirigami.Settings.isMobile
            iconName: root.currentExerciseIconName
            onboardingGroups: ["clapping"]
            onboardingTexts: [i18n("The header shows the current instruction, microphone status, and score.")]
            subtitle: internal.inputErrorMessage.length > 0 ? internal.inputErrorMessage : internal.viewState === "listening" ? i18n("Listening...") : internal.viewState === "analyzing" ? i18n("Analyzing...") : Core.exerciseSessionController.isTest && Core.exerciseSessionController.statusText.length > 0 ? Core.exerciseSessionController.statusText : internal.microphone ? internal.microphone.inputDeviceAvailable ? internal.microphone.status : i18n("No microphone input devices found") : i18n("No microphone input plugin available")
            title: internal.score >= 0 ? i18n("Score: %1%", internal.score) : i18n("Clap the rhythm")

            QQC2.Button {
                id: startQuestionButton

                Layout.preferredWidth: exerciseHeader.actionButtonWidth
                enabled: internal.microphoneReady && internal.viewState !== "counting" && internal.viewState !== "listening" && internal.viewState !== "analyzing"
                text: internal.expectedOnsets.length === 0 || internal.viewState === "finished" ? i18n("New Question") : i18n("Start")

                onClicked: {
                    if (internal.expectedOnsets.length === 0 || internal.viewState === "finished") {
                        root.generateQuestion();
                    }
                    root.startExercise();
                }
            }
            QQC2.Button {
                id: testButton

                Layout.preferredWidth: exerciseHeader.actionButtonWidth
                enabled: internal.microphoneReady && internal.viewState !== "counting" && internal.viewState !== "listening" && internal.viewState !== "analyzing"
                text: Core.exerciseSessionController.isTest ? i18n("Stop Test") : i18n("Start Test")

                onClicked: Core.exerciseSessionController.isTest ? root.stopTest() : root.startTest()
            }
        }
        QQC2.Frame {
            id: rhythmFrame

            Layout.bottomMargin: internal.contentPadding
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: internal.contentPadding
            Layout.rightMargin: internal.contentPadding
            Layout.topMargin: internal.contentPadding
            Onboarding.groups: ["clapping"]
            Onboarding.texts: [i18n("This area shows every rhythm figure. Borders mark correct or missed claps, and timing meters show early or late claps.")]

            Onboarding.onAboutToShow: root.onboardingPreviewActive = true
            Onboarding.onHide: root.onboardingPreviewActive = false

            Flickable {
                id: rhythmViewport

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentHeight: rhythmViewport.height
                contentWidth: rhythmContent.cardsOverflowing ? rhythmRow.implicitWidth + rhythmContent.sideInset * 2 : rhythmViewport.width
                flickableDirection: Flickable.HorizontalFlick

                QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                    id: rhythmHorizontalScrollBar

                    policy: QQC2.ScrollBar.AsNeeded
                }

                onWidthChanged: Qt.callLater(root.centerCurrentFigureCard)

                Item {
                    id: rhythmContent

                    readonly property bool cardsOverflowing: rhythmRow.implicitWidth > rhythmViewport.width
                    readonly property real sideInset: Math.max(0, (rhythmViewport.width - internal.rhythmCardWidth) / 2)

                    height: rhythmViewport.contentHeight
                    width: rhythmViewport.contentWidth

                    Row {
                        id: rhythmRow

                        opacity: root.onboardingCardsHidden ? 0 : 1
                        spacing: Kirigami.Units.smallSpacing
                        x: rhythmContent.cardsOverflowing ? rhythmContent.sideInset : Math.max(0, (rhythmViewport.width - rhythmRow.implicitWidth) / 2)
                        y: Math.round((rhythmContent.height - (rhythmContent.cardsOverflowing ? rhythmHorizontalScrollBar.height : 0) - rhythmRow.implicitHeight) / 2)

                        Repeater {
                            id: rhythmRepeater

                            model: internal.displayedFigureStates

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                color: Kirigami.Theme.backgroundColor
                                height: rhythmColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                                radius: Kirigami.Units.cornerRadius
                                width: internal.rhythmCardWidth

                                border {
                                    color: root.stateBorderColor(modelData.state)
                                    width: modelData.state === "pending" ? 1 : 2
                                }
                                Column {
                                    id: rhythmColumn

                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing
                                    width: parent.width - internal.cardHorizontalPadding

                                    Item {
                                        height: Kirigami.Units.gridUnit * 4
                                        width: parent.width

                                        Text {
                                            id: rhythmText

                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: Kirigami.Theme.textColor
                                            height: implicitHeight
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
                                            verticalAlignment: Text.AlignVCenter
                                            width: Math.max(1, parent.width)
                                            y: Math.round((parent.height - height) / 2 + Math.round(internal.rhythmAnswerCardTextSize * 0.22))

                                            font {
                                                family: bravura.name
                                                pixelSize: internal.rhythmAnswerCardTextSize
                                            }
                                        }
                                    }
                                    GraphicalMeter {
                                        id: timingMeter

                                        accuracy: modelData.meterAccuracy
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        height: implicitHeight
                                        meterKind: "onset"
                                        readoutText: modelData.meterText
                                        value: modelData.meterValue
                                        width: implicitWidth
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        QQC2.Frame {
            Layout.bottomMargin: internal.contentPadding
            Layout.fillWidth: true
            Layout.leftMargin: internal.contentPadding
            Layout.rightMargin: internal.contentPadding

            MicrophoneInputPanel {
                anchors.fill: parent
                calibrationHelpText: i18n("Calibrate silence in a quiet room before clapping so background noise is not counted as input.")
                inputHelpText: i18n("The input level shows microphone activity while you clap. Open means the signal is above the current gate.")
                microphone: internal.microphone
                microphoneReady: internal.microphoneReady
                onboardingGroup: "clapping"

                onCalibrateRequested: {
                    root.applyMicrophoneSettings();
                    if (!internal.microphone.running) {
                        internal.microphone.start();
                    }
                    Qt.callLater(internal.microphone.calibrateNoiseFloor);
                }
            }
        }
    }
}
