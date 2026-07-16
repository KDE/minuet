// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "singingexercisecontroller.h"

#include <KLocalizedString>

#include <algorithm>
#include <cmath>

using namespace Qt::StringLiterals;

namespace Minuet
{
SingingExerciseController::SingingExerciseController(QObject *parent)
    : QObject(parent)
{
}

QVariantMap SingingExerciseController::exerciseForVoiceClass(const QVariantMap &exercise, int voiceClass) const
{
    static constexpr std::pair<int, int> ranges[] = {{60, 84}, {55, 77}, {48, 72}, {40, 64}};
    const int index = std::clamp(voiceClass, 0, 3);
    QVariantMap result = exercise;
    result[u"targetPitchMin"_s] = ranges[index].first;
    result[u"targetPitchMax"_s] = ranges[index].second;
    return result;
}

QVariantMap SingingExerciseController::createQuestion(const QVariantMap &option, bool scaleExercise) const
{
    const int rootNote = option.value(u"rootNote"_s).toInt();
    QVariantList targetNotes;
    QVariantList targetStates;
    const QStringList intervals = option.value(u"sequence"_s).toString().split(u' ', Qt::SkipEmptyParts);
    for (const QString &interval : intervals) {
        bool valid = false;
        const int semitones = interval.toInt(&valid);
        if (!valid) {
            continue;
        }
        const int targetNote = rootNote + semitones;
        targetNotes.append(targetNote);
        targetStates.append(defaultTargetState(targetNote, scaleExercise));
    }
    return {{u"exerciseName"_s, option.value(u"name"_s)},
            {u"rootNote"_s, rootNote},
            {u"targetNotes"_s, targetNotes},
            {u"targetStates"_s, targetStates}};
}

QVariantList SingingExerciseController::displayedTargetStates(const QVariantList &targetStates,
                                                              bool onboardingPreviewActive,
                                                              bool referenceCardExercise,
                                                              int rootNote,
                                                              bool scaleExercise) const
{
    QVariantList states = targetStates;
    if (states.isEmpty() && onboardingPreviewActive) {
        states.append(defaultTargetState(rootNote > 0 ? rootNote : 60, scaleExercise));
    }
    if (!referenceCardExercise || states.isEmpty()) {
        return states;
    }
    QVariantMap reference = defaultTargetState(rootNote > 0 ? rootNote : states.first().toMap().value(u"midi"_s).toInt(), scaleExercise);
    reference[u"reference"_s] = true;
    reference[u"timingCorrect"_s] = true;
    reference[u"pitchText"_s] = i18n("Played");
    reference[u"timingText"_s] = QString();
    states.prepend(reference);
    return states;
}

QVariantMap SingingExerciseController::evaluatePitch(const QVariantList &targetStates,
                                                     const QVariantList &targetNotes,
                                                     double seconds,
                                                     int midiNote,
                                                     double cents,
                                                     double listeningStartSeconds,
                                                     double beatMs,
                                                     int pitchToleranceCents,
                                                     double pitchCorrectHoldSeconds,
                                                     bool disregardOctaveDifference,
                                                     bool scaleExercise,
                                                     double timingToleranceMs) const
{
    QVariantList states = targetStates;
    if (states.isEmpty() || targetNotes.isEmpty() || listeningStartSeconds < 0.0) {
        return {{u"targetStates"_s, states}, {u"targetIndex"_s, 0}, {u"meterValue"_s, 0.0}, {u"meterText"_s, i18n("No pitch")}};
    }
    const double elapsedMs = std::max(0.0, (seconds - listeningStartSeconds) * 1000.0);
    const int index = targetIndexForElapsed(targetNotes.size(), elapsedMs, beatMs);
    const int tolerance = std::max(1, pitchToleranceCents);
    const double error = pitchErrorCents(midiNote, cents, targetNotes.at(index).toInt(), disregardOctaveDifference);
    const double absoluteError = std::abs(error);
    const double meterAccuracy = std::max(0.0, 1.0 - absoluteError / tolerance);
    const QString meterText = i18n("%1 cents", qRound(error));
    QVariantMap state = states.at(index).toMap();
    state[u"pitchValue"_s] = std::clamp(error / tolerance, -1.0, 1.0);
    state[u"pitchAccuracy"_s] = meterAccuracy;
    state[u"pitchText"_s] = meterText;

    if (absoluteError <= tolerance) {
        state[u"pitchWrongSinceSeconds"_s] = -1.0;
        if (state.value(u"pitchCorrectSinceSeconds"_s).toDouble() < 0.0) {
            state[u"pitchCorrectSinceSeconds"_s] = seconds;
        }
    } else {
        state[u"pitchCorrectSinceSeconds"_s] = -1.0;
        if (state.value(u"pitchCorrect"_s).toBool()) {
            double wrongSince = state.value(u"pitchWrongSinceSeconds"_s).toDouble();
            if (wrongSince < 0.0) {
                wrongSince = seconds;
                state[u"pitchWrongSinceSeconds"_s] = seconds;
            }
            if (seconds - wrongSince >= pitchCorrectHoldSeconds) {
                state[u"pitchCorrect"_s] = false;
                state[u"pitchWrong"_s] = true;
                state[u"heard"_s] = false;
            }
        }
    }

    const double correctSince = state.value(u"pitchCorrectSinceSeconds"_s).toDouble();
    if (correctSince >= 0.0 && seconds - correctSince >= pitchCorrectHoldSeconds) {
        const bool becameCorrect = !state.value(u"pitchCorrect"_s).toBool();
        state[u"pitchCorrect"_s] = true;
        state[u"pitchWrong"_s] = false;
        state[u"heard"_s] = true;
        state[u"pitchWrongSinceSeconds"_s] = -1.0;
        if (becameCorrect && scaleExercise && state.value(u"timingEntrySeconds"_s).toDouble() < 0.0) {
            const double entryElapsedMs = std::max(0.0, (correctSince - listeningStartSeconds) * 1000.0);
            const double timingError = entryElapsedMs - index * beatMs;
            const double safeTimingTolerance = std::max(1.0, timingToleranceMs);
            state[u"timingEntrySeconds"_s] = correctSince;
            state[u"timingValue"_s] = -std::clamp(timingError / safeTimingTolerance, -1.0, 1.0);
            state[u"timingAccuracy"_s] = std::max(0.0, 1.0 - std::abs(timingError) / safeTimingTolerance);
            state[u"timingText"_s] = std::abs(timingError) < 1.0 ? i18n("On time") : i18n("%1 ms", qRound(timingError));
            state[u"timingCorrect"_s] = std::abs(timingError) <= safeTimingTolerance;
            state[u"timingWrong"_s] = !state.value(u"timingCorrect"_s).toBool();
        }
    }
    states[index] = state;
    states = refreshTargetStates(states, elapsedMs, beatMs, timingToleranceMs, pitchCorrectHoldSeconds, scaleExercise);
    return {{u"targetStates"_s, states},
            {u"targetIndex"_s, index},
            {u"elapsedMs"_s, elapsedMs},
            {u"meterValue"_s, meterAccuracy},
            {u"meterText"_s, meterText}};
}

QVariantList SingingExerciseController::refreshTargetStates(const QVariantList &targetStates,
                                                            double elapsedMs,
                                                            double beatMs,
                                                            double timingToleranceMs,
                                                            double pitchCorrectHoldSeconds,
                                                            bool scaleExercise) const
{
    QVariantList states = targetStates;
    const double finalTime = finalElapsedMs(states.size(), beatMs, timingToleranceMs, pitchCorrectHoldSeconds, scaleExercise);
    for (int index = 0; index < states.size(); ++index) {
        QVariantMap state = states.at(index).toMap();
        const double pitchEnd = scaleExercise && index < states.size() - 1 ? (index + 1) * beatMs : finalTime;
        if (!state.value(u"pitchCorrect"_s).toBool() && elapsedMs > pitchEnd) {
            state[u"pitchWrong"_s] = true;
        }
        if (scaleExercise && !state.value(u"timingCorrect"_s).toBool() && elapsedMs > index * beatMs + timingToleranceMs) {
            state[u"timingWrong"_s] = true;
            if (state.value(u"timingEntrySeconds"_s).toDouble() < 0.0) {
                state[u"timingText"_s] = i18n("Missed");
                state[u"timingAccuracy"_s] = 0.0;
                state[u"timingValue"_s] = 0.0;
            }
        }
        states[index] = state;
    }
    return states;
}

int SingingExerciseController::targetIndexForElapsed(int targetCount, double elapsedMs, double beatMs) const
{
    if (targetCount <= 0) {
        return 0;
    }
    return std::clamp(static_cast<int>(std::floor(elapsedMs / std::max(1.0, beatMs))), 0, targetCount - 1);
}

double SingingExerciseController::finalElapsedMs(int targetCount,
                                                double beatMs,
                                                double timingToleranceMs,
                                                double pitchCorrectHoldSeconds,
                                                bool scaleExercise) const
{
    return scaleExercise ? targetCount * beatMs + std::max(timingToleranceMs, pitchCorrectHoldSeconds * 1000.0) : targetCount * beatMs + beatMs;
}

int SingingExerciseController::score(const QVariantList &targetStates, int scoringMode) const
{
    const int correct = std::count_if(targetStates.cbegin(), targetStates.cend(), [scoringMode](const QVariant &stateValue) {
        const QVariantMap state = stateValue.toMap();
        return state.value(u"pitchCorrect"_s).toBool() && (scoringMode == 0 || state.value(u"timingCorrect"_s).toBool());
    });
    return targetStates.isEmpty() ? 0 : qRound(correct * 100.0 / targetStates.size());
}

QString SingingExerciseController::noteName(int midiNote) const
{
    static const QStringList names = {u"C"_s, u"C#"_s, u"D"_s, u"D#"_s, u"E"_s, u"F"_s, u"F#"_s, u"G"_s, u"G#"_s, u"A"_s, u"A#"_s, u"B"_s};
    const int note = ((midiNote % 12) + 12) % 12;
    return names.at(note) + QString::number(static_cast<int>(std::floor(midiNote / 12.0)) - 1);
}

QVariantList SingingExerciseController::referenceNotes(int rootNote, const QVariantList &targetNotes) const
{
    if (rootNote <= 0 || targetNotes.isEmpty()) {
        return {};
    }
    QVariantList notes{rootNote};
    notes.append(targetNotes);
    return notes;
}

QVariantMap SingingExerciseController::defaultTargetState(int midiNote, bool scaleExercise) const
{
    return {{u"midi"_s, midiNote},
            {u"reference"_s, false},
            {u"pitchCorrect"_s, false},
            {u"pitchWrong"_s, false},
            {u"timingCorrect"_s, !scaleExercise},
            {u"timingWrong"_s, false},
            {u"timingEntrySeconds"_s, -1.0},
            {u"heard"_s, false},
            {u"pitchCorrectSinceSeconds"_s, -1.0},
            {u"pitchWrongSinceSeconds"_s, -1.0},
            {u"pitchValue"_s, 0.0},
            {u"pitchAccuracy"_s, 0.0},
            {u"pitchText"_s, i18n("No pitch")},
            {u"timingValue"_s, 0.0},
            {u"timingAccuracy"_s, 0.0},
            {u"timingText"_s, i18n("No timing")}};
}

double SingingExerciseController::pitchErrorCents(int midiNote, double cents, int expectedMidiNote, bool disregardOctaveDifference) const
{
    const double rawError = (midiNote - expectedMidiNote) * 100.0 + cents;
    if (!disregardOctaveDifference) {
        return rawError;
    }
    double normalized = std::fmod(rawError + 600.0, 1200.0);
    if (normalized < 0.0) {
        normalized += 1200.0;
    }
    return normalized - 600.0;
}
}
