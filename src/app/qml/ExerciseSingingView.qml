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

    property int countIn: 0
    property var currentExercise
    property string currentExerciseIconName: ""
    property int onboardingCountIn: 0
    readonly property var microphone: Core.microphoneInputController
    readonly property bool scaleExercise: currentExercise !== undefined && currentExercise["singingExerciseKind"] === "scale"
    readonly property real beatMs: 60000 / Core.settingsController.exerciseSpeed
    readonly property real contentPadding: Kirigami.Units.largeSpacing * 2
    readonly property real noteCardWidth: scaleExercise ? Kirigami.Units.gridUnit * 12 : Kirigami.Units.gridUnit * 7
    readonly property real timingToleranceMs: Math.min(180, beatMs * Core.settingsController.clappingCorrectnessTolerancePercent / 100)
    property var targetNotes: []
    property var targetStates: []
    property int currentTargetIndex: 0
    property string exerciseName: ""
    property int rootNote: 0
    property int score: -1
    property string viewState: "idle"
    property real pitchMeterValue: 0
    property string pitchMeterText: i18n("No pitch")
    property real onsetMeterValue: 0
    property string onsetMeterText: i18n("No onset")
    property real listeningStartSeconds: -1
    property var onsetHits: []

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
    function noteName(midi: int): string {
        const names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        return names[((midi % 12) + 12) % 12] + (Math.floor(midi / 12) - 1);
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
    function pitchToleranceCents(): real {
        return Math.max(1, Core.settingsController.singingPitchToleranceCents);
    }
    function isIntervalExercise(): bool {
        return root.currentExercise !== undefined && root.currentExercise["singingExerciseKind"] === "interval";
    }
    function beginMicrophoneCapture(): void {
        if (!root.microphone) {
            return;
        }
        root.microphone.stop();
        root.microphone.start();
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
    function startExercise(): void {
        if (root.currentExercise === undefined || root.viewState === "counting" || root.viewState === "listening") {
            return;
        }
        if (root.targetNotes.length === 0) {
            generateQuestion();
        }
        applyMicrophoneSettings();
        beginMicrophoneCapture();
        root.countIn = 1;
        root.viewState = "counting";
        if (Core.soundController) {
            Core.soundController.playCountIn(4);
        }
        countTimer.restart();
    }
    function playRootAndListen(): void {
        root.countIn = 0;
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
    function startListening(): void {
        root.listeningStartSeconds = root.microphone ? root.microphone.analysisTimeSeconds : 0;
        root.currentTargetIndex = 0;
        root.viewState = "listening";
        if (Core.soundController) {
            Core.soundController.playCountIn(root.targetNotes.length);
        }
        finishTimer.interval = root.targetNotes.length * root.beatMs + root.beatMs;
        finishTimer.restart();
    }
    function expectedIndexForElapsed(elapsedMs: real): int {
        return Math.max(0, Math.min(root.targetNotes.length - 1, Math.floor(elapsedMs / root.beatMs)));
    }
    function normalizedPitchMeterValue(pitchError: real): real {
        const pitchTolerance = Math.max(1, Core.settingsController.singingPitchToleranceCents);
        return Math.max(-1, Math.min(1, pitchError / pitchTolerance));
    }
    function timingMeterValue(errorMs: real): real {
        return -Math.max(-1, Math.min(1, errorMs / root.timingToleranceMs));
    }
    function handlePitch(seconds: real, midiNote: int, cents: real, confidence: real): void {
        if (root.viewState !== "listening" || root.targetNotes.length === 0) {
            return;
        }
        const elapsedMs = Math.max(0, (seconds - root.listeningStartSeconds) * 1000);
        const index = expectedIndexForElapsed(elapsedMs);
        root.currentTargetIndex = index;
        const expected = root.targetNotes[index];
        const pitchError = (midiNote - expected) * 100 + cents;
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
        root.viewState = "finished";
    }
    function cardColor(index: int): color {
        return internal.colors[index % internal.colors.length];
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

    visible: root.currentExercise !== undefined

    onCurrentExerciseChanged: {
        countTimer.stop();
        listenDelay.stop();
        finishTimer.stop();
        if (root.microphone) {
            root.microphone.stop();
        }
        if (Core.soundController) {
            Core.soundController.stop();
        }
        root.targetNotes = [];
        root.targetStates = [];
        root.countIn = 0;
        root.score = -1;
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
        id: countTimer

        interval: root.beatMs
        repeat: true

        onTriggered: {
            if (root.countIn >= 4) {
                stop();
                root.playRootAndListen();
            } else {
                ++root.countIn;
            }
        }
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
    Connections {
        function onPitchDetected(seconds: real, midiNote: int, cents: real, confidence: real): void {
            root.handlePitch(seconds, midiNote, cents, confidence);
        }
        function onOnsetDetected(seconds: real, strength: real): void {
            root.handleOnset(seconds);
        }

        target: root.microphone
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
                    spacing: 0

                    Onboarding.groups: ["singing"]
                    Onboarding.texts: [i18n("Start a question, listen to the count-in and first note, then sing the displayed interval or scale notes.")]

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
                        text: root.exerciseName.length > 0 ? i18n("%1 - target: %2").arg(i18nc("technical term, do you have a musician friend?", root.exerciseName)).arg(root.viewState === "listening" ? root.noteName(root.targetNotes.length > root.currentTargetIndex ? root.targetNotes[root.currentTargetIndex] : root.rootNote) : root.noteName(root.rootNote)) : root.microphone ? root.microphone.status : i18n("No microphone input plugin available")
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Button {
                            enabled: root.microphone !== null && root.viewState !== "counting" && root.viewState !== "listening"
                            text: root.targetNotes.length === 0 ? i18n("New Question") : i18n("Start")

                            onClicked: {
                                if (root.targetNotes.length === 0 || root.viewState === "finished") {
                                    root.generateQuestion();
                                }
                                root.startExercise();
                            }
                        }
                        QQC2.Button {
                            enabled: root.viewState !== "counting" && root.viewState !== "listening"
                            text: i18n("New Question")

                            onClicked: root.generateQuestion()
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
                        Onboarding.texts: [
                            i18n("Sing the note cards in order. The current card is highlighted; borders show correctness after detection."),
                            i18n("Pitch meters point left for flat notes and right for sharp notes. Scale exercises also show a tempo meter for each note.")
                        ]

                        anchors.centerIn: parent
                        columns: Math.max(1, Math.min(root.targetStates.length, maximumColumns))
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing
                        width: Math.min(parent.width, columns * root.noteCardWidth + Math.max(0, columns - 1) * columnSpacing)

                        Repeater {
                            model: root.targetStates

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                color: root.cardColor(index)
                                Layout.preferredHeight: noteColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                                Layout.preferredWidth: root.noteCardWidth
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
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: Kirigami.Units.gridUnit * 5.8
                                            meterKind: "pitch"
                                            value: modelData.pitchValue
                                            accuracy: modelData.pitchAccuracy
                                            readoutText: modelData.pitchText
                                            width: height
                                        }
                                        GraphicalMeter {
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: visible ? Kirigami.Units.gridUnit * 5.8 : 0
                                            meterKind: "onset"
                                            value: modelData.onsetValue
                                            accuracy: modelData.onsetAccuracy
                                            readoutText: modelData.onsetText
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
