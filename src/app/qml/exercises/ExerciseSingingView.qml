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

    readonly property bool scaleExercise: currentExercise !== undefined && currentExercise["singingExerciseKind"] === "scale"

    function applyMicrophoneSettings(): void {
        if (!internal.microphone) {
            return;
        }
        internal.microphone.analysisMode = IMicrophoneInputController.SingingPitchOnly;
        internal.microphone.preset = IMicrophoneInputController.Singing;
        internal.microphone.voiceClass = Core.settingsController.singingVoiceClass;
        internal.microphone.pitchMethod = Core.settingsController.singingPitchMethod;
        internal.microphone.minimumPitchConfidence = Core.settingsController.singingMinimumPitchConfidence;
        internal.microphone.inputGateLevel = Core.settingsController.singingInputGateLevel;
        internal.microphone.requiredStablePitchFrames = Core.settingsController.singingRequiredStablePitchFrames;
    }
    function beginMicrophoneCapture(): void {
        if (!internal.microphone) {
            return;
        }
        internal.microphone.stop();
        internal.microphone.start();
    }
    function beginScaleInputTiming(): void {
        if (!root.scaleExercise || internal.listeningStartSeconds >= 0) {
            return;
        }
        internal.listeningStartSeconds = internal.microphone ? internal.microphone.captureTimeSeconds : 0;
        root.updateScaleInputTimeline(0);
        root.centerCurrentTargetCard();
        timelineTimer.restart();
        progressTimer.restart();
        finishTimer.restart();
    }
    function cardColor(index: int): color {
        return internal.colors[index % internal.colors.length];
    }
    function centerAllTargetCards(): void {
        if (!root.scaleExercise || internal.displayedTargetStates.length === 0 || noteViewport.width <= 0) {
            return;
        }

        noteViewport.contentX = noteContent.cardsOverflowing ? Math.max(0, (noteViewport.contentWidth - noteViewport.width) / 2) : 0;
    }
    function centerCurrentTargetCard(): void {
        if (!root.scaleExercise || internal.displayedTargetStates.length === 0 || noteViewport.width <= 0) {
            return;
        }
        if (!noteContent.cardsOverflowing) {
            noteViewport.contentX = 0;
            return;
        }
        if (!internal.currentScaleCardCentered) {
            root.centerAllTargetCards();
            return;
        }

        const cardCenter = noteRow.x + internal.displayedTargetIndex * (internal.noteCardWidth + noteRow.spacing) + internal.noteCardWidth / 2;
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
        testNextQuestionTimer.stop();
        listenDelay.stop();
        noteSubTickTimer.stop();
        finishTimer.stop();
        progressTimer.stop();
        timelineTimer.stop();
        root.countIn = 0;
        internal.countInOverlayAnchorIndex = -1;
        internal.countPhase = "idle";
        internal.countInStarted = false;
        internal.inputTargetIndex = 0;
        internal.listeningStartSeconds = -1;
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
        const finalElapsedMs = Core.singingExerciseController.finalElapsedMs(internal.targetNotes.length, internal.beatMs, internal.timingToleranceMs, internal.pitchCorrectHoldSeconds, root.scaleExercise);
        const finalStates = refreshTargetStates(finalElapsedMs);
        internal.score = Core.singingExerciseController.score(finalStates, Core.settingsController.singingScoringMode);
        internal.viewState = "finished";
        Qt.callLater(root.centerAllTargetCards);
        finishScoredQuestion();
    }
    function countInOverlayTargetX(): real {
        if (internal.countPhase !== "input" && !(internal.referenceCardExercise && internal.countPhase === "root")) {
            return root.clampCountInOverlayX(root.noteRowCenterX() - root.countInOverlaySize / 2);
        }

        const lastIndex = Math.max(0, internal.displayedTargetStates.length - 1);
        const cardIndex = Math.max(0, Math.min(lastIndex, internal.countInOverlayAnchorIndex));
        return root.clampCountInOverlayX(root.noteCardCenterX(cardIndex) - root.countInOverlaySize / 2);
    }
    function countInOverlayTargetY(): real {
        const cardY = noteFrame.y + noteViewport.y + noteRow.y;
        return root.clampCountInOverlayY(cardY - root.countInOverlaySize / 2);
    }
    function currentDisplayTargetIndex(): int {
        if (internal.referenceCardExercise && internal.countPhase === "root") {
            return 0;
        }
        return root.displayIndexForTarget(root.scaleExercise && internal.viewState === "listening" && internal.countPhase === "input" ? internal.inputTargetIndex : internal.currentTargetIndex);
    }
    function displayIndexForTarget(targetIndex: int): int {
        if (!internal.referenceCardExercise) {
            return targetIndex;
        }
        return Math.max(0, targetIndex + 1);
    }
    function displayedTargetStatesModel(): var {
        return Core.singingExerciseController.displayedTargetStates(internal.targetStates, root.onboardingPreviewActive, internal.referenceCardExercise, internal.rootNote, root.scaleExercise);
    }
    function failInputAnalysis(message: string): void {
        if (internal.viewState !== "counting" && internal.viewState !== "listening" && internal.viewState !== "analyzing") {
            return;
        }
        listenDelay.stop();
        noteSubTickTimer.stop();
        finishTimer.stop();
        progressTimer.stop();
        timelineTimer.stop();
        root.countIn = 0;
        internal.countInOverlayAnchorIndex = -1;
        internal.countPhase = "idle";
        internal.countInStarted = false;
        internal.inputErrorMessage = message;
        internal.viewState = "ready";
        if (Core.soundController) {
            Core.soundController.stop();
        }
    }
    function finishExercise(): void {
        if (internal.viewState !== "listening") {
            return;
        }
        finishTimer.stop();
        noteSubTickTimer.stop();
        progressTimer.stop();
        timelineTimer.stop();
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
        if (root.currentExercise === undefined) {
            return;
        }
        Core.exerciseSessionController.setActiveExercise(Core.singingExerciseController.exerciseForVoiceClass(root.currentExercise, Core.settingsController.singingVoiceClass));
        Core.exerciseSessionController.beginQuestion(Core.settingsController.testExerciseCount);
        Core.exerciseSessionController.randomlySelectExerciseOptions(1);
        const selected = Core.exerciseSessionController.selectedExerciseOptions;
        if (selected.length === 0) {
            return;
        }
        const question = Core.singingExerciseController.createQuestion(selected[0], root.scaleExercise);
        internal.exerciseName = question.exerciseName;
        internal.rootNote = question.rootNote;
        internal.targetNotes = question.targetNotes;
        internal.targetStates = question.targetStates;
        internal.currentTargetIndex = 0;
        internal.score = -1;
        internal.pitchMeterValue = 0;
        internal.pitchMeterText = i18n("No pitch");
        showReferenceNotes();
        internal.viewState = "ready";
        Qt.callLater(root.centerAllTargetCards);
        Core.exerciseSessionController.finishQuestionGeneration();
    }
    function handlePitch(seconds: real, midiNote: int, cents: real, confidence: real): void {
        if ((internal.viewState !== "listening" && internal.viewState !== "analyzing") || internal.targetNotes.length === 0 || internal.listeningStartSeconds < 0) {
            return;
        }
        const evaluation = Core.singingExerciseController.evaluatePitch(internal.targetStates, internal.targetNotes, seconds, midiNote, cents, internal.listeningStartSeconds, internal.beatMs, Core.settingsController.singingPitchToleranceCents, internal.pitchCorrectHoldSeconds, Core.settingsController.singingDisregardOctaveDifference, root.scaleExercise, internal.timingToleranceMs);
        internal.currentTargetIndex = evaluation.targetIndex;
        internal.pitchMeterValue = evaluation.meterValue;
        internal.pitchMeterText = evaluation.meterText;
        internal.targetStates = evaluation.targetStates;
    }
    function isIntervalExercise(): bool {
        return root.currentExercise !== undefined && root.currentExercise["singingExerciseKind"] === "interval";
    }
    function mapNoteRowX(localX: real): real {
        const geometryDependency = noteFrame.x + noteViewport.x + noteViewport.contentX + noteContent.x + noteRow.x + noteRow.implicitWidth;
        return noteRow.mapToItem(root, localX + geometryDependency * 0, 0).x;
    }
    function noteCardCenterX(index: int): real {
        return root.mapNoteRowX(index * (internal.noteCardWidth + noteRow.spacing) + internal.noteCardWidth / 2);
    }
    function noteRowCenterX(): real {
        if (internal.displayedTargetStates.length <= 0) {
            return noteFrame.x + noteViewport.x + noteViewport.width / 2;
        }
        return root.mapNoteRowX(noteRow.implicitWidth / 2);
    }
    function playRootAndListen(): void {
        root.countIn = internal.referenceCardExercise ? 1 : 0;
        internal.countInOverlayAnchorIndex = internal.referenceCardExercise ? 0 : -1;
        internal.countPhase = "root";
        internal.countInStarted = false;
        Qt.callLater(root.centerCurrentTargetCard);
        if (Core.soundController) {
            Core.soundController.prepareFromExerciseOptions([
                {
                    "rootNote": internal.rootNote.toString(),
                    "sequence": ""
                }
            ]);
            Core.soundController.play();
        }
        if (internal.referenceCardExercise) {
            noteSubTickTimer.restart();
        }
        listenDelay.restart();
    }
    function questionPitchMessage(): string {
        if (internal.inputErrorMessage.length > 0) {
            return internal.inputErrorMessage;
        }
        if (internal.viewState === "analyzing" && !Core.exerciseSessionController.isTest) {
            return i18n("Analyzing...");
        }
        if (internal.exerciseName.length === 0 || internal.targetNotes.length === 0) {
            if (!internal.microphone) {
                return i18n("No microphone input plugin available");
            }
            if (!internal.microphone.inputDeviceAvailable) {
                return i18n("No microphone input devices found");
            }
            return internal.microphone.status;
        }

        const base = Core.singingExerciseController.noteName(internal.rootNote);
        const translatedExerciseName = i18nc("technical term, do you have a musician friend?", internal.exerciseName);
        if (root.scaleExercise) {
            const targetNames = [];
            for (const note of internal.targetNotes) {
                targetNames.push(Core.singingExerciseController.noteName(note));
            }
            return i18n("%1 - Base: %2 - Targets: %3", translatedExerciseName, base, targetNames.join(", "));
        }
        return i18n("%1 - Base: %2 - Target: %3", translatedExerciseName, base, Core.singingExerciseController.noteName(internal.targetNotes[0]));
    }
    function referenceNotes(): var {
        if (internal.rootNote <= 0 || internal.targetNotes.length === 0) {
            return [];
        }
        return Core.singingExerciseController.referenceNotes(internal.rootNote, internal.targetNotes);
    }
    function refreshTargetStates(elapsedMs: real): var {
        internal.targetStates = Core.singingExerciseController.refreshTargetStates(internal.targetStates, elapsedMs, internal.beatMs, internal.timingToleranceMs, internal.pitchCorrectHoldSeconds, root.scaleExercise);
        return internal.targetStates;
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

        pianoView.noteMark(0, internal.rootNote, 0, "white");
        for (let i = 0; i < internal.targetNotes.length; ++i) {
            pianoView.noteMark(0, internal.targetNotes[i], 0, root.cardColor(i));
        }
        pianoView.scrollToMarkedKeys();
        sheetMusicView.model = notes;
    }
    function startExercise(): void {
        if (root.currentExercise === undefined || internal.viewState === "counting" || internal.viewState === "listening" || internal.viewState === "analyzing") {
            return;
        }
        if (internal.targetNotes.length === 0) {
            generateQuestion();
        }
        applyMicrophoneSettings();
        internal.inputErrorMessage = "";
        root.countIn = 0;
        internal.countPhase = "preparation";
        internal.countInStarted = false;
        internal.countInOverlayAnchorIndex = -1;
        internal.viewState = "counting";
        if (Core.soundController) {
            Core.soundController.playCountIn(4);
        }
        root.centerAllTargetCards();
    }
    function startListening(): void {
        noteSubTickTimer.stop();
        if (internal.microphone && !internal.microphone.running) {
            beginMicrophoneCapture();
        }
        internal.currentTargetIndex = 0;
        internal.inputTargetIndex = 0;
        internal.countInOverlayAnchorIndex = internal.referenceCardExercise ? 1 : 0;
        if (root.isIntervalExercise()) {
            root.countIn = 2;
        } else if (!root.scaleExercise) {
            root.countIn = 0;
        }
        internal.countPhase = "input";
        internal.countInStarted = false;
        internal.viewState = "listening";
        if (root.isIntervalExercise()) {
            noteSubTickTimer.restart();
        }
        if (root.scaleExercise) {
            internal.listeningStartSeconds = -1;
            if (internal.microphone) {
                internal.microphone.resetInputAnalysisState();
            }
        } else {
            if (internal.microphone) {
                internal.microphone.resetInputAnalysisState();
            }
            internal.listeningStartSeconds = internal.microphone ? internal.microphone.captureTimeSeconds : 0;
        }
        finishTimer.interval = Core.singingExerciseController.finalElapsedMs(internal.targetNotes.length, internal.beatMs, internal.timingToleranceMs, internal.pitchCorrectHoldSeconds, root.scaleExercise);
        if (Core.soundController && root.scaleExercise) {
            Core.soundController.playSilentCountIn(internal.targetNotes.length);
        } else if (root.scaleExercise) {
            root.beginScaleInputTiming();
        }
        if (!root.scaleExercise) {
            timelineTimer.restart();
            progressTimer.restart();
            finishTimer.restart();
        }
    }
    function startTest(): void {
        Core.exerciseSessionController.startTest();
        generateQuestion();
        startExercise();
    }
    function stateBorderColor(state: var, index: int): color {
        if (state.reference) {
            if (index === internal.displayedTargetIndex && (internal.countPhase === "root" || internal.viewState === "listening")) {
                return Kirigami.Theme.highlightColor;
            }
            return Kirigami.Theme.textColor;
        }
        if (state.pitchCorrect && (Core.settingsController.singingScoringMode === 0 || state.timingCorrect)) {
            return Kirigami.Theme.positiveTextColor;
        }
        if (state.pitchWrong || (Core.settingsController.singingScoringMode !== 0 && state.timingWrong) || internal.viewState === "finished") {
            return Kirigami.Theme.negativeTextColor;
        }
        if (index === internal.displayedTargetIndex && internal.viewState === "listening") {
            return Kirigami.Theme.highlightColor;
        }
        return Kirigami.Theme.textColor;
    }
    function stateBorderWidth(state: var, index: int): int {
        if (state.reference) {
            return index === internal.displayedTargetIndex && (internal.countPhase === "root" || internal.viewState === "listening") ? 2 : 1;
        }
        return (index === internal.displayedTargetIndex && internal.viewState === "listening") || internal.viewState === "finished" || state.pitchCorrect ? 2 : 1;
    }
    function stopExerciseActivity(): void {
        clearCurrentRun();
        root.currentExercise = undefined;
    }
    function stopTest(): void {
        clearCurrentRun();
        Core.exerciseSessionController.stopTest();
        internal.viewState = internal.targetNotes.length > 0 ? "ready" : "idle";
    }
    function testHeaderStatus(): string {
        if (internal.viewState === "counting") {
            return i18n("Playing…");
        }
        if (internal.viewState === "listening") {
            return i18n("Listening...");
        }
        if (internal.viewState === "analyzing") {
            return i18n("Analyzing...");
        }
        return Core.exerciseSessionController.statusText;
    }
    function titleMessage(): string {
        if (internal.score >= 0) {
            return i18n("Score: %1%", internal.score);
        }

        const instruction = root.scaleExercise ? i18n("Sing the scale") : i18n("Sing the interval");
        if (!Core.exerciseSessionController.isTest) {
            return instruction;
        }

        const status = root.testHeaderStatus();
        return status.length > 0 ? i18n("%1 — %2", instruction, status) : instruction;
    }
    function updateScaleInputTimeline(elapsedMs: real): void {
        if (!root.scaleExercise || internal.countPhase !== "input" || internal.targetNotes.length === 0) {
            return;
        }
        const index = Core.singingExerciseController.targetIndexForElapsed(internal.targetNotes.length, Math.max(0, elapsedMs), internal.beatMs);
        const indexChanged = internal.inputTargetIndex !== index;
        if (indexChanged) {
            internal.inputTargetIndex = index;
            internal.currentTargetIndex = index;
        }
        if (indexChanged) {
            root.centerCurrentTargetCard();
        }
    }

    countInOverlayInitial: internal.countPhase === "preparation" || root.onboardingCountIn > 0
    countInOverlaySize: internal.meterWidth
    countInOverlayX: root.countInOverlayTargetX()
    countInOverlayY: root.countInOverlayTargetY()
    visible: root.currentExercise !== undefined

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
        internal.targetNotes = [];
        internal.targetStates = [];
        internal.score = -1;
        internal.exerciseName = "";
        internal.viewState = "idle";
        pianoView.clearAllMarks();
        sheetMusicView.clearAllMarks();
        if (root.currentExercise !== undefined) {
            Core.exerciseSessionController.resetForExercise();
            Qt.callLater(root.generateQuestion);
        }
    }

    QtObject {
        id: internal

        readonly property real beatMs: 60000 / Core.settingsController.exerciseSpeed
        property var colors: ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        readonly property real contentPadding: Kirigami.Units.largeSpacing * 2
        property int countInOverlayAnchorIndex: -1
        property bool countInStarted: false
        property string countPhase: "idle"
        readonly property bool currentScaleCardCentered: root.scaleExercise && (internal.countPhase === "root" || (internal.viewState === "listening" && internal.countPhase === "input"))
        property int currentTargetIndex: 0
        readonly property int displayedTargetIndex: root.currentDisplayTargetIndex()
        readonly property var displayedTargetStates: root.displayedTargetStatesModel()
        property string exerciseName: ""
        property string inputErrorMessage: ""
        property int inputTargetIndex: 0
        property real listeningStartSeconds: -1
        readonly property real meterWidth: Math.ceil(Math.max(pitchMeterProbe.implicitWidth, timingMeterProbe.implicitWidth))
        readonly property var microphone: Core.microphoneInputController
        readonly property bool microphoneReady: internal.microphone !== null && internal.microphone.inputDeviceAvailable
        readonly property bool musicViewsTabbed: !applicationWindow().wideScreen && root.height > root.width
        readonly property real noteCardWidth: Math.ceil((root.scaleExercise ? internal.meterWidth * 2 + Kirigami.Units.smallSpacing : internal.meterWidth) + Kirigami.Units.largeSpacing * 2)
        property int onboardingInitialMusicTabIndex: -1
        property bool onboardingMusicTabCaptured: false
        readonly property real pitchCorrectHoldSeconds: Math.min(0.18, Math.max(0.10, internal.beatMs * 0.0002))
        property string pitchMeterText: i18n("No pitch")
        property real pitchMeterValue: 0
        readonly property bool referenceCardExercise: root.currentExercise !== undefined && (root.currentExercise["singingExerciseKind"] === "interval" || root.currentExercise["singingExerciseKind"] === "scale")
        property int rootNote: 0
        property int score: -1
        property var targetNotes: []
        property var targetStates: []
        readonly property real timingToleranceMs: Math.min(180, internal.beatMs * Core.settingsController.clappingCorrectnessTolerancePercent / 100)
        property string viewState: "idle"
    }
    Connections {
        function onCurrentTargetIndexChanged(): void {
            if (!internal.currentScaleCardCentered) {
                Qt.callLater(root.centerCurrentTargetCard);
            }
        }
        function onDisplayedTargetIndexChanged(): void {
            if (!internal.currentScaleCardCentered) {
                Qt.callLater(root.centerCurrentTargetCard);
            }
        }
        function onTargetStatesChanged(): void {
            if (internal.viewState === "finished") {
                Qt.callLater(root.centerAllTargetCards);
            }
        }

        target: internal
    }
    GraphicalMeter {
        id: pitchMeterProbe

        meterKind: "pitch"
        visible: false
    }
    GraphicalMeter {
        id: timingMeterProbe

        meterKind: "onset"
        visible: false
    }
    Timer {
        id: listenDelay

        interval: internal.beatMs

        onTriggered: root.startListening()
    }
    Timer {
        id: noteSubTickTimer

        interval: Math.max(1, Math.round(internal.beatMs / 2))

        onTriggered: {
            if (internal.referenceCardExercise && (internal.countPhase === "root" || internal.countPhase === "input") && root.countIn > 0) {
                root.countInSubTickRequested();
            }
        }
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
            if (internal.viewState === "listening" && internal.microphone && internal.listeningStartSeconds >= 0) {
                root.refreshTargetStates(Math.max(0, (internal.microphone.captureTimeSeconds - internal.listeningStartSeconds) * 1000));
            }
        }
    }
    Timer {
        id: timelineTimer

        interval: 20
        repeat: true

        onTriggered: {
            if (internal.viewState === "listening" && internal.microphone && internal.listeningStartSeconds >= 0) {
                root.updateScaleInputTimeline((internal.microphone.captureTimeSeconds - internal.listeningStartSeconds) * 1000);
            }
        }
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
        function onPitchDetected(seconds: real, midiNote: int, cents: real, confidence: real): void {
            root.handlePitch(seconds, midiNote, cents, confidence);
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
                    root.playRootAndListen();
                }
            } else if (internal.countPhase === "input") {
                if (root.scaleExercise && count > 0) {
                    const targetIndex = count - 1;
                    internal.inputTargetIndex = targetIndex;
                    internal.currentTargetIndex = targetIndex;
                    internal.countInOverlayAnchorIndex = count;
                    root.countIn = count + 1;
                    root.centerCurrentTargetCard();
                    if (count === 1) {
                        internal.countInStarted = true;
                        root.beginScaleInputTiming();
                    }
                } else if (!root.scaleExercise) {
                    root.countIn = count;
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
            onboardingGroups: ["singing"]
            onboardingTexts: [root.scaleExercise ? i18n("The header identifies the scale and shows the current instruction or score.") : i18n("The header identifies the interval and shows the current instruction or score.")]
            subtitle: root.questionPitchMessage()
            title: root.titleMessage()

            QQC2.Button {
                id: startQuestionButton

                Layout.preferredWidth: exerciseHeader.actionButtonWidth
                enabled: internal.microphoneReady && internal.viewState !== "counting" && internal.viewState !== "listening" && internal.viewState !== "analyzing"
                text: internal.targetNotes.length === 0 || internal.viewState === "finished" ? i18n("New Question") : i18n("Start")

                onClicked: {
                    if (internal.targetNotes.length === 0 || internal.viewState === "finished") {
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
            id: noteFrame

            Layout.bottomMargin: internal.contentPadding
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: internal.contentPadding
            Layout.rightMargin: internal.contentPadding
            Layout.topMargin: internal.contentPadding
            Onboarding.groups: ["singing"]
            Onboarding.texts: [root.scaleExercise ? i18n("This area shows the scale notes in order. Borders report pitch; pitch meters show flat or sharp notes, and timing meters show early or late starts.") : i18n("This area shows the reference and target notes. Sing the target; its border reports accuracy, and its pitch meter shows flat or sharp notes.")]

            Onboarding.onAboutToShow: root.onboardingPreviewActive = true
            Onboarding.onHide: root.onboardingPreviewActive = false

            Flickable {
                id: noteViewport

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentHeight: noteViewport.height
                contentWidth: root.scaleExercise && noteContent.cardsOverflowing ? noteRow.implicitWidth + noteContent.sideInset * 2 : noteViewport.width
                flickableDirection: Flickable.HorizontalFlick

                QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                    id: noteHorizontalScrollBar

                    policy: QQC2.ScrollBar.AsNeeded
                }

                onWidthChanged: Qt.callLater(root.centerCurrentTargetCard)

                Item {
                    id: noteContent

                    readonly property bool cardsOverflowing: noteRow.implicitWidth > noteViewport.width
                    readonly property real sideInset: Math.max(0, (noteViewport.width - internal.noteCardWidth) / 2)

                    height: noteViewport.contentHeight
                    width: noteViewport.contentWidth

                    Row {
                        id: noteRow

                        opacity: root.onboardingCardsHidden ? 0 : 1
                        spacing: Kirigami.Units.smallSpacing
                        x: root.scaleExercise && noteContent.cardsOverflowing ? noteContent.sideInset : Math.max(0, (noteViewport.width - noteRow.implicitWidth) / 2)
                        y: Math.round((noteContent.height - (root.scaleExercise && noteContent.cardsOverflowing ? noteHorizontalScrollBar.height : 0) - noteRow.implicitHeight) / 2)

                        Repeater {
                            id: noteRepeater

                            model: internal.displayedTargetStates

                            delegate: Rectangle {
                                id: noteCard

                                required property int index
                                required property var modelData

                                color: Kirigami.Theme.backgroundColor
                                height: noteColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                                radius: Kirigami.Units.cornerRadius
                                width: internal.noteCardWidth

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
                                        text: Core.singingExerciseController.noteName(noteCard.modelData.midi)
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
                                            width: internal.meterWidth
                                        }
                                        GraphicalMeter {
                                            id: timingMeter

                                            accuracy: noteCard.modelData.timingAccuracy
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: timingMeter.visible ? timingMeter.implicitHeight : 0
                                            meterKind: "onset"
                                            noReadingText: i18n("No timing")
                                            readoutText: noteCard.modelData.timingText
                                            value: noteCard.modelData.timingValue
                                            visible: root.scaleExercise && !noteCard.modelData.reference
                                            width: timingMeter.visible ? internal.meterWidth : 0
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
            Layout.bottomMargin: internal.contentPadding
            Layout.fillWidth: true
            Layout.leftMargin: internal.contentPadding
            Layout.rightMargin: internal.contentPadding

            MicrophoneInputPanel {
                anchors.fill: parent
                calibrationHelpText: i18n("Calibrate silence in a quiet room before singing so room noise does not affect pitch detection.")
                inputHelpText: i18n("The input level shows microphone activity while you sing. Open means the signal is above the current gate.")
                microphone: internal.microphone
                microphoneReady: internal.microphoneReady
                onboardingGroup: "singing"

                onCalibrateRequested: {
                    root.applyMicrophoneSettings();
                    if (!internal.microphone.running) {
                        internal.microphone.start();
                    }
                    Qt.callLater(internal.microphone.calibrateNoiseFloor);
                }
            }
        }
        ColumnLayout {
            id: musicPanel

            readonly property real viewHeight: Math.max(sheetMusicView.implicitHeight, pianoView.implicitHeight)

            Layout.bottomMargin: internal.contentPadding
            Layout.fillWidth: true
            Layout.leftMargin: internal.contentPadding
            Layout.maximumHeight: viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0)
            Layout.preferredHeight: viewHeight + (musicTabs.visible ? musicTabs.implicitHeight + spacing : 0)
            Layout.rightMargin: internal.contentPadding
            spacing: Kirigami.Units.smallSpacing

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
                    id: keyboardPanel

                    Layout.fillWidth: true
                    Layout.preferredHeight: musicPanel.viewHeight
                    Layout.preferredWidth: musicViewsLayout.musicViewWidth
                    visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 0

                    Item {
                        id: keyboardOnboardingTarget

                        Onboarding.groups: ["singing"]
                        Onboarding.texts: [i18n("The keyboard highlights the reference note and target notes for the singing question.")]
                        height: musicViewsLayout.tabbed ? musicPanel.height : parent.height
                        width: musicViewsLayout.tabbed ? musicPanel.width : parent.width
                        x: musicViewsLayout.tabbed ? -keyboardPanel.x - musicViewsLayout.x : 0
                        y: musicViewsLayout.tabbed ? -keyboardPanel.y - musicViewsLayout.y : 0
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
                    id: staffPanel

                    Layout.fillWidth: true
                    Layout.preferredHeight: musicPanel.viewHeight
                    Layout.preferredWidth: musicViewsLayout.musicViewWidth
                    clip: true
                    visible: !musicViewsLayout.tabbed || musicTabs.currentIndex === 1

                    Item {
                        id: staffOnboardingTarget

                        Onboarding.groups: ["singing"]
                        Onboarding.texts: [i18n("The staff shows the same singing notes in music notation.")]
                        height: musicViewsLayout.tabbed ? musicPanel.height : parent.height
                        width: musicViewsLayout.tabbed ? musicPanel.width : parent.width
                        x: musicViewsLayout.tabbed ? -staffPanel.x - musicViewsLayout.x : 0
                        y: musicViewsLayout.tabbed ? -staffPanel.y - musicViewsLayout.y : 0
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
                        spaced: true
                    }
                }
            }
            QQC2.TabBar {
                id: musicTabs

                Layout.fillWidth: true
                position: QQC2.TabBar.Footer
                visible: internal.musicViewsTabbed

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
