// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "settingscontroller.h"

#include <QSettings>

#include <algorithm>

using namespace Qt::StringLiterals;

namespace Minuet
{
SettingsController::SettingsController(QObject *parent)
    : QObject(parent)
{
    load();
}

void SettingsController::load()
{
    QSettings settings;
    settings.beginGroup(u"Settings"_s);
    m_rhythmPatternCount = std::clamp(settings.value(u"RhythmPatternCount"_s, m_rhythmPatternCount).toInt(), 4, 16);
    m_testExerciseCount = std::clamp(settings.value(u"TestExerciseCount"_s, m_testExerciseCount).toInt(), 5, 20);
    m_volume = std::clamp(settings.value(u"Volume"_s, m_volume).toInt(), 0, 200);
    m_pitch = std::clamp(settings.value(u"Pitch"_s, m_pitch).toInt(), -12, 12);
    m_tempo = std::clamp(settings.value(u"Tempo"_s, m_tempo).toInt(), 1, 255);
    m_exerciseSpeed = std::clamp(settings.value(u"ExerciseSpeed"_s, m_tempo).toInt(), 30, 240);
    m_clappingSpeed = std::clamp(settings.value(u"ClappingSpeed"_s, m_clappingSpeed).toInt(), 30, 120);
    m_instrumentGroup = settings.value(u"InstrumentGroup"_s, m_instrumentGroup).toInt();
    m_instrument = std::clamp(settings.value(u"Instrument"_s, m_instrument).toInt(), 0, 127);
    m_rhythmInstrument = std::clamp(settings.value(u"RhythmInstrument"_s, m_rhythmInstrument).toInt(), 35, 81);
    m_microphoneInputDeviceId = settings.value(u"MicrophoneInputDeviceId"_s, m_microphoneInputDeviceId).toString();
    m_clappingCorrectnessTolerancePercent = std::clamp(settings.value(u"ClappingCorrectnessTolerancePercent"_s, m_clappingCorrectnessTolerancePercent).toInt(), 5, 100);
    m_singingPitchToleranceCents = std::clamp(settings.value(u"SingingPitchToleranceCents"_s, m_singingPitchToleranceCents).toInt(), 10, 49);
    m_singingDisregardOctaveDifference = settings.value(u"SingingDisregardOctaveDifference"_s, m_singingDisregardOctaveDifference).toBool();
    m_singingScoringMode = std::clamp(settings.value(u"SingingScoringMode"_s, m_singingScoringMode).toInt(), 0, 1);
    m_singingVoiceClass = std::clamp(settings.value(u"SingingVoiceClass"_s, m_singingVoiceClass).toInt(), 0, 3);
    m_singingPitchMethod = std::clamp(settings.value(u"SingingPitchMethod"_s, m_singingPitchMethod).toInt(), 0, 6);
    m_singingMinimumPitchConfidence = std::clamp(settings.value(u"SingingMinimumPitchConfidence"_s, m_singingMinimumPitchConfidence).toDouble(), 0.0, 0.95);
    m_singingInputGateLevel = std::clamp(settings.value(u"SingingInputGateLevel"_s, m_singingInputGateLevel).toDouble(), 0.0, 0.25);
    m_singingRequiredStablePitchFrames = std::clamp(settings.value(u"SingingRequiredStablePitchFrames"_s, m_singingRequiredStablePitchFrames).toInt(), 1, 10);
    m_clappingPitchMethod = std::clamp(settings.value(u"ClappingPitchMethod"_s, m_clappingPitchMethod).toInt(), 0, 6);
    m_clappingOnsetMethod = std::clamp(settings.value(u"ClappingOnsetMethod"_s, m_clappingOnsetMethod).toInt(), 0, 7);
    m_clappingMinimumPitchConfidence = std::clamp(settings.value(u"ClappingMinimumPitchConfidence"_s, m_clappingMinimumPitchConfidence).toDouble(), 0.0, 0.95);
    m_clappingOnsetThreshold = std::clamp(settings.value(u"ClappingOnsetThreshold"_s, m_clappingOnsetThreshold).toDouble(), 0.01, 1.0);
    m_clappingInputGateLevel = std::clamp(settings.value(u"ClappingInputGateLevel"_s, m_clappingInputGateLevel).toDouble(), 0.0, 0.25);
    m_clappingMinimumOnsetStrength = std::clamp(settings.value(u"ClappingMinimumOnsetStrength"_s, m_clappingMinimumOnsetStrength).toDouble(), 0.0, 1.0);
    m_clappingRequiredStablePitchFrames = std::clamp(settings.value(u"ClappingRequiredStablePitchFrames"_s, m_clappingRequiredStablePitchFrames).toInt(), 1, 10);
    m_melodicOnboardingPromptShown = settings.value(u"MelodicOnboardingPromptShown"_s, m_melodicOnboardingPromptShown).toBool();
    m_rhythmicOnboardingPromptShown = settings.value(u"RhythmicOnboardingPromptShown"_s, m_rhythmicOnboardingPromptShown).toBool();
    m_clappingOnboardingPromptShown = settings.value(u"ClappingOnboardingPromptShown"_s, m_clappingOnboardingPromptShown).toBool();
    m_singingOnboardingPromptShown = settings.value(u"SingingOnboardingPromptShown"_s, m_singingOnboardingPromptShown).toBool();
    settings.remove(u"SingingOnsetMethod"_s);
    settings.remove(u"SingingOnsetThreshold"_s);
    settings.remove(u"SingingMinimumOnsetStrength"_s);
}

void SettingsController::write(const QString &key, int value)
{
    QSettings settings;
    settings.beginGroup(u"Settings"_s);
    settings.setValue(key, value);
}

void SettingsController::write(const QString &key, double value)
{
    QSettings settings;
    settings.beginGroup(u"Settings"_s);
    settings.setValue(key, value);
}

void SettingsController::write(const QString &key, bool value)
{
    QSettings settings;
    settings.beginGroup(u"Settings"_s);
    settings.setValue(key, value);
}

void SettingsController::write(const QString &key, const QString &value)
{
    QSettings settings;
    settings.beginGroup(u"Settings"_s);
    settings.setValue(key, value);
}

int SettingsController::rhythmPatternCount() const
{
    return m_rhythmPatternCount;
}

int SettingsController::testExerciseCount() const
{
    return m_testExerciseCount;
}

int SettingsController::volume() const
{
    return m_volume;
}

int SettingsController::pitch() const
{
    return m_pitch;
}

int SettingsController::tempo() const
{
    return m_tempo;
}

int SettingsController::exerciseSpeed() const
{
    return m_exerciseSpeed;
}

int SettingsController::clappingSpeed() const
{
    return m_clappingSpeed;
}

int SettingsController::instrumentGroup() const
{
    return m_instrumentGroup;
}

int SettingsController::instrument() const
{
    return m_instrument;
}

int SettingsController::rhythmInstrument() const
{
    return m_rhythmInstrument;
}

QString SettingsController::microphoneInputDeviceId() const
{
    return m_microphoneInputDeviceId;
}

int SettingsController::clappingCorrectnessTolerancePercent() const
{
    return m_clappingCorrectnessTolerancePercent;
}

int SettingsController::singingPitchToleranceCents() const
{
    return m_singingPitchToleranceCents;
}

bool SettingsController::singingDisregardOctaveDifference() const
{
    return m_singingDisregardOctaveDifference;
}

int SettingsController::singingScoringMode() const
{
    return m_singingScoringMode;
}

int SettingsController::singingVoiceClass() const
{
    return m_singingVoiceClass;
}

int SettingsController::singingPitchMethod() const
{
    return m_singingPitchMethod;
}

double SettingsController::singingMinimumPitchConfidence() const
{
    return m_singingMinimumPitchConfidence;
}

double SettingsController::singingInputGateLevel() const
{
    return m_singingInputGateLevel;
}

int SettingsController::singingRequiredStablePitchFrames() const
{
    return m_singingRequiredStablePitchFrames;
}

int SettingsController::clappingPitchMethod() const
{
    return m_clappingPitchMethod;
}

int SettingsController::clappingOnsetMethod() const
{
    return m_clappingOnsetMethod;
}

double SettingsController::clappingMinimumPitchConfidence() const
{
    return m_clappingMinimumPitchConfidence;
}

double SettingsController::clappingOnsetThreshold() const
{
    return m_clappingOnsetThreshold;
}

double SettingsController::clappingInputGateLevel() const
{
    return m_clappingInputGateLevel;
}

double SettingsController::clappingMinimumOnsetStrength() const
{
    return m_clappingMinimumOnsetStrength;
}

int SettingsController::clappingRequiredStablePitchFrames() const
{
    return m_clappingRequiredStablePitchFrames;
}

bool SettingsController::melodicOnboardingPromptShown() const
{
    return m_melodicOnboardingPromptShown;
}

bool SettingsController::rhythmicOnboardingPromptShown() const
{
    return m_rhythmicOnboardingPromptShown;
}

bool SettingsController::clappingOnboardingPromptShown() const
{
    return m_clappingOnboardingPromptShown;
}

bool SettingsController::singingOnboardingPromptShown() const
{
    return m_singingOnboardingPromptShown;
}

void SettingsController::resetAdvancedSettingsToDefaults()
{
    setSingingDisregardOctaveDifference(DefaultSingingDisregardOctaveDifference);
    setSingingScoringMode(DefaultSingingScoringMode);
    setSingingPitchMethod(DefaultSingingPitchMethod);
    setSingingMinimumPitchConfidence(DefaultSingingMinimumPitchConfidence);
    setSingingInputGateLevel(DefaultSingingInputGateLevel);
    setSingingRequiredStablePitchFrames(DefaultSingingRequiredStablePitchFrames);
    setClappingPitchMethod(DefaultClappingPitchMethod);
    setClappingOnsetMethod(DefaultClappingOnsetMethod);
    setClappingMinimumPitchConfidence(DefaultClappingMinimumPitchConfidence);
    setClappingOnsetThreshold(DefaultClappingOnsetThreshold);
    setClappingInputGateLevel(DefaultClappingInputGateLevel);
    setClappingMinimumOnsetStrength(DefaultClappingMinimumOnsetStrength);
    setClappingRequiredStablePitchFrames(DefaultClappingRequiredStablePitchFrames);
}

void SettingsController::setRhythmPatternCount(int rhythmPatternCount)
{
    rhythmPatternCount = std::clamp(rhythmPatternCount, 4, 16);
    if (m_rhythmPatternCount == rhythmPatternCount) {
        return;
    }

    m_rhythmPatternCount = rhythmPatternCount;
    write(u"RhythmPatternCount"_s, m_rhythmPatternCount);
    emit rhythmPatternCountChanged(m_rhythmPatternCount);
}

void SettingsController::setTestExerciseCount(int testExerciseCount)
{
    testExerciseCount = std::clamp(testExerciseCount, 5, 20);
    if (m_testExerciseCount == testExerciseCount) {
        return;
    }

    m_testExerciseCount = testExerciseCount;
    write(u"TestExerciseCount"_s, m_testExerciseCount);
    emit testExerciseCountChanged(m_testExerciseCount);
}

void SettingsController::setVolume(int volume)
{
    volume = std::clamp(volume, 0, 200);
    if (m_volume == volume) {
        return;
    }

    m_volume = volume;
    write(u"Volume"_s, m_volume);
    emit volumeChanged(m_volume);
}

void SettingsController::setPitch(int pitch)
{
    pitch = std::clamp(pitch, -12, 12);
    if (m_pitch == pitch) {
        return;
    }

    m_pitch = pitch;
    write(u"Pitch"_s, m_pitch);
    emit pitchChanged(m_pitch);
}

void SettingsController::setTempo(int tempo)
{
    tempo = std::clamp(tempo, 1, 255);
    if (m_tempo == tempo) {
        return;
    }

    m_tempo = tempo;
    m_exerciseSpeed = std::clamp(tempo, 30, 240);
    write(u"Tempo"_s, m_tempo);
    write(u"ExerciseSpeed"_s, m_exerciseSpeed);
    emit tempoChanged(m_tempo);
    emit exerciseSpeedChanged(m_exerciseSpeed);
}

void SettingsController::setExerciseSpeed(int exerciseSpeed)
{
    exerciseSpeed = std::clamp(exerciseSpeed, 30, 240);
    if (m_exerciseSpeed == exerciseSpeed) {
        return;
    }

    m_exerciseSpeed = exerciseSpeed;
    m_tempo = exerciseSpeed;
    write(u"ExerciseSpeed"_s, m_exerciseSpeed);
    write(u"Tempo"_s, m_tempo);
    emit exerciseSpeedChanged(m_exerciseSpeed);
    emit tempoChanged(m_tempo);
}

void SettingsController::setClappingSpeed(int clappingSpeed)
{
    clappingSpeed = std::clamp(clappingSpeed, 30, 120);
    if (m_clappingSpeed == clappingSpeed) {
        return;
    }

    m_clappingSpeed = clappingSpeed;
    write(u"ClappingSpeed"_s, m_clappingSpeed);
    emit clappingSpeedChanged(m_clappingSpeed);
}

void SettingsController::setInstrumentGroup(int instrumentGroup)
{
    if (m_instrumentGroup == instrumentGroup) {
        return;
    }

    m_instrumentGroup = instrumentGroup;
    write(u"InstrumentGroup"_s, m_instrumentGroup);
    emit instrumentGroupChanged(m_instrumentGroup);
}

void SettingsController::setInstrument(int instrument)
{
    instrument = std::clamp(instrument, 0, 127);
    if (m_instrument == instrument) {
        return;
    }

    m_instrument = instrument;
    write(u"Instrument"_s, m_instrument);
    emit instrumentChanged(m_instrument);
}

void SettingsController::setRhythmInstrument(int rhythmInstrument)
{
    rhythmInstrument = std::clamp(rhythmInstrument, 35, 81);
    if (m_rhythmInstrument == rhythmInstrument) {
        return;
    }

    m_rhythmInstrument = rhythmInstrument;
    write(u"RhythmInstrument"_s, m_rhythmInstrument);
    emit rhythmInstrumentChanged(m_rhythmInstrument);
}

void SettingsController::setMicrophoneInputDeviceId(const QString &deviceId)
{
    if (m_microphoneInputDeviceId == deviceId) {
        return;
    }

    m_microphoneInputDeviceId = deviceId;
    write(u"MicrophoneInputDeviceId"_s, m_microphoneInputDeviceId);
    emit microphoneInputDeviceIdChanged(m_microphoneInputDeviceId);
}

void SettingsController::setClappingCorrectnessTolerancePercent(int tolerance)
{
    tolerance = std::clamp(tolerance, 5, 100);
    if (m_clappingCorrectnessTolerancePercent == tolerance) {
        return;
    }
    m_clappingCorrectnessTolerancePercent = tolerance;
    write(u"ClappingCorrectnessTolerancePercent"_s, m_clappingCorrectnessTolerancePercent);
    emit clappingCorrectnessTolerancePercentChanged(m_clappingCorrectnessTolerancePercent);
}

void SettingsController::setSingingPitchToleranceCents(int cents)
{
    cents = std::clamp(cents, 10, 49);
    if (m_singingPitchToleranceCents == cents) {
        return;
    }
    m_singingPitchToleranceCents = cents;
    write(u"SingingPitchToleranceCents"_s, m_singingPitchToleranceCents);
    emit singingPitchToleranceCentsChanged(m_singingPitchToleranceCents);
}

void SettingsController::setSingingDisregardOctaveDifference(bool disregard)
{
    if (m_singingDisregardOctaveDifference == disregard) {
        return;
    }
    m_singingDisregardOctaveDifference = disregard;
    write(u"SingingDisregardOctaveDifference"_s, m_singingDisregardOctaveDifference);
    emit singingDisregardOctaveDifferenceChanged(m_singingDisregardOctaveDifference);
}

void SettingsController::setSingingScoringMode(int mode)
{
    mode = std::clamp(mode, 0, 1);
    if (m_singingScoringMode == mode) {
        return;
    }
    m_singingScoringMode = mode;
    write(u"SingingScoringMode"_s, m_singingScoringMode);
    emit singingScoringModeChanged(m_singingScoringMode);
}

#define MINUET_SET_INT_SETTING(Setter, Member, Key, Signal, Min, Max) \
    void SettingsController::Setter(int value) \
    { \
        value = std::clamp(value, Min, Max); \
        if (Member == value) { \
            return; \
        } \
        Member = value; \
        write(Key, Member); \
        emit Signal(Member); \
    }

#define MINUET_SET_DOUBLE_SETTING(Setter, Member, Key, Signal, Min, Max) \
    void SettingsController::Setter(double value) \
    { \
        value = std::clamp(value, Min, Max); \
        if (qFuzzyCompare(Member, value)) { \
            return; \
        } \
        Member = value; \
        write(Key, Member); \
        emit Signal(Member); \
    }

MINUET_SET_INT_SETTING(setSingingVoiceClass, m_singingVoiceClass, u"SingingVoiceClass"_s, singingVoiceClassChanged, 0, 3)
MINUET_SET_INT_SETTING(setSingingPitchMethod, m_singingPitchMethod, u"SingingPitchMethod"_s, singingPitchMethodChanged, 0, 6)
MINUET_SET_DOUBLE_SETTING(setSingingMinimumPitchConfidence,
                          m_singingMinimumPitchConfidence,
                          u"SingingMinimumPitchConfidence"_s,
                          singingMinimumPitchConfidenceChanged,
                          0.0,
                          0.95)
MINUET_SET_DOUBLE_SETTING(setSingingInputGateLevel, m_singingInputGateLevel, u"SingingInputGateLevel"_s, singingInputGateLevelChanged, 0.0, 0.25)
MINUET_SET_INT_SETTING(setSingingRequiredStablePitchFrames,
                       m_singingRequiredStablePitchFrames,
                       u"SingingRequiredStablePitchFrames"_s,
                       singingRequiredStablePitchFramesChanged,
                       1,
                       10)
MINUET_SET_INT_SETTING(setClappingPitchMethod, m_clappingPitchMethod, u"ClappingPitchMethod"_s, clappingPitchMethodChanged, 0, 6)
MINUET_SET_INT_SETTING(setClappingOnsetMethod, m_clappingOnsetMethod, u"ClappingOnsetMethod"_s, clappingOnsetMethodChanged, 0, 7)
MINUET_SET_DOUBLE_SETTING(setClappingMinimumPitchConfidence,
                          m_clappingMinimumPitchConfidence,
                          u"ClappingMinimumPitchConfidence"_s,
                          clappingMinimumPitchConfidenceChanged,
                          0.0,
                          0.95)
MINUET_SET_DOUBLE_SETTING(setClappingOnsetThreshold, m_clappingOnsetThreshold, u"ClappingOnsetThreshold"_s, clappingOnsetThresholdChanged, 0.01, 1.0)
MINUET_SET_DOUBLE_SETTING(setClappingInputGateLevel, m_clappingInputGateLevel, u"ClappingInputGateLevel"_s, clappingInputGateLevelChanged, 0.0, 0.25)
MINUET_SET_DOUBLE_SETTING(setClappingMinimumOnsetStrength,
                          m_clappingMinimumOnsetStrength,
                          u"ClappingMinimumOnsetStrength"_s,
                          clappingMinimumOnsetStrengthChanged,
                          0.0,
                          1.0)
MINUET_SET_INT_SETTING(setClappingRequiredStablePitchFrames,
                       m_clappingRequiredStablePitchFrames,
                       u"ClappingRequiredStablePitchFrames"_s,
                       clappingRequiredStablePitchFramesChanged,
                       1,
                       10)

#undef MINUET_SET_INT_SETTING
#undef MINUET_SET_DOUBLE_SETTING

void SettingsController::setMelodicOnboardingPromptShown(bool shown)
{
    if (m_melodicOnboardingPromptShown == shown) {
        return;
    }

    m_melodicOnboardingPromptShown = shown;
    write(u"MelodicOnboardingPromptShown"_s, m_melodicOnboardingPromptShown);
    emit melodicOnboardingPromptShownChanged(m_melodicOnboardingPromptShown);
}

void SettingsController::setRhythmicOnboardingPromptShown(bool shown)
{
    if (m_rhythmicOnboardingPromptShown == shown) {
        return;
    }

    m_rhythmicOnboardingPromptShown = shown;
    write(u"RhythmicOnboardingPromptShown"_s, m_rhythmicOnboardingPromptShown);
    emit rhythmicOnboardingPromptShownChanged(m_rhythmicOnboardingPromptShown);
}

void SettingsController::setClappingOnboardingPromptShown(bool shown)
{
    if (m_clappingOnboardingPromptShown == shown) {
        return;
    }

    m_clappingOnboardingPromptShown = shown;
    write(u"ClappingOnboardingPromptShown"_s, m_clappingOnboardingPromptShown);
    emit clappingOnboardingPromptShownChanged(m_clappingOnboardingPromptShown);
}

void SettingsController::setSingingOnboardingPromptShown(bool shown)
{
    if (m_singingOnboardingPromptShown == shown) {
        return;
    }

    m_singingOnboardingPromptShown = shown;
    write(u"SingingOnboardingPromptShown"_s, m_singingOnboardingPromptShown);
    emit singingOnboardingPromptShownChanged(m_singingOnboardingPromptShown);
}
}

#include "moc_settingscontroller.cpp"
