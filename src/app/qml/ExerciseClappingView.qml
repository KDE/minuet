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
    readonly property real contentPadding: Kirigami.Units.largeSpacing * 2
    property int countIn: 0
    property bool countInStarted: false
    property string countPhase: "idle"
    property var currentExercise
    property string currentExerciseIconName: ""
    readonly property var displayedFigureStates: root.figureStates.length > 0 ? root.figureStates : root.onboardingPreviewActive ? [
        {
            "state": "pending",
            "onsets": [],
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
    readonly property bool compactMode: !applicationWindow().wideScreen || Kirigami.Settings.isMobile
    property int onboardingCountIn: 0
    property bool onboardingPreviewActive: false
    readonly property real rhythmAnswerCardTextSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.0)
    readonly property real rhythmAnswerCardVerticalOffset: Math.round(rhythmAnswerCardTextSize * 0.22)
    readonly property real rhythmCardWidth: Kirigami.Units.gridUnit * 11
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
        root.countPhase = "idle";
        root.countInStarted = false;
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
    function finishExercise(): void {
        if (root.viewState !== "listening") {
            return;
        }
        progressTimer.stop();
        finishTimer.stop();
        root.countIn = 0;
        root.countPhase = "idle";
        root.countInStarted = false;
        if (Core.soundController) {
            Core.soundController.stop();
        }
        if (root.microphone) {
            root.microphone.stop();
        }
        refreshFigureStates(totalDurationMs() + root.toleranceMs + 1);
        const matched = root.expectedOnsets.filter(onset => onset.matched).length;
        root.score = root.expectedOnsets.length > 0 ? Math.round(matched * 100 / root.expectedOnsets.length) : 0;
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
                    "matched": false
                });
                cursor += durationForToken(part);
            }
            states.push({
                "state": "pending",
                "onsets": figureOnsets,
                "endMs": cursor,
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
        if (bestIndex >= 0 && bestError <= root.toleranceMs) {
            let onsets = root.expectedOnsets.slice();
            onsets[bestIndex].matched = true;
            root.expectedOnsets = onsets;
        }
        if (bestIndex >= 0) {
            let states = root.figureStates.slice();
            const figureIndex = root.expectedOnsets[bestIndex].figure;
            const signedError = elapsedMs - root.expectedOnsets[bestIndex].timeMs;
            states[figureIndex].meterValue = timingMeterValue(signedError);
            states[figureIndex].meterAccuracy = Math.max(0, 1 - Math.abs(signedError) / root.toleranceMs);
            states[figureIndex].meterText = timingMeterText(signedError);
            root.figureStates = states;
        }
        refreshFigureStates(elapsedMs);
    }
    function refreshFigureStates(elapsedMs: real): void {
        let states = root.figureStates.slice();
        for (let i = 0; i < states.length; ++i) {
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
        root.listeningStartSeconds = root.microphone ? root.microphone.analysisTimeSeconds : 0;
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
    Timer {
        id: progressTimer

        interval: 50
        repeat: true

        onTriggered: {
            if (root.microphone && root.microphone.lastOnsetSeconds >= 0) {
                root.refreshFigureStates((root.microphone.lastOnsetSeconds - root.listeningStartSeconds) * 1000);
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
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    source: root.currentExerciseIconName
                    visible: root.currentExerciseIconName.length > 0 && !root.compactMode
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Onboarding.groups: ["clapping"]
                    Onboarding.texts: [i18n("Start a question, listen to the count, then clap each rhythm figure in time.")]
                    spacing: 0

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        level: 2
                        text: root.score >= 0 ? i18n("Score: %1%", root.score) : i18n("Clap the rhythm")
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text: root.viewState === "listening" ? i18n("Listening...") : Core.exerciseSessionController.isTest && Core.exerciseSessionController.statusText.length > 0 ? Core.exerciseSessionController.statusText : root.microphone ? root.microphone.status : i18n("No microphone input plugin available")
                    }
                    RowLayout {
                        id: actionButtons

                        readonly property real buttonWidth: Math.max(startQuestionButton.implicitWidth, testButton.implicitWidth)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Kirigami.Units.smallSpacing
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
            }
        }
        QQC2.Frame {
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
                contentHeight: Math.max(height, rhythmGrid.implicitHeight)
                contentWidth: width

                Item {
                    id: rhythmCenter

                    height: Math.max(rhythmViewport.height, rhythmGrid.implicitHeight)
                    width: rhythmViewport.width

                    GridLayout {
                        id: rhythmGrid

                        readonly property int maximumColumns: Math.max(1, Math.floor((parent.width + columnSpacing) / (root.rhythmCardWidth + columnSpacing)))

                        Onboarding.groups: ["clapping"]
                        Onboarding.texts: [i18n("Each colored card is one rhythm figure. Green borders mark figures clapped correctly; red borders mark missed figures."), i18n("The tempo meter below each figure points left for late claps and right for advanced claps.")]
                        anchors.centerIn: parent
                        columnSpacing: Kirigami.Units.smallSpacing
                        columns: Math.max(1, Math.min(root.displayedFigureStates.length, maximumColumns))
                        rowSpacing: Kirigami.Units.smallSpacing
                        width: Math.min(parent.width, columns * root.rhythmCardWidth + Math.max(0, columns - 1) * columnSpacing)

                        Onboarding.onAboutToShow: root.onboardingPreviewActive = true
                        Onboarding.onHide: root.onboardingPreviewActive = false

                        Repeater {
                            model: root.displayedFigureStates

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                Layout.preferredHeight: rhythmColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                                Layout.preferredWidth: root.rhythmCardWidth
                                color: Kirigami.Theme.backgroundColor
                                radius: Kirigami.Units.cornerRadius

                                border {
                                    color: root.stateBorderColor(modelData.state)
                                    width: modelData.state === "pending" ? 1 : 2
                                }
                                Column {
                                    id: rhythmColumn

                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing

                                    Item {
                                        height: Kirigami.Units.gridUnit * 4
                                        width: parent.parent.width - Kirigami.Units.largeSpacing * 2

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
                                        width: Math.min(Kirigami.Units.gridUnit * 8, parent.parent.width - Kirigami.Units.largeSpacing * 2)
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
                    accentColor: root.microphone && root.microphone.inputGateOpen ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                    label: i18n("Input level")
                    value: root.microphone ? Math.min(1, root.microphone.audioLevel * 12) : 0
                    valueText: root.microphone && root.microphone.inputGateOpen ? i18n("Open") : i18n("Closed")
                }
                QQC2.Button {
                    enabled: root.microphone !== null
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
