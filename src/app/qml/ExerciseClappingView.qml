// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.onboarding

Item {
    id: root

    readonly property real beatMs: 60000 / Core.settingsController.exerciseSpeed
    readonly property real cardHorizontalPadding: Kirigami.Units.largeSpacing * 2
    readonly property bool compactMode: !applicationWindow().wideScreen || Kirigami.Settings.isMobile
    readonly property real contentPadding: Kirigami.Units.largeSpacing * 2
    property int countIn: 0
    property int countInOverlayAnchorIndex: -1
    readonly property real countInOverlayGap: Kirigami.Units.smallSpacing
    readonly property bool countInOverlayInitial: root.countPhase === "preparation"
    readonly property real countInOverlaySize: Math.ceil(onsetMeterProbe.implicitWidth)
    readonly property real countInOverlayX: root.countInOverlayTargetX()
    readonly property real countInOverlayY: root.countInOverlayTargetY()
    property bool countInStarted: false
    property string countPhase: "idle"
    property var currentExercise
    property string currentExerciseIconName: ""
    readonly property var displayedFigureStates: root.figureStates.length > 0 ? root.figureStates : root.onboardingPreviewActive ? [
        {
            "state": "pending",
            "onsets": [],
            "startMs": 0,
            "endMs": root.beatMs,
            "name": "\uE1F0",
            "meterValue": 0,
            "meterAccuracy": 0,
            "meterText": i18n("Ready")
        }
    ] : []
    property var expectedOnsets: []
    property var figureStates: []
    property real listeningStartSeconds: -1
    property var matchedOnsets: []
    readonly property int maximumExercises: Core.settingsController.testExerciseCount
    readonly property var microphone: Core.microphoneInputController
    property int onboardingCountIn: 0
    property bool onboardingPreviewActive: false
    readonly property real rhythmAnswerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.0)
    readonly property real rhythmAnswerCardVerticalOffset: Math.round(rhythmAnswerCardTextSize * 0.22)
    readonly property real rhythmCardWidth: Math.ceil(Math.max(Kirigami.Units.gridUnit * 4, onsetMeterProbe.implicitWidth) + root.cardHorizontalPadding)
    property int score: -1
    readonly property int selectedOptionCount: Core.settingsController.rhythmPatternCount
    property int testScoreTotal: 0
    readonly property real toleranceMs: Math.min(180, beatMs * Core.settingsController.clappingCorrectnessTolerancePercent / 100)
    property string viewState: "idle"

    function applyMicrophoneSettings(): void {
        if (!root.microphone) {
            return;
        }
        root.microphone.preset = IMicrophoneInputController.Clapping;
        root.microphone.pitchMethod = Core.settingsController.clappingPitchMethod;
        root.microphone.onsetMethod = Core.settingsController.clappingOnsetMethod;
        root.microphone.minimumPitchConfidence = Core.settingsController.clappingMinimumPitchConfidence;
        root.microphone.pitchSilenceDb = Core.settingsController.clappingPitchSilenceDb;
        root.microphone.onsetThreshold = Core.settingsController.clappingOnsetThreshold;
        root.microphone.inputGateLevel = Core.settingsController.clappingInputGateLevel;
        root.microphone.minimumOnsetStrength = Core.settingsController.clappingMinimumOnsetStrength;
        root.microphone.requiredStablePitchFrames = Core.settingsController.clappingRequiredStablePitchFrames;
        root.microphone.targetBpm = Core.settingsController.exerciseSpeed;
    }
    function beginMicrophoneCapture(): void {
        if (!root.microphone) {
            return;
        }
        root.microphone.stop();
        root.microphone.start();
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
        progressTimer.stop();
        finishTimer.stop();
        if (root.microphone) {
            root.microphone.stop();
        }
        if (Core.soundController) {
            Core.soundController.stop();
        }
        root.countIn = 0;
        root.countInOverlayAnchorIndex = -1;
        root.countPhase = "idle";
        root.countInStarted = false;
    }
    function countInOverlayTargetX(): real {
        if (root.countPhase !== "input") {
            return root.clampCountInOverlayX(root.rhythmRowCenterX() - root.countInOverlaySize / 2);
        }
        const cardIndex = Math.max(0, Math.min(root.displayedFigureStates.length - 1, root.countInOverlayAnchorIndex));
        return root.clampCountInOverlayX(root.rhythmCardCenterX(cardIndex) - root.countInOverlaySize / 2);
    }
    function countInOverlayTargetY(): real {
        const cardY = rhythmFrame.y + rhythmViewport.y + rhythmRow.y;
        return root.clampCountInOverlayY(cardY - root.countInOverlaySize - root.countInOverlayGap);
    }
    function durationForToken(token: string): real {
        let note = token;
        let dotted = 1.0;
        if (note.endsWith(".")) {
            dotted = 1.5;
            note = note.slice(0, -1);
        }
        const denominator = parseInt(note);
        if (!isFinite(denominator) || denominator <= 0) {
            return 0;
        }
        return dotted * root.beatMs * 4 / denominator;
    }
    function expectedIntervalMatches(expectedIndex: int, elapsedMs: real): bool {
        if (expectedIndex <= 0) {
            return true;
        }

        const previous = root.expectedOnsets[expectedIndex - 1];
        if (!previous.matched || previous.matchedTimeMs < 0) {
            return true;
        }

        const expectedInterval = root.expectedOnsets[expectedIndex].timeMs - previous.timeMs;
        const actualInterval = elapsedMs - previous.matchedTimeMs;
        return Math.abs(actualInterval - expectedInterval) <= root.toleranceMs;
    }
    function figureIndexForElapsed(elapsedMs: real): int {
        if (elapsedMs < -root.toleranceMs || elapsedMs > totalDurationMs() + root.toleranceMs) {
            return -1;
        }
        for (let i = 0; i < root.figureStates.length; ++i) {
            if (elapsedMs >= root.figureStates[i].startMs && elapsedMs < root.figureStates[i].endMs) {
                return i;
            }
        }
        let closestIndex = -1;
        let closestDistance = Number.MAX_VALUE;
        for (let i = 0; i < root.figureStates.length; ++i) {
            const distance = Math.min(Math.abs(elapsedMs - root.figureStates[i].startMs), Math.abs(elapsedMs - root.figureStates[i].endMs));
            if (distance <= root.toleranceMs && distance < closestDistance) {
                closestDistance = distance;
                closestIndex = i;
            }
        }
        return closestIndex;
    }
    function finishExercise(): void {
        if (root.viewState !== "listening") {
            return;
        }
        progressTimer.stop();
        finishTimer.stop();
        root.countIn = 0;
        root.countInOverlayAnchorIndex = -1;
        root.countPhase = "idle";
        root.countInStarted = false;
        if (Core.soundController) {
            Core.soundController.stop();
        }
        if (root.microphone) {
            root.microphone.stop();
        }
        const finalStates = refreshFigureStates(totalDurationMs() + root.toleranceMs + 1);
        const correct = finalStates.filter(state => state.state === "correct").length;
        root.score = finalStates.length > 0 ? Math.round(correct * 100 / finalStates.length) : 0;
        root.viewState = "finished";
        finishScoredQuestion();
    }
    function finishScoredQuestion(): void {
        if (!Core.exerciseSessionController.isTest) {
            return;
        }

        root.testScoreTotal += Math.max(0, root.score);
        if (Core.exerciseSessionController.currentExercise >= root.maximumExercises) {
            root.score = Math.round(root.testScoreTotal / root.maximumExercises);
            root.testScoreTotal = 0;
            Core.exerciseSessionController.resetTest();
        } else {
            testNextQuestionTimer.restart();
        }
    }
    function generateQuestion(): void {
        Core.exerciseSessionController.beginQuestion(Core.settingsController.testExerciseCount);
        Core.exerciseSessionController.randomlySelectExerciseOptions(root.selectedOptionCount);
        const selected = Core.exerciseSessionController.selectedExerciseOptions;
        let onsetList = [];
        let states = [];
        let cursor = 0;
        for (let figureIndex = 0; figureIndex < selected.length; ++figureIndex) {
            const parts = selected[figureIndex].sequence.split(" ").filter(part => part.length > 0);
            let figureOnsets = [];
            const figureStart = cursor;
            for (const part of parts) {
                figureOnsets.push(onsetList.length);
                onsetList.push({
                    "figure": figureIndex,
                    "timeMs": cursor,
                    "matched": false,
                    "matchedTimeMs": -1
                });
                cursor += durationForToken(part);
            }
            states.push({
                "state": "pending",
                "onsets": figureOnsets,
                "startMs": figureStart,
                "endMs": cursor,
                "extraInputCount": 0,
                "name": selected[figureIndex].name,
                "meterValue": 0,
                "meterAccuracy": 0,
                "meterText": i18n("Ready")
            });
        }
        root.expectedOnsets = onsetList;
        root.figureStates = states;
        root.matchedOnsets = [];
        root.score = -1;
        root.viewState = "ready";
        Core.exerciseSessionController.finishQuestionGeneration();
    }
    function handleOnset(seconds: real): void {
        if (root.viewState !== "listening") {
            return;
        }
        const elapsedMs = (seconds - root.listeningStartSeconds) * 1000;
        let bestIndex = -1;
        let bestError = Number.MAX_VALUE;
        for (let i = 0; i < root.expectedOnsets.length; ++i) {
            if (root.expectedOnsets[i].matched) {
                continue;
            }
            const error = Math.abs(root.expectedOnsets[i].timeMs - elapsedMs);
            if (error < bestError) {
                bestError = error;
                bestIndex = i;
            }
        }
        const matchedExpected = bestIndex >= 0 && bestError <= root.toleranceMs && expectedIntervalMatches(bestIndex, elapsedMs);
        if (matchedExpected) {
            let onsets = root.expectedOnsets.slice();
            onsets[bestIndex].matched = true;
            onsets[bestIndex].matchedTimeMs = elapsedMs;
            root.expectedOnsets = onsets;
        }
        let states = root.figureStates.slice();
        const figureIndex = matchedExpected ? root.expectedOnsets[bestIndex].figure : figureIndexForElapsed(elapsedMs);
        if (figureIndex >= 0) {
            const signedError = matchedExpected ? elapsedMs - root.expectedOnsets[bestIndex].timeMs : elapsedMs - root.figureStates[figureIndex].startMs;
            states[figureIndex].meterValue = timingMeterValue(signedError);
            states[figureIndex].meterAccuracy = Math.max(0, 1 - Math.abs(signedError) / root.toleranceMs);
            states[figureIndex].meterText = timingMeterText(signedError);
            if (!matchedExpected) {
                states[figureIndex].extraInputCount += 1;
                states[figureIndex].state = "wrong";
            }
            root.figureStates = states;
        }
        refreshFigureStates(elapsedMs);
    }
    function mapRhythmRowX(localX: real): real {
        const geometryDependency = rhythmFrame.x + rhythmViewport.x + rhythmViewport.contentX + rhythmContent.x + rhythmRow.x + rhythmRow.implicitWidth;
        return rhythmRow.mapToItem(root, localX + geometryDependency * 0, 0).x;
    }
    function minimumExpectedOnsetIntervalMs(): real {
        if (root.expectedOnsets.length < 2) {
            return root.beatMs;
        }
        let minimumInterval = Number.MAX_VALUE;
        for (let i = 1; i < root.expectedOnsets.length; ++i) {
            const interval = root.expectedOnsets[i].timeMs - root.expectedOnsets[i - 1].timeMs;
            if (interval > 0 && interval < minimumInterval) {
                minimumInterval = interval;
            }
        }
        return minimumInterval < Number.MAX_VALUE ? minimumInterval : root.beatMs;
    }
    function nearestExpectedErrorForFigure(figureIndex: int, elapsedMs: real): real {
        const figure = root.figureStates[figureIndex];
        if (!figure || figure.onsets.length === 0) {
            return elapsedMs - (figure ? figure.startMs : 0);
        }

        let bestError = elapsedMs - root.expectedOnsets[figure.onsets[0]].timeMs;
        for (const onsetIndex of figure.onsets) {
            const error = elapsedMs - root.expectedOnsets[onsetIndex].timeMs;
            if (Math.abs(error) < Math.abs(bestError)) {
                bestError = error;
            }
        }
        return bestError;
    }
    function refreshFigureStates(elapsedMs: real): var {
        let states = root.figureStates.slice();
        for (let i = 0; i < states.length; ++i) {
            if (states[i].state === "wrong") {
                continue;
            }
            const allMatched = states[i].onsets.every(index => root.expectedOnsets[index].matched);
            if (allMatched) {
                states[i].state = "correct";
            } else if (elapsedMs > states[i].endMs + root.toleranceMs) {
                states[i].state = "wrong";
                if (states[i].meterText === i18n("Ready")) {
                    states[i].meterText = i18n("Missed");
                    states[i].meterAccuracy = 0;
                    states[i].meterValue = 0;
                }
            }
        }
        root.figureStates = states;
        return states;
    }
    function rhythmCardCenterX(index: int): real {
        return root.mapRhythmRowX(index * (root.rhythmCardWidth + rhythmRow.spacing) + root.rhythmCardWidth / 2);
    }
    function rhythmRowCenterX(): real {
        if (root.displayedFigureStates.length <= 0) {
            return rhythmFrame.x + rhythmViewport.x + rhythmViewport.width / 2;
        }
        return root.mapRhythmRowX(rhythmRow.implicitWidth / 2);
    }
    function startExercise(): void {
        if (root.currentExercise === undefined || root.viewState === "counting" || root.viewState === "listening") {
            return;
        }
        if (root.expectedOnsets.length === 0) {
            generateQuestion();
        }
        applyMicrophoneSettings();
        root.countPhase = "preparation";
        root.countInStarted = false;
        root.countIn = 0;
        root.countInOverlayAnchorIndex = -1;
        root.viewState = "counting";
        if (Core.soundController) {
            Core.soundController.playCountIn(root.selectedOptionCount);
        }
    }
    function startListening(): void {
        if (root.microphone && !root.microphone.running) {
            beginMicrophoneCapture();
        }
        root.countPhase = "input";
        root.countInStarted = false;
        root.countIn = 0;
        root.countInOverlayAnchorIndex = 0;
        root.inputTimingArmed = true;
        root.inputTimingStarted = false;
        root.listeningStartSeconds = -1;
        root.performedOnsets = [];
        root.viewState = "listening";
        if (Core.soundController) {
            Core.soundController.playCountIn(root.selectedOptionCount);
        }
        progressTimer.restart();
        finishTimer.interval = totalDurationMs() + root.toleranceMs + root.beatMs;
        finishTimer.restart();
    }
    function startTest(): void {
        Core.exerciseSessionController.startTest();
        root.testScoreTotal = 0;
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
    function stopTest(): void {
        testNextQuestionTimer.stop();
        clearCurrentRun();
        root.testScoreTotal = 0;
        Core.exerciseSessionController.stopTest();
        root.viewState = root.expectedOnsets.length > 0 ? "ready" : "idle";
    }
    function timingMeterText(errorMs: real): string {
        if (Math.abs(errorMs) < 1) {
            return i18n("On time");
        }
        return i18n("%1 ms").arg(Math.round(errorMs));
    }
    function timingMeterValue(errorMs: real): real {
        return -Math.max(-1, Math.min(1, errorMs / root.toleranceMs));
    }
    function totalDurationMs(): real {
        if (root.figureStates.length === 0) {
            return 0;
        }
        return root.figureStates[root.figureStates.length - 1].endMs;
    }

    visible: root.currentExercise !== undefined

    onCurrentExerciseChanged: {
        testNextQuestionTimer.stop();
        clearCurrentRun();
        root.expectedOnsets = [];
        root.figureStates = [];
        root.score = -1;
        root.testScoreTotal = 0;
        root.viewState = "idle";
        if (root.currentExercise !== undefined) {
            Core.exerciseSessionController.resetForExercise();
        }
    }

    FontLoader {
        id: bravura

        source: "SheetMusicView/Bravura.otf"
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
            if (root.viewState === "listening" && root.microphone) {
                root.refreshFigureStates(Math.max(0, (root.microphone.analysisTimeSeconds - root.listeningStartSeconds) * 1000));
            }
        }
    }
    Timer {
        id: finishTimer

        onTriggered: root.finishExercise()
    }
    Timer {
        id: testNextQuestionTimer

        interval: root.beatMs

        onTriggered: {
            root.generateQuestion();
            root.startExercise();
        }
    }
    Connections {
        function onOnsetDetected(seconds: real, strength: real): void {
            root.handleOnset(seconds);
        }

        target: root.microphone
    }
    Connections {
        function onCountInChanged(count: int): void {
            if (root.currentExercise === undefined) {
                return;
            }
            if (root.countPhase === "preparation") {
                root.countIn = count;
                if (count > 0) {
                    root.countInStarted = true;
                }
                if (count >= root.selectedOptionCount) {
                    root.beginMicrophoneCapture();
                } else if (count === 0 && root.countInStarted) {
                    root.startListening();
                }
            } else if (root.countPhase === "input") {
                if (count > 0) {
                    root.countInOverlayAnchorIndex = Math.max(0, Math.min(root.displayedFigureStates.length - 1, count - 1));
                }
                root.countIn = count;
            }
        }

        target: Core.soundController
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: headerLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
            color: Kirigami.Theme.alternateBackgroundColor

            RowLayout {
                id: headerLayout

                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    id: exerciseIcon

                    readonly property real sideLength: visible ? headerCenter.implicitHeight : 0

                    Layout.preferredHeight: exerciseIcon.sideLength * 0.75
                    Layout.preferredWidth: exerciseIcon.sideLength
                    source: root.currentExerciseIconName
                    visible: root.currentExerciseIconName.length > 0 && !root.compactMode
                }
                ColumnLayout {
                    id: headerCenter

                    Layout.fillWidth: true
                    Onboarding.groups: ["clapping"]
                    Onboarding.texts: [i18n("The header shows the exercise status and score while you prepare, listen, clap, and review the result.")]
                    spacing: 0

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        level: 3
                        text: root.score >= 0 ? i18n("Score: %1%", root.score) : i18n("Clap the rhythm")
                    }
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        level: 3
                        text: root.viewState === "listening" ? i18n("Listening...") : Core.exerciseSessionController.isTest && Core.exerciseSessionController.statusText.length > 0 ? Core.exerciseSessionController.statusText : root.microphone ? root.microphone.status : i18n("No microphone input plugin available")
                    }
                    RowLayout {
                        id: actionButtons

                        readonly property real buttonWidth: Math.max(startQuestionButton.implicitWidth, testButton.implicitWidth)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Onboarding.groups: ["clapping"]
                        Onboarding.texts: [i18n("Start a single clapping question or begin a test with several questions in a row.")]
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Button {
                            id: startQuestionButton

                            Layout.preferredWidth: actionButtons.buttonWidth
                            enabled: root.microphone !== null && root.viewState !== "counting" && root.viewState !== "listening"
                            text: root.expectedOnsets.length === 0 || root.viewState === "finished" ? i18n("New Question") : i18n("Start")

                            onClicked: {
                                if (root.expectedOnsets.length === 0 || root.viewState === "finished") {
                                    root.generateQuestion();
                                }
                                root.startExercise();
                            }
                        }
                        QQC2.Button {
                            id: testButton

                            Layout.preferredWidth: actionButtons.buttonWidth
                            enabled: root.microphone !== null && root.viewState !== "counting" && root.viewState !== "listening"
                            text: Core.exerciseSessionController.isTest ? i18n("Stop Test") : i18n("Start Test")

                            onClicked: {
                                if (Core.exerciseSessionController.isTest) {
                                    root.stopTest();
                                } else {
                                    root.startTest();
                                }
                            }
                        }
                    }
                }
                Item {
                    Layout.preferredHeight: 1
                    Layout.preferredWidth: exerciseIcon.sideLength
                    visible: exerciseIcon.visible
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
        QQC2.Frame {
            id: rhythmFrame

            Layout.bottomMargin: root.contentPadding
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: root.contentPadding
            Layout.rightMargin: root.contentPadding
            Layout.topMargin: root.contentPadding

            Flickable {
                id: rhythmViewport

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentHeight: Math.max(height, rhythmRow.implicitHeight + root.countInOverlaySize + root.countInOverlayGap * 2)
                contentWidth: Math.max(width, rhythmRow.implicitWidth)
                flickableDirection: Flickable.HorizontalFlick

                QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                    policy: QQC2.ScrollBar.AsNeeded
                }

                Item {
                    id: rhythmContent

                    readonly property real centeredInset: Math.max(0, (rhythmViewport.width - rhythmRow.implicitWidth) / 2)
                    readonly property real countInTopInset: root.countInOverlaySize + root.countInOverlayGap

                    height: rhythmViewport.contentHeight
                    width: rhythmViewport.contentWidth

                    Row {
                        id: rhythmRow

                        Onboarding.groups: ["clapping"]
                        Onboarding.texts: [i18n("Each colored card is one rhythm figure. Green borders mark figures clapped correctly; red borders mark missed figures."), i18n("The onset meter below each figure lights below the center for advanced claps and above the center for late claps.")]
                        spacing: Kirigami.Units.smallSpacing
                        x: rhythmContent.centeredInset
                        y: Math.max(rhythmContent.countInTopInset, Math.round((rhythmContent.height - rhythmRow.implicitHeight) / 2))

                        Onboarding.onAboutToShow: root.onboardingPreviewActive = true
                        Onboarding.onHide: root.onboardingPreviewActive = false

                        Repeater {
                            id: rhythmRepeater

                            model: root.displayedFigureStates

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                color: Kirigami.Theme.backgroundColor
                                height: rhythmColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                                radius: Kirigami.Units.cornerRadius
                                width: root.rhythmCardWidth

                                border {
                                    color: root.stateBorderColor(modelData.state)
                                    width: modelData.state === "pending" ? 1 : 2
                                }
                                Column {
                                    id: rhythmColumn

                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing
                                    width: parent.width - root.cardHorizontalPadding

                                    Item {
                                        height: Kirigami.Units.gridUnit * 4
                                        width: parent.width

                                        Text {
                                            id: rhythmText

                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: Kirigami.Theme.textColor
                                            font.family: bravura.name
                                            font.pixelSize: root.rhythmAnswerCardTextSize
                                            height: implicitHeight
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.name
                                            verticalAlignment: Text.AlignVCenter
                                            width: Math.max(1, parent.width)
                                            y: Math.round((parent.height - height) / 2 + root.rhythmAnswerCardVerticalOffset)
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
            Layout.bottomMargin: root.contentPadding
            Layout.fillWidth: true
            Layout.leftMargin: root.contentPadding
            Layout.rightMargin: root.contentPadding

            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing

                AccuracyMeter {
                    Layout.fillWidth: true
                    Onboarding.groups: ["clapping"]
                    Onboarding.texts: [i18n("The input level shows microphone activity while you clap. Open means the signal is above the current gate.")]
                    accentColor: root.microphone && root.microphone.inputGateOpen ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                    label: i18n("Input level")
                    value: root.microphone ? Math.min(1, root.microphone.audioLevel * 12) : 0
                    valueText: root.microphone && root.microphone.inputGateOpen ? i18n("Open") : i18n("Closed")
                }
                QQC2.Button {
                    Onboarding.groups: ["clapping"]
                    Onboarding.texts: [i18n("Calibrate silence in a quiet room before clapping so background noise is not counted as input.")]
                    enabled: root.microphoneReady
                    text: root.microphone && root.microphone.noiseCalibrationActive ? i18n("Calibrating...") : i18n("Calibrate Silence")

                    onClicked: {
                        root.applyMicrophoneSettings();
                        if (!root.microphone.running) {
                            root.microphone.start();
                        }
                        Qt.callLater(root.microphone.calibrateNoiseFloor);
                    }
                }
            }
        }
    }
}
