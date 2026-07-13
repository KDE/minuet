// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_SETTINGSCONTROLLER_H
#define MINUET_SETTINGSCONTROLLER_H

#include <QObject>
#include <QString>

namespace Minuet
{
class SettingsController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rhythmPatternCount READ rhythmPatternCount WRITE setRhythmPatternCount NOTIFY rhythmPatternCountChanged)
    Q_PROPERTY(int testExerciseCount READ testExerciseCount WRITE setTestExerciseCount NOTIFY testExerciseCountChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(int pitch READ pitch WRITE setPitch NOTIFY pitchChanged)
    Q_PROPERTY(int tempo READ tempo WRITE setTempo NOTIFY tempoChanged)
    Q_PROPERTY(int exerciseSpeed READ exerciseSpeed WRITE setExerciseSpeed NOTIFY exerciseSpeedChanged)
    Q_PROPERTY(int clappingSpeed READ clappingSpeed WRITE setClappingSpeed NOTIFY clappingSpeedChanged)
    Q_PROPERTY(int instrumentGroup READ instrumentGroup WRITE setInstrumentGroup NOTIFY instrumentGroupChanged)
    Q_PROPERTY(int instrument READ instrument WRITE setInstrument NOTIFY instrumentChanged)
    Q_PROPERTY(int rhythmInstrument READ rhythmInstrument WRITE setRhythmInstrument NOTIFY rhythmInstrumentChanged)
    Q_PROPERTY(QString microphoneInputDeviceId READ microphoneInputDeviceId WRITE setMicrophoneInputDeviceId NOTIFY microphoneInputDeviceIdChanged)
    Q_PROPERTY(int clappingCorrectnessTolerancePercent READ clappingCorrectnessTolerancePercent WRITE setClappingCorrectnessTolerancePercent NOTIFY
                   clappingCorrectnessTolerancePercentChanged)
    Q_PROPERTY(int singingPitchToleranceCents READ singingPitchToleranceCents WRITE setSingingPitchToleranceCents NOTIFY singingPitchToleranceCentsChanged)
    Q_PROPERTY(bool singingDisregardOctaveDifference READ singingDisregardOctaveDifference WRITE setSingingDisregardOctaveDifference NOTIFY
                   singingDisregardOctaveDifferenceChanged)
    Q_PROPERTY(int singingScoringMode READ singingScoringMode WRITE setSingingScoringMode NOTIFY singingScoringModeChanged)
    Q_PROPERTY(int singingVoiceClass READ singingVoiceClass WRITE setSingingVoiceClass NOTIFY singingVoiceClassChanged)
    Q_PROPERTY(int singingPitchMethod READ singingPitchMethod WRITE setSingingPitchMethod NOTIFY singingPitchMethodChanged)
    Q_PROPERTY(int singingOnsetMethod READ singingOnsetMethod WRITE setSingingOnsetMethod NOTIFY singingOnsetMethodChanged)
    Q_PROPERTY(double singingMinimumPitchConfidence READ singingMinimumPitchConfidence WRITE setSingingMinimumPitchConfidence NOTIFY
                   singingMinimumPitchConfidenceChanged)
    Q_PROPERTY(double singingOnsetThreshold READ singingOnsetThreshold WRITE setSingingOnsetThreshold NOTIFY singingOnsetThresholdChanged)
    Q_PROPERTY(double singingInputGateLevel READ singingInputGateLevel WRITE setSingingInputGateLevel NOTIFY singingInputGateLevelChanged)
    Q_PROPERTY(double singingMinimumOnsetStrength READ singingMinimumOnsetStrength WRITE setSingingMinimumOnsetStrength NOTIFY
                   singingMinimumOnsetStrengthChanged)
    Q_PROPERTY(int singingRequiredStablePitchFrames READ singingRequiredStablePitchFrames WRITE setSingingRequiredStablePitchFrames NOTIFY
                   singingRequiredStablePitchFramesChanged)
    Q_PROPERTY(int clappingPitchMethod READ clappingPitchMethod WRITE setClappingPitchMethod NOTIFY clappingPitchMethodChanged)
    Q_PROPERTY(int clappingOnsetMethod READ clappingOnsetMethod WRITE setClappingOnsetMethod NOTIFY clappingOnsetMethodChanged)
    Q_PROPERTY(double clappingMinimumPitchConfidence READ clappingMinimumPitchConfidence WRITE setClappingMinimumPitchConfidence NOTIFY
                   clappingMinimumPitchConfidenceChanged)
    Q_PROPERTY(double clappingOnsetThreshold READ clappingOnsetThreshold WRITE setClappingOnsetThreshold NOTIFY clappingOnsetThresholdChanged)
    Q_PROPERTY(double clappingInputGateLevel READ clappingInputGateLevel WRITE setClappingInputGateLevel NOTIFY clappingInputGateLevelChanged)
    Q_PROPERTY(double clappingMinimumOnsetStrength READ clappingMinimumOnsetStrength WRITE setClappingMinimumOnsetStrength NOTIFY
                   clappingMinimumOnsetStrengthChanged)
    Q_PROPERTY(int clappingRequiredStablePitchFrames READ clappingRequiredStablePitchFrames WRITE setClappingRequiredStablePitchFrames NOTIFY
                   clappingRequiredStablePitchFramesChanged)
    Q_PROPERTY(
        bool melodicOnboardingPromptShown READ melodicOnboardingPromptShown WRITE setMelodicOnboardingPromptShown NOTIFY melodicOnboardingPromptShownChanged)
    Q_PROPERTY(bool rhythmicOnboardingPromptShown READ rhythmicOnboardingPromptShown WRITE setRhythmicOnboardingPromptShown NOTIFY
                   rhythmicOnboardingPromptShownChanged)
    Q_PROPERTY(bool clappingOnboardingPromptShown READ clappingOnboardingPromptShown WRITE setClappingOnboardingPromptShown NOTIFY
                   clappingOnboardingPromptShownChanged)
    Q_PROPERTY(
        bool singingOnboardingPromptShown READ singingOnboardingPromptShown WRITE setSingingOnboardingPromptShown NOTIFY singingOnboardingPromptShownChanged)

public:
    ~SettingsController() override = default;

    int rhythmPatternCount() const;
    int testExerciseCount() const;
    int volume() const;
    int pitch() const;
    int tempo() const;
    int exerciseSpeed() const;
    int clappingSpeed() const;
    int instrumentGroup() const;
    int instrument() const;
    int rhythmInstrument() const;
    QString microphoneInputDeviceId() const;
    int clappingCorrectnessTolerancePercent() const;
    int singingPitchToleranceCents() const;
    bool singingDisregardOctaveDifference() const;
    int singingScoringMode() const;
    int singingVoiceClass() const;
    int singingPitchMethod() const;
    int singingOnsetMethod() const;
    double singingMinimumPitchConfidence() const;
    double singingOnsetThreshold() const;
    double singingInputGateLevel() const;
    double singingMinimumOnsetStrength() const;
    int singingRequiredStablePitchFrames() const;
    int clappingPitchMethod() const;
    int clappingOnsetMethod() const;
    double clappingMinimumPitchConfidence() const;
    double clappingOnsetThreshold() const;
    double clappingInputGateLevel() const;
    double clappingMinimumOnsetStrength() const;
    int clappingRequiredStablePitchFrames() const;
    bool melodicOnboardingPromptShown() const;
    bool rhythmicOnboardingPromptShown() const;
    bool clappingOnboardingPromptShown() const;
    bool singingOnboardingPromptShown() const;

    Q_INVOKABLE void resetAdvancedSettingsToDefaults();

public Q_SLOTS:
    void setRhythmPatternCount(int rhythmPatternCount);
    void setTestExerciseCount(int testExerciseCount);
    void setVolume(int volume);
    void setPitch(int pitch);
    void setTempo(int tempo);
    void setExerciseSpeed(int exerciseSpeed);
    void setClappingSpeed(int clappingSpeed);
    void setInstrumentGroup(int instrumentGroup);
    void setInstrument(int instrument);
    void setRhythmInstrument(int rhythmInstrument);
    void setMicrophoneInputDeviceId(const QString &deviceId);
    void setClappingCorrectnessTolerancePercent(int tolerance);
    void setSingingPitchToleranceCents(int cents);
    void setSingingDisregardOctaveDifference(bool disregard);
    void setSingingScoringMode(int mode);
    void setSingingVoiceClass(int voiceClass);
    void setSingingPitchMethod(int method);
    void setSingingOnsetMethod(int method);
    void setSingingMinimumPitchConfidence(double confidence);
    void setSingingOnsetThreshold(double threshold);
    void setSingingInputGateLevel(double inputGateLevel);
    void setSingingMinimumOnsetStrength(double strength);
    void setSingingRequiredStablePitchFrames(int frames);
    void setClappingPitchMethod(int method);
    void setClappingOnsetMethod(int method);
    void setClappingMinimumPitchConfidence(double confidence);
    void setClappingOnsetThreshold(double threshold);
    void setClappingInputGateLevel(double inputGateLevel);
    void setClappingMinimumOnsetStrength(double strength);
    void setClappingRequiredStablePitchFrames(int frames);
    void setMelodicOnboardingPromptShown(bool shown);
    void setRhythmicOnboardingPromptShown(bool shown);
    void setClappingOnboardingPromptShown(bool shown);
    void setSingingOnboardingPromptShown(bool shown);

Q_SIGNALS:
    void rhythmPatternCountChanged(int rhythmPatternCount);
    void testExerciseCountChanged(int testExerciseCount);
    void volumeChanged(int volume);
    void pitchChanged(int pitch);
    void tempoChanged(int tempo);
    void exerciseSpeedChanged(int exerciseSpeed);
    void clappingSpeedChanged(int clappingSpeed);
    void instrumentGroupChanged(int instrumentGroup);
    void instrumentChanged(int instrument);
    void rhythmInstrumentChanged(int rhythmInstrument);
    void microphoneInputDeviceIdChanged(const QString &deviceId);
    void clappingCorrectnessTolerancePercentChanged(int tolerance);
    void singingPitchToleranceCentsChanged(int cents);
    void singingDisregardOctaveDifferenceChanged(bool disregard);
    void singingScoringModeChanged(int mode);
    void singingVoiceClassChanged(int voiceClass);
    void singingPitchMethodChanged(int method);
    void singingOnsetMethodChanged(int method);
    void singingMinimumPitchConfidenceChanged(double confidence);
    void singingOnsetThresholdChanged(double threshold);
    void singingInputGateLevelChanged(double inputGateLevel);
    void singingMinimumOnsetStrengthChanged(double strength);
    void singingRequiredStablePitchFramesChanged(int frames);
    void clappingPitchMethodChanged(int method);
    void clappingOnsetMethodChanged(int method);
    void clappingMinimumPitchConfidenceChanged(double confidence);
    void clappingOnsetThresholdChanged(double threshold);
    void clappingInputGateLevelChanged(double inputGateLevel);
    void clappingMinimumOnsetStrengthChanged(double strength);
    void clappingRequiredStablePitchFramesChanged(int frames);
    void melodicOnboardingPromptShownChanged(bool shown);
    void rhythmicOnboardingPromptShownChanged(bool shown);
    void clappingOnboardingPromptShownChanged(bool shown);
    void singingOnboardingPromptShownChanged(bool shown);

private:
    friend class Core;

    explicit SettingsController(QObject *parent = nullptr);

    void load();
    void write(const QString &key, int value);
    void write(const QString &key, double value);
    void write(const QString &key, bool value);
    void write(const QString &key, const QString &value);

    static constexpr bool DefaultSingingDisregardOctaveDifference = true;
    static constexpr int DefaultSingingScoringMode = 0;
    static constexpr int DefaultSingingPitchMethod = 1;
    static constexpr int DefaultSingingOnsetMethod = 0;
    static constexpr double DefaultSingingMinimumPitchConfidence = 0.05;
    static constexpr double DefaultSingingOnsetThreshold = 0.14;
    static constexpr double DefaultSingingInputGateLevel = 0.006;
    static constexpr double DefaultSingingMinimumOnsetStrength = 0.006;
    static constexpr int DefaultSingingRequiredStablePitchFrames = 2;
    static constexpr int DefaultClappingPitchMethod = 0;
    static constexpr int DefaultClappingOnsetMethod = 1;
    static constexpr double DefaultClappingMinimumPitchConfidence = 0.70;
    static constexpr double DefaultClappingOnsetThreshold = 0.30;
    static constexpr double DefaultClappingInputGateLevel = 0.0;
    static constexpr double DefaultClappingMinimumOnsetStrength = 0.015;
    static constexpr int DefaultClappingRequiredStablePitchFrames = 2;

    int m_rhythmPatternCount = 4;
    int m_testExerciseCount = 10;
    int m_volume = 100;
    int m_pitch = 0;
    int m_tempo = 60;
    int m_exerciseSpeed = 60;
    int m_clappingSpeed = 45;
    int m_instrumentGroup = -1;
    int m_instrument = 0;
    int m_rhythmInstrument = 37;
    QString m_microphoneInputDeviceId;
    int m_clappingCorrectnessTolerancePercent = 25;
    int m_singingPitchToleranceCents = 49;
    bool m_singingDisregardOctaveDifference = DefaultSingingDisregardOctaveDifference;
    int m_singingScoringMode = DefaultSingingScoringMode;
    int m_singingVoiceClass = 2;
    int m_singingPitchMethod = DefaultSingingPitchMethod;
    int m_singingOnsetMethod = DefaultSingingOnsetMethod;
    double m_singingMinimumPitchConfidence = DefaultSingingMinimumPitchConfidence;
    double m_singingOnsetThreshold = DefaultSingingOnsetThreshold;
    double m_singingInputGateLevel = DefaultSingingInputGateLevel;
    double m_singingMinimumOnsetStrength = DefaultSingingMinimumOnsetStrength;
    int m_singingRequiredStablePitchFrames = DefaultSingingRequiredStablePitchFrames;
    int m_clappingPitchMethod = DefaultClappingPitchMethod;
    int m_clappingOnsetMethod = DefaultClappingOnsetMethod;
    double m_clappingMinimumPitchConfidence = DefaultClappingMinimumPitchConfidence;
    double m_clappingOnsetThreshold = DefaultClappingOnsetThreshold;
    double m_clappingInputGateLevel = DefaultClappingInputGateLevel;
    double m_clappingMinimumOnsetStrength = DefaultClappingMinimumOnsetStrength;
    int m_clappingRequiredStablePitchFrames = DefaultClappingRequiredStablePitchFrames;
    bool m_melodicOnboardingPromptShown = false;
    bool m_rhythmicOnboardingPromptShown = false;
    bool m_clappingOnboardingPromptShown = false;
    bool m_singingOnboardingPromptShown = false;
};
}

#endif
