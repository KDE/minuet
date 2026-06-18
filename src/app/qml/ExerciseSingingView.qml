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
    property int currentTargetIndex: 0
    readonly property var displayedTargetStates: root.targetStates.length > 0 ? root.targetStates : root.onboardingPreviewActive ? [
        {
            "midi": root.rootNote > 0 ? root.rootNote : 60,
            "pitchCorrect": false,
            "timingCorrect": !root.scaleExercise,
            "heard": false,
            "pitchValue": 0,
            "pitchAccuracy": 0,
            "pitchText": i18n("No pitch"),
            "onsetValue": 0,
            "onsetAccuracy": 0,
            "onsetText": i18n("No onset")
        }
    ] : []
    property string exerciseName: ""
    property real listeningStartSeconds: -1
    readonly property int maximumExercises: Core.settingsController.testExerciseCount
    readonly property var microphone: Core.microphoneInputController
    readonly property real noteCardWidth: scaleExercise ? Kirigami.Units.gridUnit * 12 : Kirigami.Units.gridUnit * 7
    property int onboardingCountIn: 0
    property bool onboardingPreviewActive: false
    property var onsetHits: []
    property string onsetMeterText: i18n("No onset")
    property real onsetMeterValue: 0
    property string pitchMeterText: i18n("No pitch")
    property real pitchMeterValue: 0
    property int rootNote: 0
    readonly property bool scaleExercise: currentExercise !== undefined && currentExercise["singingExerciseKind"] === "scale"
    property int score: -1
    property var targetNotes: []
    property var targetStates: []
    property int testScoreTotal: 0
    readonly property real timingToleranceMs: Math.min(180, beatMs * Core.settingsController.clappingCorrectnessTolerancePercent / 100)
    property string viewState: "idle"

    function applyMicrophoneSettings(): void {
        if (!root.microphone) {
            return;
        }
        root.microphone.preset = IMicrophoneInputController.Singing;
        root.microphone.voiceClass = Core.settingsController.singingVoiceClass;
        root.microphone.pitchMethod = Core.settingsController.singingPitchMethod;
        root.microphone.onsetMethod = Core.settingsController.singingOnsetMethod;
        root.microphone.minimumPitchConfidence = Core.settingsController.singingMinimumPitchConfidence;
        root.microphone.pitchSilenceDb = Core.settingsController.singingPitchSilenceDb;
        root.microphone.onsetThreshold = Core.settingsController.singingOnsetThreshold;
        root.microphone.inputGateLevel = Core.settingsController.singingInputGateLevel;
        root.microphone.minimumOnsetStrength = Core.settingsController.singingMinimumOnsetStrength;
        root.microphone.requiredStablePitchFrames = Core.settingsController.singingRequiredStablePitchFrames;
        root.microphone.targetBpm = Core.settingsController.exerciseSpeed;
    }
    function beginMicrophoneCapture(): void {
        if (!root.microphone) {
            return;
        }
        root.microphone.stop();
        root.microphone.start();
    }
    function cardColor(index: int): color {
        return internal.colors[index % internal.colors.length];
    }
    function clearCurrentRun(): void {
        listenDelay.stop();
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
    function exerciseConstrainedToVoiceClass(): var {
        let constrainedExercise = {};
        for (const key in root.currentExercise) {
            constrainedExercise[key] = root.currentExercise[key];
        }
        const range = voiceClassPitchRange(Core.settingsController.singingVoiceClass);
        constrainedExercise.targetPitchMin = range.min;
        constrainedExercise.targetPitchMax = range.max;
        return constrainedExercise;
    }
    function expectedIndexForElapsed(elapsedMs: real): int {
        return Math.max(0, Math.min(root.targetNotes.length - 1, Math.floor(elapsedMs / root.beatMs)));
    }
    function finishExercise(): void {
        if (root.viewState !== "listening") {
            return;
        }
        finishTimer.stop();
        if (root.microphone) {
            root.microphone.stop();
        }
        if (Core.soundController) {
            Core.soundController.stop();
        }
        let correct = 0;
        for (const state of root.targetStates) {
            if (state.pitchCorrect && (Core.settingsController.singingScoringMode === 0 || state.timingCorrect)) {
                ++correct;
            }
        }
        root.score = root.targetStates.length > 0 ? Math.round(correct * 100 / root.targetStates.length) : 0;
        root.countIn = 0;
        root.countPhase = "idle";
        root.countInStarted = false;
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
        Core.exerciseSessionController.setActiveExercise(exerciseConstrainedToVoiceClass());
        Core.exerciseSessionController.beginQuestion(Core.settingsController.testExerciseCount);
        Core.exerciseSessionController.randomlySelectExerciseOptions(1);
        const selected = Core.exerciseSessionController.selectedExerciseOptions;
        if (selected.length === 0) {
            return;
        }
        const option = selected[0];
        root.exerciseName = option.name;
        root.rootNote = parseInt(option.rootNote);
        // For interval singing, the root note is played by the app and only the
        // interval note is expected from the singer. For scale exercises, every
        // note in the generated sequence is expected from the singer.
        root.targetNotes = option.sequence.split(" ").filter(part => part.length > 0).map(part => root.rootNote + parseInt(part));
        root.targetStates = root.targetNotes.map(function (note) {
            return {
                "midi": note,
                "pitchCorrect": false,
                "timingCorrect": !root.scaleExercise,
                "heard": false,
                "pitchValue": 0,
                "pitchAccuracy": 0,
                "pitchText": i18n("No pitch"),
                "onsetValue": 0,
                "onsetAccuracy": 0,
                "onsetText": i18n("No onset")
            };
        });
        root.onsetHits = root.targetNotes.map(function () {
            return false;
        });
        root.currentTargetIndex = 0;
        root.score = -1;
        root.pitchMeterValue = 0;
        root.onsetMeterValue = 0;
        root.pitchMeterText = i18n("No pitch");
        root.onsetMeterText = i18n("No onset");
        root.viewState = "ready";
        Core.exerciseSessionController.finishQuestionGeneration();
    }
    function giveUpQuestion(): void {
        if (root.viewState !== "ready") {
            return;
        }
        root.score = 0;
        root.viewState = "finished";
        finishScoredQuestion();
    }
    function handleOnset(seconds: real): void {
        if (root.viewState !== "listening" || !root.scaleExercise) {
            return;
        }
        const elapsedMs = Math.max(0, (seconds - root.listeningStartSeconds) * 1000);
        const nearestIndex = Math.max(0, Math.min(root.targetNotes.length - 1, Math.round(elapsedMs / root.beatMs)));
        const errorMs = elapsedMs - nearestIndex * root.beatMs;
        root.onsetMeterValue = Math.max(0, 1 - Math.abs(errorMs) / root.timingToleranceMs);
        root.onsetMeterText = i18n("%1 ms").arg(Math.round(errorMs));
        let hits = root.onsetHits.slice();
        let states = root.targetStates.slice();
        states[nearestIndex].onsetValue = timingMeterValue(errorMs);
        states[nearestIndex].onsetAccuracy = root.onsetMeterValue;
        states[nearestIndex].onsetText = root.onsetMeterText;
        if (Math.abs(errorMs) <= root.timingToleranceMs) {
            hits[nearestIndex] = true;
            states[nearestIndex].timingCorrect = true;
        }
        root.onsetHits = hits;
        root.targetStates = states;
    }
    function handlePitch(seconds: real, midiNote: int, cents: real, confidence: real): void {
        if (root.viewState !== "listening" || root.targetNotes.length === 0) {
            return;
        }
        const elapsedMs = Math.max(0, (seconds - root.listeningStartSeconds) * 1000);
        const index = expectedIndexForElapsed(elapsedMs);
        root.currentTargetIndex = index;
        const expected = root.targetNotes[index];
        const pitchError = pitchErrorCents(midiNote, cents, expected);
        const absError = Math.abs(pitchError);
        const pitchTolerance = Math.max(1, Core.settingsController.singingPitchToleranceCents);
        root.pitchMeterValue = Math.max(0, 1 - absError / pitchTolerance);
        root.pitchMeterText = i18n("%1 cents").arg(Math.round(pitchError));
        let states = root.targetStates.slice();
        states[index].pitchValue = root.normalizedPitchMeterValue(pitchError);
        states[index].pitchAccuracy = root.pitchMeterValue;
        states[index].pitchText = root.pitchMeterText;
        if (absError <= pitchTolerance) {
            states[index].pitchCorrect = true;
            states[index].heard = true;
        }
        root.targetStates = states;
    }
    function isIntervalExercise(): bool {
        return root.currentExercise !== undefined && root.currentExercise["singingExerciseKind"] === "interval";
    }
    function normalizedPitchMeterValue(pitchError: real): real {
        const pitchTolerance = Math.max(1, Core.settingsController.singingPitchToleranceCents);
        return Math.max(-1, Math.min(1, pitchError / pitchTolerance));
    }
    function noteName(midi: int): string {
        const names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        return names[((midi % 12) + 12) % 12] + (Math.floor(midi / 12) - 1);
    }
    function pitchErrorCents(midiNote: int, cents: real, expected: int): real {
        const rawError = (midiNote - expected) * 100 + cents;
        if (!Core.settingsController.singingDisregardOctaveDifference) {
            return rawError;
        }

        let normalizedError = (rawError + 600) % 1200;
        if (normalizedError < 0) {
            normalizedError += 1200;
        }
        return normalizedError - 600;
    }
    function pitchToleranceCents(): real {
        return Math.max(1, Core.settingsController.singingPitchToleranceCents);
    }
    function playRootAndListen(): void {
        root.countIn = 0;
        root.countPhase = "root";
        root.countInStarted = false;
        if (Core.soundController) {
            Core.soundController.prepareFromExerciseOptions([
                {
                    "rootNote": root.rootNote.toString(),
                    "sequence": ""
                }
            ]);
            Core.soundController.play();
        }
        listenDelay.restart();
    }
    function questionPitchMessage(): string {
        if (root.exerciseName.length === 0 || root.targetNotes.length === 0) {
            return root.microphone ? root.microphone.status : i18n("No microphone input plugin available");
        }

        const base = noteName(root.rootNote);
        const translatedExerciseName = i18nc("technical term, do you have a musician friend?", root.exerciseName);
        if (root.scaleExercise) {
            return i18n("%1 - Base: %2 - Targets: %3", translatedExerciseName, base, root.targetNotes.map(note => noteName(note)).join(", "));
        }
        return i18n("%1 - Base: %2 - Target: %3", translatedExerciseName, base, noteName(root.targetNotes[0]));
    }
    function startExercise(): void {
        if (root.currentExercise === undefined || root.viewState === "counting" || root.viewState === "listening") {
            return;
        }
        if (root.targetNotes.length === 0) {
            generateQuestion();
        }
        applyMicrophoneSettings();
        root.countIn = 0;
        root.countPhase = "preparation";
        root.countInStarted = false;
        root.viewState = "counting";
        if (Core.soundController) {
            Core.soundController.playCountIn(4);
        }
    }
    function startListening(): void {
        if (root.microphone && !root.microphone.running) {
            beginMicrophoneCapture();
        }
        root.listeningStartSeconds = root.microphone ? root.microphone.analysisTimeSeconds : 0;
        root.currentTargetIndex = 0;
        root.countPhase = "input";
        root.countInStarted = false;
        root.viewState = "listening";
        if (Core.soundController) {
            Core.soundController.playCountIn(root.targetNotes.length);
        }
        finishTimer.interval = root.targetNotes.length * root.beatMs + root.beatMs;
        finishTimer.restart();
    }
    function startTest(): void {
        Core.exerciseSessionController.startTest();
        root.testScoreTotal = 0;
        generateQuestion();
        startExercise();
    }
    function stateBorderColor(state: var, index: int): color {
        if (state.pitchCorrect && (Core.settingsController.singingScoringMode === 0 || state.timingCorrect)) {
            return Kirigami.Theme.positiveTextColor;
        }
        if (root.viewState === "finished" || index < root.currentTargetIndex) {
            return Kirigami.Theme.negativeTextColor;
        }
        if (index === root.currentTargetIndex && root.viewState === "listening") {
            return Kirigami.Theme.highlightColor;
        }
        return Kirigami.Theme.textColor;
    }
    function stopTest(): void {
        testNextQuestionTimer.stop();
        clearCurrentRun();
        root.testScoreTotal = 0;
        Core.exerciseSessionController.stopTest();
        root.viewState = root.targetNotes.length > 0 ? "ready" : "idle";
    }
    function timingMeterValue(errorMs: real): real {
        return -Math.max(-1, Math.min(1, errorMs / root.timingToleranceMs));
    }
    function voiceClassPitchRange(voiceClass: int): var {
        switch (voiceClass) {
        case IMicrophoneInputController.Soprano:
            return {
                "min": 60,
                "max": 84
            };
        case IMicrophoneInputController.Alto:
            return {
                "min": 55,
                "max": 77
            };
        case IMicrophoneInputController.Tenor:
            return {
                "min": 48,
                "max": 72
            };
        case IMicrophoneInputController.Bass:
            return {
                "min": 40,
                "max": 64
            };
        }
        return {
            "min": 48,
            "max": 72
        };
    }

    visible: root.currentExercise !== undefined

    onCurrentExerciseChanged: {
        testNextQuestionTimer.stop();
        clearCurrentRun();
        root.targetNotes = [];
        root.targetStates = [];
        root.score = -1;
        root.testScoreTotal = 0;
        root.exerciseName = "";
        root.viewState = "idle";
        if (root.currentExercise !== undefined) {
            Core.exerciseSessionController.resetForExercise();
        }
    }

    QtObject {
        id: internal

        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
    }
    Timer {
        id: listenDelay

        interval: root.beatMs

        onTriggered: root.startListening()
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
        function onPitchDetected(seconds: real, midiNote: int, cents: real, confidence: real): void {
            root.handlePitch(seconds, midiNote, cents, confidence);
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
                if (count >= 4) {
                    root.beginMicrophoneCapture();
                } else if (count === 0 && root.countInStarted) {
                    root.playRootAndListen();
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
                    visible: root.currentExerciseIconName.length > 0
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Onboarding.groups: ["singing"]
                    Onboarding.texts: [i18n("Start a question, listen to the count-in and first note, then sing the displayed interval or scale notes."), i18n("For interval exercises, Minuet plays the first note and you sing the next note shown as the target."), i18n("For scale exercises, Minuet plays the first note and you sing the remaining target notes in order.")]
                    spacing: 0

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        level: 2
                        text: root.score >= 0 ? i18n("Score: %1%", root.score) : root.scaleExercise ? i18n("Sing the scale") : i18n("Sing the interval")
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text: root.questionPitchMessage()
                    }
                    RowLayout {
                        id: actionButtons

                        readonly property real buttonWidth: Math.max(startQuestionButton.implicitWidth, giveUpButton.implicitWidth, testButton.implicitWidth)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Button {
                            id: startQuestionButton

                            Layout.preferredWidth: actionButtons.buttonWidth
                            enabled: root.microphone !== null && root.viewState !== "counting" && root.viewState !== "listening"
                            text: root.targetNotes.length === 0 || root.viewState === "finished" ? i18n("New Question") : i18n("Start")

                            onClicked: {
                                if (root.targetNotes.length === 0 || root.viewState === "finished") {
                                    root.generateQuestion();
                                }
                                root.startExercise();
                            }
                        }
                        QQC2.Button {
                            id: giveUpButton

                            Layout.preferredWidth: actionButtons.buttonWidth
                            enabled: root.targetNotes.length > 0 && root.viewState === "ready"
                            text: i18n("Give Up")

                            onClicked: root.giveUpQuestion()
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
                id: noteViewport

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentHeight: Math.max(height, noteGrid.implicitHeight)
                contentWidth: width

                Item {
                    id: noteCenter

                    height: Math.max(noteViewport.height, noteGrid.implicitHeight)
                    width: noteViewport.width

                    GridLayout {
                        id: noteGrid

                        readonly property int maximumColumns: Math.max(1, Math.floor((parent.width + columnSpacing) / (root.noteCardWidth + columnSpacing)))

                        Onboarding.groups: ["singing"]
                        Onboarding.texts: [i18n("Sing the note cards in order. The current card is highlighted; borders show correctness after detection."), i18n("Pitch meters point left for flat notes and right for sharp notes. Scale exercises also show a tempo meter for each note.")]
                        anchors.centerIn: parent
                        columnSpacing: Kirigami.Units.smallSpacing
                        columns: Math.max(1, Math.min(root.displayedTargetStates.length, maximumColumns))
                        rowSpacing: Kirigami.Units.smallSpacing
                        width: Math.min(parent.width, columns * root.noteCardWidth + Math.max(0, columns - 1) * columnSpacing)

                        Onboarding.onAboutToShow: root.onboardingPreviewActive = true
                        Onboarding.onHide: root.onboardingPreviewActive = false

                        Repeater {
                            model: root.displayedTargetStates

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                Layout.preferredHeight: noteColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                                Layout.preferredWidth: root.noteCardWidth
                                color: root.cardColor(index)
                                radius: Kirigami.Units.cornerRadius

                                border {
                                    color: root.stateBorderColor(modelData, index)
                                    width: index === root.currentTargetIndex && root.viewState === "listening" || root.viewState === "finished" || modelData.pitchCorrect ? 2 : 1
                                }
                                Column {
                                    id: noteColumn

                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing

                                    QQC2.Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: "#202124"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: root.noteName(modelData.midi)
                                        width: parent.parent.width - Kirigami.Units.largeSpacing * 2
                                    }
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: Kirigami.Units.smallSpacing

                                        GraphicalMeter {
                                            accuracy: modelData.pitchAccuracy
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: Kirigami.Units.gridUnit * 5.8
                                            meterKind: "pitch"
                                            readoutText: modelData.pitchText
                                            value: modelData.pitchValue
                                            width: height
                                        }
                                        GraphicalMeter {
                                            accuracy: modelData.onsetAccuracy
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: visible ? Kirigami.Units.gridUnit * 5.8 : 0
                                            meterKind: "onset"
                                            readoutText: modelData.onsetText
                                            value: modelData.onsetValue
                                            visible: root.scaleExercise
                                            width: height
                                        }
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
