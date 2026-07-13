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
    readonly property real countInOverlaySize: root.meterWidth
    readonly property real countInOverlayX: root.countInOverlayTargetX()
    readonly property real countInOverlayY: root.countInOverlayTargetY()
    property bool countInStarted: false
    property string countPhase: "idle"
    property var currentExercise
    property string currentExerciseIconName: ""
    readonly property bool currentScaleCardCentered: root.scaleExercise && root.viewState === "listening" && root.countPhase === "input"
    property int currentTargetIndex: 0
    readonly property int displayedTargetIndex: root.currentDisplayTargetIndex()
    readonly property var displayedTargetStates: root.displayedTargetStatesModel()
    property string exerciseName: ""
    property int inputTargetIndex: 0
    property real listeningStartSeconds: -1
    readonly property int maximumExercises: Core.settingsController.testExerciseCount
    readonly property real meterSpacing: Kirigami.Units.smallSpacing
    readonly property real meterWidth: Math.ceil(Math.max(pitchMeterProbe.implicitWidth, onsetMeterProbe.implicitWidth))
    readonly property var microphone: Core.microphoneInputController
    readonly property bool microphoneReady: root.microphone !== null && root.microphone.inputDeviceAvailable
    readonly property bool musicViewsTabbed: !applicationWindow().wideScreen && root.height > root.width
    readonly property real noteCardWidth: Math.ceil((root.scaleExercise ? root.meterWidth * 2 + root.meterSpacing : root.meterWidth) + root.cardHorizontalPadding)
    property int onboardingCountIn: 0
    property bool onboardingPreviewActive: false
    property var onsetHits: []
    property string onsetMeterText: i18n("No onset")
    property real onsetMeterValue: 0
    readonly property real pitchCorrectHoldSeconds: Math.min(0.18, Math.max(0.10, root.beatMs * 0.0002))
    property string pitchMeterText: i18n("No pitch")
    property real pitchMeterValue: 0
    readonly property bool referenceCardExercise: currentExercise !== undefined && (currentExercise["singingExerciseKind"] === "interval" || currentExercise["singingExerciseKind"] === "scale")
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
        root.microphone.analysisMode = root.scaleExercise ? IMicrophoneInputController.SingingPitchAndOnset : IMicrophoneInputController.SingingPitchOnly;
        root.microphone.preset = IMicrophoneInputController.Singing;
        root.microphone.voiceClass = Core.settingsController.singingVoiceClass;
        root.microphone.pitchMethod = Core.settingsController.singingPitchMethod;
        root.microphone.onsetMethod = Core.settingsController.singingOnsetMethod;
        root.microphone.minimumPitchConfidence = Core.settingsController.singingMinimumPitchConfidence;
        root.microphone.onsetThreshold = Core.settingsController.singingOnsetThreshold;
        root.microphone.inputGateLevel = Core.settingsController.singingInputGateLevel;
        root.microphone.minimumOnsetStrength = Core.settingsController.singingMinimumOnsetStrength;
        root.microphone.requiredStablePitchFrames = Core.settingsController.singingRequiredStablePitchFrames;
        root.microphone.targetBpm = Core.settingsController.exerciseSpeed;
        root.microphone.disregardOctaveDifference = Core.settingsController.singingDisregardOctaveDifference;
        root.syncExpectedPitchConstraint();
    }
    function beginMicrophoneCapture(): void {
        if (!root.microphone) {
            return;
        }
        root.microphone.stop();
        root.microphone.start();
    }
    function beginScaleInputTiming(): void {
        if (!root.scaleExercise || root.listeningStartSeconds >= 0) {
            return;
        }
        if (root.microphone) {
            root.microphone.resetInputAnalysisState();
        }
        root.listeningStartSeconds = root.microphone ? root.microphone.analysisTimeSeconds : 0;
        progressTimer.restart();
        finishTimer.restart();
    }
    function cardColor(index: int): color {
        return internal.colors[index % internal.colors.length];
    }
    function centerAllTargetCards(): void {
        if (!root.scaleExercise || root.displayedTargetStates.length === 0 || noteViewport.width <= 0) {
            return;
        }

        noteViewport.contentX = Math.max(0, (noteViewport.contentWidth - noteViewport.width) / 2);
    }
    function centerCurrentTargetCard(): void {
        if (!root.scaleExercise || root.displayedTargetStates.length === 0 || noteViewport.width <= 0) {
            return;
        }
        if (!root.currentScaleCardCentered) {
            root.centerAllTargetCards();
            return;
        }

        const cardCenter = noteRow.x + root.displayedTargetIndex * (root.noteCardWidth + noteRow.spacing) + root.noteCardWidth / 2;
        noteViewport.contentX = Math.max(0, Math.min(noteViewport.contentWidth - noteViewport.width, cardCenter - noteViewport.width / 2));
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
        listenDelay.stop();
        finishTimer.stop();
        progressTimer.stop();
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
        root.inputTargetIndex = 0;
    }
    function countInOverlayTargetX(): real {
        if (root.countPhase !== "input" && !(root.referenceCardExercise && root.countPhase === "root")) {
            return root.clampCountInOverlayX(root.noteRowCenterX() - root.countInOverlaySize / 2);
        }

        const lastIndex = Math.max(0, root.displayedTargetStates.length - 1);
        const cardIndex = Math.max(0, Math.min(lastIndex, root.countInOverlayAnchorIndex));
        return root.clampCountInOverlayX(root.noteCardCenterX(cardIndex) - root.countInOverlaySize / 2);
    }
    function countInOverlayTargetY(): real {
        const cardY = noteFrame.y + noteViewport.y + noteRow.y;
        return root.clampCountInOverlayY(cardY - root.countInOverlaySize - root.countInOverlayGap);
    }
    function currentDisplayTargetIndex(): int {
        if (root.referenceCardExercise && root.countPhase === "root") {
            return 0;
        }
        return root.displayIndexForTarget(root.scaleExercise && root.viewState === "listening" && root.countPhase === "input" ? root.inputTargetIndex : root.currentTargetIndex);
    }
    function defaultTargetState(midi: int): var {
        return {
            "midi": midi,
            "reference": false,
            "pitchCorrect": false,
            "pitchWrong": false,
            "timingCorrect": !root.scaleExercise,
            "timingWrong": false,
            "heard": false,
            "pitchCorrectSinceSeconds": -1,
            "pitchWrongSinceSeconds": -1,
            "pitchValue": 0,
            "pitchAccuracy": 0,
            "pitchText": i18n("No pitch"),
            "onsetValue": 0,
            "onsetAccuracy": 0,
            "onsetText": i18n("No onset")
        };
    }
    function displayIndexForTarget(targetIndex: int): int {
        if (!root.referenceCardExercise) {
            return targetIndex;
        }
        return Math.max(0, targetIndex + 1);
    }
    function displayedTargetStatesModel(): var {
        const states = root.targetStates.length > 0 ? root.targetStates : root.onboardingPreviewActive ? [root.defaultTargetState(root.rootNote > 0 ? root.rootNote : 60)] : [];
        if (!root.referenceCardExercise || states.length === 0) {
            return states;
        }

        const referenceState = root.defaultTargetState(root.rootNote > 0 ? root.rootNote : states[0].midi);
        referenceState.reference = true;
        referenceState.timingCorrect = true;
        referenceState.pitchText = i18n("Played");
        referenceState.onsetText = "";
        return [referenceState].concat(states);
    }
    function evaluationIndexForElapsed(elapsedMs: real): int {
        if (root.scaleExercise && root.countPhase === "input") {
            return root.inputTargetIndex;
        }
        return expectedIndexForElapsed(elapsedMs);
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
        progressTimer.stop();
        if (root.microphone) {
            root.microphone.stop();
        }
        if (Core.soundController) {
            Core.soundController.stop();
        }
        const finalElapsedMs = root.scaleExercise ? scaleFinalElapsedMs() : root.targetNotes.length * root.beatMs + root.beatMs;
        const finalStates = refreshTargetStates(finalElapsedMs);
        let correct = 0;
        for (const state of finalStates) {
            if (state.pitchCorrect && (Core.settingsController.singingScoringMode === 0 || state.timingCorrect)) {
                ++correct;
            }
        }
        root.score = root.targetStates.length > 0 ? Math.round(correct * 100 / root.targetStates.length) : 0;
        root.countIn = 0;
        root.countInOverlayAnchorIndex = -1;
        root.countPhase = "idle";
        root.countInStarted = false;
        root.viewState = "finished";
        Qt.callLater(root.centerAllTargetCards);
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
        root.targetStates = root.targetNotes.map(note => root.defaultTargetState(note));
        root.onsetHits = root.targetNotes.map(function () {
            return false;
        });
        root.currentTargetIndex = 0;
        root.score = -1;
        root.pitchMeterValue = 0;
        root.onsetMeterValue = 0;
        root.pitchMeterText = i18n("No pitch");
        root.onsetMeterText = i18n("No onset");
        root.syncExpectedPitchConstraint();
        showReferenceNotes();
        root.viewState = "ready";
        Core.exerciseSessionController.finishQuestionGeneration();
    }
    function handleOnset(seconds: real): void {
        if (root.viewState !== "listening" || !root.scaleExercise || root.listeningStartSeconds < 0) {
            return;
        }
        const elapsedMs = Math.max(0, (seconds - root.listeningStartSeconds) * 1000);
        const roundedIndex = Math.round(elapsedMs / root.beatMs);
        if (roundedIndex < 0 || elapsedMs > Math.max(0, root.targetNotes.length - 1) * root.beatMs + root.timingToleranceMs) {
            return;
        }
        const nearestIndex = Math.min(root.targetNotes.length - 1, roundedIndex);
        const errorMs = elapsedMs - nearestIndex * root.beatMs;
        const slotIndex = Math.max(0, Math.min(root.targetNotes.length - 1, Math.floor(elapsedMs / root.beatMs)));
        const stateIndex = Math.abs(errorMs) <= root.timingToleranceMs ? nearestIndex : slotIndex;

        root.onsetMeterValue = Math.max(0, 1 - Math.abs(errorMs) / root.timingToleranceMs);
        root.onsetMeterText = i18n("%1 ms").arg(Math.round(errorMs));
        let hits = root.onsetHits.slice();
        let states = root.targetStates.slice();
        states[stateIndex].onsetValue = timingMeterValue(errorMs);
        states[stateIndex].onsetAccuracy = root.onsetMeterValue;
        states[stateIndex].onsetText = root.onsetMeterText;
        if (Math.abs(errorMs) <= root.timingToleranceMs && !states[nearestIndex].timingCorrect) {
            hits[nearestIndex] = true;
            states[nearestIndex].timingCorrect = true;
        } else {
            states[stateIndex].timingWrong = true;
        }
        root.onsetHits = hits;
        root.targetStates = states;
        refreshTargetStates(elapsedMs);
    }
    function handlePitch(seconds: real, midiNote: int, cents: real, confidence: real): void {
        if (root.viewState !== "listening" || root.targetNotes.length === 0 || root.listeningStartSeconds < 0) {
            return;
        }
        const elapsedMs = Math.max(0, (seconds - root.listeningStartSeconds) * 1000);
        const index = evaluationIndexForElapsed(elapsedMs);
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
            states[index].pitchWrongSinceSeconds = -1;
            if (states[index].pitchCorrectSinceSeconds < 0) {
                states[index].pitchCorrectSinceSeconds = seconds;
            }
        } else {
            states[index].pitchCorrectSinceSeconds = -1;
            if (states[index].pitchCorrect) {
                if (states[index].pitchWrongSinceSeconds < 0) {
                    states[index].pitchWrongSinceSeconds = seconds;
                }
                if (seconds - states[index].pitchWrongSinceSeconds >= root.pitchCorrectHoldSeconds) {
                    states[index].pitchCorrect = false;
                    states[index].pitchWrong = true;
                    states[index].heard = false;
                }
            }
        }
        if (states[index].pitchCorrectSinceSeconds >= 0 && seconds - states[index].pitchCorrectSinceSeconds >= root.pitchCorrectHoldSeconds) {
            states[index].pitchCorrect = true;
            states[index].pitchWrong = false;
            states[index].heard = true;
            states[index].pitchWrongSinceSeconds = -1;
        }
        root.targetStates = states;
        refreshTargetStates(elapsedMs);
    }
    function isIntervalExercise(): bool {
        return root.currentExercise !== undefined && root.currentExercise["singingExerciseKind"] === "interval";
    }
    function mapNoteRowX(localX: real): real {
        const geometryDependency = noteFrame.x + noteViewport.x + noteViewport.contentX + noteContent.x + noteRow.x + noteRow.implicitWidth;
        return noteRow.mapToItem(root, localX + geometryDependency * 0, 0).x;
    }
    function normalizedPitchMeterValue(pitchError: real): real {
        const pitchTolerance = Math.max(1, Core.settingsController.singingPitchToleranceCents);
        return Math.max(-1, Math.min(1, pitchError / pitchTolerance));
    }
    function noteCardCenterX(index: int): real {
        return root.mapNoteRowX(index * (root.noteCardWidth + noteRow.spacing) + root.noteCardWidth / 2);
    }
    function noteName(midi: int): string {
        const names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        return names[((midi % 12) + 12) % 12] + (Math.floor(midi / 12) - 1);
    }
    function noteRowCenterX(): real {
        if (root.displayedTargetStates.length <= 0) {
            return noteFrame.x + noteViewport.x + noteViewport.width / 2;
        }
        return root.mapNoteRowX(noteRow.implicitWidth / 2);
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
    function pitchSlotEndMs(index: int): real {
        if (!root.scaleExercise) {
            return root.targetNotes.length * root.beatMs + root.beatMs;
        }
        if (index < root.targetNotes.length - 1) {
            return (index + 1) * root.beatMs;
        }
        return scaleFinalElapsedMs();
    }
    function pitchToleranceCents(): real {
        return Math.max(1, Core.settingsController.singingPitchToleranceCents);
    }
    function playRootAndListen(): void {
        root.countIn = root.referenceCardExercise ? 1 : 0;
        root.countInOverlayAnchorIndex = root.referenceCardExercise ? 0 : -1;
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
            if (!root.microphone) {
                return i18n("No microphone input plugin available");
            }
            if (!root.microphone.inputDeviceAvailable) {
                return i18n("No microphone input devices found");
            }
            return root.microphone.status;
        }

        const base = noteName(root.rootNote);
        const translatedExerciseName = i18nc("technical term, do you have a musician friend?", root.exerciseName);
        if (root.scaleExercise) {
            return i18n("%1 - Base: %2 - Targets: %3", translatedExerciseName, base, root.targetNotes.map(note => noteName(note)).join(", "));
        }
        return i18n("%1 - Base: %2 - Target: %3", translatedExerciseName, base, noteName(root.targetNotes[0]));
    }
    function referenceNotes(): var {
        if (root.rootNote <= 0 || root.targetNotes.length === 0) {
            return [];
        }
        return [root.rootNote].concat(root.targetNotes);
    }
    function refreshTargetStates(elapsedMs: real): var {
        let states = root.targetStates.slice();
        for (let i = 0; i < states.length; ++i) {
            if (!states[i].pitchCorrect && elapsedMs > pitchSlotEndMs(i)) {
                states[i].pitchWrong = true;
            }
            if (root.scaleExercise && !states[i].timingCorrect && elapsedMs > i * root.beatMs + root.timingToleranceMs) {
                states[i].timingWrong = true;
                if (states[i].onsetText === i18n("No onset")) {
                    states[i].onsetText = i18n("Missed");
                    states[i].onsetAccuracy = 0;
                    states[i].onsetValue = 0;
                }
            }
        }
        root.targetStates = states;
        return states;
    }
    function scaleFinalElapsedMs(): real {
        return root.targetNotes.length * root.beatMs + Math.max(root.timingToleranceMs, root.pitchCorrectHoldSeconds * 1000);
    }
    function showReferenceNotes(): void {
        if (pianoView === null || sheetMusicView === null) {
            return;
        }

        const notes = referenceNotes();
        pianoView.clearAllMarks();
        sheetMusicView.clearAllMarks();
        if (notes.length === 0) {
            return;
        }

        pianoView.noteMark(0, root.rootNote, 0, "white");
        for (let i = 0; i < root.targetNotes.length; ++i) {
            pianoView.noteMark(0, root.targetNotes[i], 0, root.cardColor(i));
        }
        pianoView.scrollToMarkedKeys();
        sheetMusicView.model = notes;
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
        root.countInOverlayAnchorIndex = -1;
        root.viewState = "counting";
        if (Core.soundController) {
            Core.soundController.playCountIn(4);
        }
        root.centerAllTargetCards();
    }
    function startListening(): void {
        if (root.microphone && !root.microphone.running) {
            beginMicrophoneCapture();
        }
        root.currentTargetIndex = 0;
        root.inputTargetIndex = 0;
        root.countInOverlayAnchorIndex = root.referenceCardExercise ? 1 : 0;
        root.syncExpectedPitchConstraint();
        root.countIn = root.isIntervalExercise() ? 2 : 0;
        root.countPhase = "input";
        root.countInStarted = false;
        root.viewState = "listening";
        if (root.scaleExercise) {
            root.listeningStartSeconds = -1;
        } else {
            if (root.microphone) {
                root.microphone.resetInputAnalysisState();
            }
            root.listeningStartSeconds = root.microphone ? root.microphone.analysisTimeSeconds : 0;
        }
        finishTimer.interval = root.scaleExercise ? scaleFinalElapsedMs() : root.targetNotes.length * root.beatMs + root.beatMs;
        if (Core.soundController && root.scaleExercise) {
            Core.soundController.playSilentCountIn(root.targetNotes.length);
        } else if (root.scaleExercise) {
            root.beginScaleInputTiming();
        }
        if (!root.scaleExercise) {
            progressTimer.restart();
            finishTimer.restart();
        }
    }
    function startTest(): void {
        Core.exerciseSessionController.startTest();
        root.testScoreTotal = 0;
        generateQuestion();
        startExercise();
    }
    function stateBorderColor(state: var, index: int): color {
        if (state.reference) {
            if (index === root.displayedTargetIndex && (root.countPhase === "root" || root.viewState === "listening")) {
                return Kirigami.Theme.highlightColor;
            }
            return Kirigami.Theme.textColor;
        }
        if (state.pitchCorrect && (Core.settingsController.singingScoringMode === 0 || state.timingCorrect)) {
            return Kirigami.Theme.positiveTextColor;
        }
        if (state.pitchWrong || (Core.settingsController.singingScoringMode !== 0 && state.timingWrong) || root.viewState === "finished") {
            return Kirigami.Theme.negativeTextColor;
        }
        if (index === root.displayedTargetIndex && root.viewState === "listening") {
            return Kirigami.Theme.highlightColor;
        }
        return Kirigami.Theme.textColor;
    }
    function stateBorderWidth(state: var, index: int): int {
        if (state.reference) {
            return index === root.displayedTargetIndex && (root.countPhase === "root" || root.viewState === "listening") ? 2 : 1;
        }
        return (index === root.displayedTargetIndex && root.viewState === "listening") || root.viewState === "finished" || state.pitchCorrect ? 2 : 1;
    }
    function stopTest(): void {
        testNextQuestionTimer.stop();
        clearCurrentRun();
        root.testScoreTotal = 0;
        Core.exerciseSessionController.stopTest();
        root.viewState = root.targetNotes.length > 0 ? "ready" : "idle";
    }
    function syncExpectedPitchConstraint(): void {
        if (!root.microphone || root.targetNotes.length === 0) {
            return;
        }
        const index = Math.max(0, Math.min(root.targetNotes.length - 1, root.scaleExercise && root.countPhase === "input" ? root.inputTargetIndex : root.currentTargetIndex));
        root.microphone.expectedMidiNote = root.targetNotes[index];
        root.microphone.disregardOctaveDifference = Core.settingsController.singingDisregardOctaveDifference;
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
        pianoView.clearAllMarks();
        sheetMusicView.clearAllMarks();
        if (root.currentExercise !== undefined) {
            Core.exerciseSessionController.resetForExercise();
            Qt.callLater(root.generateQuestion);
        }
    }
    onCurrentTargetIndexChanged: Qt.callLater(root.centerCurrentTargetCard)
    onDisplayedTargetIndexChanged: Qt.callLater(root.centerCurrentTargetCard)
    onInputTargetIndexChanged: root.centerCurrentTargetCard()
    onTargetStatesChanged: root.viewState === "finished" ? Qt.callLater(root.centerAllTargetCards) : Qt.callLater(root.centerCurrentTargetCard)

    QtObject {
        id: internal

        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
    }
    GraphicalMeter {
        id: pitchMeterProbe

        meterKind: "pitch"
        visible: false
    }
    GraphicalMeter {
        id: onsetMeterProbe

        meterKind: "onset"
        visible: false
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
        id: progressTimer

        interval: 50
        repeat: true

        onTriggered: {
            if (root.viewState === "listening" && root.microphone && root.listeningStartSeconds >= 0) {
                root.refreshTargetStates(Math.max(0, (root.microphone.analysisTimeSeconds - root.listeningStartSeconds) * 1000));
            }
        }
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
                if (root.scaleExercise && count > 0) {
                    root.countInStarted = true;
                    root.inputTargetIndex = Math.max(0, Math.min(root.targetNotes.length - 1, count - 1));
                    root.currentTargetIndex = root.inputTargetIndex;
                    root.countInOverlayAnchorIndex = root.inputTargetIndex + 1;
                    root.syncExpectedPitchConstraint();
                    root.beginScaleInputTiming();
                    root.countIn = count + 1;
                    root.centerCurrentTargetCard();
                } else {
                    root.countIn = count;
                }
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
                    Onboarding.groups: ["singing"]
                    Onboarding.texts: [i18n("The header shows the exercise status, score, and current target information while you sing.")]
                    spacing: 0

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        level: 3
                        text: root.score >= 0 ? i18n("Score: %1%", root.score) : root.scaleExercise ? i18n("Sing the scale") : i18n("Sing the interval")
                    }
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        level: 3
                        text: root.questionPitchMessage()
                    }
                    RowLayout {
                        id: actionButtons

                        readonly property real buttonWidth: Math.max(startQuestionButton.implicitWidth, testButton.implicitWidth)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Onboarding.groups: ["singing"]
                        Onboarding.texts: [i18n("Start a single singing question or begin a test with several questions in a row.")]
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Button {
                            id: startQuestionButton

                            Layout.preferredWidth: actionButtons.buttonWidth
                            enabled: root.microphoneReady && root.viewState !== "counting" && root.viewState !== "listening"
                            text: root.targetNotes.length === 0 || root.viewState === "finished" ? i18n("New Question") : i18n("Start")

                            onClicked: {
                                if (root.targetNotes.length === 0 || root.viewState === "finished") {
                                    root.generateQuestion();
                                }
                                root.startExercise();
                            }
                        }
                        QQC2.Button {
                            id: testButton

                            Layout.preferredWidth: actionButtons.buttonWidth
                            enabled: root.microphoneReady && root.viewState !== "counting" && root.viewState !== "listening"
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
            id: noteFrame

            Layout.bottomMargin: root.contentPadding
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: root.contentPadding
            Layout.rightMargin: root.contentPadding
            Layout.topMargin: root.contentPadding

            Flickable {
                id: noteViewport

                Onboarding.groups: ["singing"]
                Onboarding.texts: [i18n("Sing the note cards in order. The current card is highlighted; borders show correctness after detection."), i18n("Pitch meters light below the center for flat notes and above the center for sharp notes. Scale exercises also show an onset meter for each note.")]
                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentHeight: Math.max(noteViewport.height, noteRow.implicitHeight + root.countInOverlaySize + root.countInOverlayGap * 2)
                contentWidth: root.scaleExercise ? Math.max(noteViewport.width, noteRow.implicitWidth + noteContent.scaleSideInset * 2) : noteViewport.width
                flickableDirection: Flickable.HorizontalFlick

                QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                    policy: QQC2.ScrollBar.AsNeeded
                }

                onWidthChanged: Qt.callLater(root.centerCurrentTargetCard)

                Item {
                    id: noteContent

                    readonly property real centeredInset: Math.max(0, (noteViewport.width - noteRow.implicitWidth) / 2)
                    readonly property real countInTopInset: root.countInOverlaySize + root.countInOverlayGap
                    readonly property real scaleSideInset: Math.max(0, (noteViewport.width - root.noteCardWidth) / 2)

                    height: noteViewport.contentHeight
                    width: noteViewport.contentWidth

                    Row {
                        id: noteRow

                        spacing: Kirigami.Units.smallSpacing
                        x: root.scaleExercise ? noteContent.scaleSideInset : noteContent.centeredInset
                        y: Math.max(noteContent.countInTopInset, Math.round((noteContent.height - noteRow.implicitHeight) / 2))

                        Onboarding.onAboutToShow: root.onboardingPreviewActive = true
                        Onboarding.onHide: root.onboardingPreviewActive = false

                        Repeater {
                            id: noteRepeater

                            model: root.displayedTargetStates

                            delegate: Rectangle {
                                id: noteCard

                                required property int index
                                required property var modelData

                                color: Kirigami.Theme.backgroundColor
                                height: noteColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                                radius: Kirigami.Units.cornerRadius
                                width: root.noteCardWidth

                                border {
                                    color: root.stateBorderColor(noteCard.modelData, noteCard.index)
                                    width: root.stateBorderWidth(noteCard.modelData, noteCard.index)
                                }
                                Column {
                                    id: noteColumn

                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing
                                    width: parent.width - Kirigami.Units.largeSpacing * 2

                                    QQC2.Label {
                                        id: noteLabel

                                        color: Kirigami.Theme.textColor
                                        elide: Text.ElideRight
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: root.noteName(noteCard.modelData.midi)
                                        width: parent.width
                                    }
                                    Row {
                                        id: metersRow

                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: Kirigami.Units.smallSpacing
                                        width: implicitWidth

                                        GraphicalMeter {
                                            id: pitchMeter

                                            accuracy: noteCard.modelData.pitchAccuracy
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: pitchMeter.implicitHeight
                                            meterKind: "pitch"
                                            readoutText: noteCard.modelData.pitchText
                                            value: noteCard.modelData.pitchValue
                                            width: root.meterWidth
                                        }
                                        GraphicalMeter {
                                            id: onsetMeter

                                            accuracy: noteCard.modelData.onsetAccuracy
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: onsetMeter.visible ? onsetMeter.implicitHeight : 0
                                            meterKind: "onset"
                                            readoutText: noteCard.modelData.onsetText
                                            value: noteCard.modelData.onsetValue
                                            visible: root.scaleExercise && !noteCard.modelData.reference
                                            width: onsetMeter.visible ? root.meterWidth : 0
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
                    Onboarding.groups: ["singing"]
                    Onboarding.texts: [i18n("The input level shows microphone activity while you sing. Open means the signal is above the current gate.")]
                    accentColor: root.microphone && root.microphone.inputGateOpen ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                    label: i18n("Input level")
                    value: root.microphone ? Math.min(1, root.microphone.audioLevel * 12) : 0
                    valueText: root.microphone && root.microphone.inputGateOpen ? i18n("Open") : i18n("Closed")
                }
                QQC2.Button {
                    Onboarding.groups: ["singing"]
                    Onboarding.texts: [i18n("Calibrate silence in a quiet room before singing so room noise does not affect pitch and onset detection.")]
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
        ColumnLayout {
            id: musicPanel

            readonly property real viewHeight: Math.max(sheetMusicView.implicitHeight, pianoView.implicitHeight)

            Layout.bottomMargin: root.contentPadding
            Layout.fillWidth: true
            Layout.leftMargin: root.contentPadding
            Layout.maximumHeight: viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0)
            Layout.preferredHeight: viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0)
            Layout.rightMargin: root.contentPadding
            spacing: Kirigami.Units.smallSpacing

            GridLayout {
                id: musicViewsLayout

                readonly property real musicViewWidth: tabbed ? width : (width - columnSpacing) / 2
                readonly property bool tabbed: root.musicViewsTabbed

                Layout.fillWidth: true
                Layout.preferredHeight: musicPanel.viewHeight
                columnSpacing: Kirigami.Units.largeSpacing * 2
                columns: tabbed ? 1 : 2
                rowSpacing: Kirigami.Units.largeSpacing
                uniformCellWidths: !tabbed

                Item {
                    id: keyboardPanel

                    Layout.fillWidth: true
                    Layout.preferredHeight: musicPanel.viewHeight
                    Layout.preferredWidth: musicViewsLayout.musicViewWidth
                    Onboarding.groups: ["singing"]
                    Onboarding.texts: [i18n("The keyboard highlights the reference note and target notes for the singing question.")]
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
                    id: staffPanel

                    Layout.fillWidth: true
                    Layout.preferredHeight: musicPanel.viewHeight
                    Layout.preferredWidth: musicViewsLayout.musicViewWidth
                    Onboarding.groups: ["singing"]
                    Onboarding.texts: [i18n("The staff shows the same singing notes in music notation.")]
                    clip: true
                    visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 1

                    SheetMusicView {
                        id: sheetMusicView

                        anchors.fill: parent
                        spaced: true
                    }
                }
            }
            QQC2.TabBar {
                id: musicTabs

                Layout.fillWidth: true
                Onboarding.groups: ["singing"]
                Onboarding.texts: [i18n("On narrow screens, switch between the keyboard and staff views with these tabs.")]
                position: QQC2.TabBar.Footer
                visible: root.musicViewsTabbed

                QQC2.TabButton {
                    text: i18n("Keyboard")
                }
                QQC2.TabButton {
                    text: i18n("Staff")
                }
            }
        }
    }
}
