// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_SINGINGEXERCISECONTROLLER_H
#define MINUET_SINGINGEXERCISECONTROLLER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace Minuet
{
class SingingExerciseController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("SingingExerciseController is provided by Core")

public:
    explicit SingingExerciseController(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap exerciseForVoiceClass(const QVariantMap &exercise, int voiceClass) const;
    Q_INVOKABLE QVariantMap createQuestion(const QVariantMap &option, bool scaleExercise) const;
    Q_INVOKABLE QVariantList displayedTargetStates(const QVariantList &targetStates,
                                                   bool onboardingPreviewActive,
                                                   bool referenceCardExercise,
                                                   int rootNote,
                                                   bool scaleExercise) const;
    Q_INVOKABLE QVariantMap evaluatePitch(const QVariantList &targetStates,
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
                                          double timingToleranceMs) const;
    Q_INVOKABLE QVariantList refreshTargetStates(const QVariantList &targetStates,
                                                 double elapsedMs,
                                                 double beatMs,
                                                 double timingToleranceMs,
                                                 double pitchCorrectHoldSeconds,
                                                 bool scaleExercise) const;
    Q_INVOKABLE int targetIndexForElapsed(int targetCount, double elapsedMs, double beatMs) const;
    Q_INVOKABLE double finalElapsedMs(int targetCount,
                                     double beatMs,
                                     double timingToleranceMs,
                                     double pitchCorrectHoldSeconds,
                                     bool scaleExercise) const;
    Q_INVOKABLE int score(const QVariantList &targetStates, int scoringMode) const;
    Q_INVOKABLE QString noteName(int midiNote) const;
    Q_INVOKABLE QVariantList referenceNotes(int rootNote, const QVariantList &targetNotes) const;

private:
    QVariantMap defaultTargetState(int midiNote, bool scaleExercise) const;
    double pitchErrorCents(int midiNote, double cents, int expectedMidiNote, bool disregardOctaveDifference) const;
};
}

#endif
