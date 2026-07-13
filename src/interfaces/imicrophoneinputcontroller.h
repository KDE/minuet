// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_IMICROPHONEINPUTCONTROLLER_H
#define MINUET_IMICROPHONEINPUTCONTROLLER_H

#include "iplugin.h"

#include <interfaces/minuetinterfacesexport.h>

#include <QVariantList>
#include <qqmlregistration.h>

namespace Minuet
{
class MINUETINTERFACES_EXPORT IMicrophoneInputController : public IPlugin
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("IMicrophoneInputController is provided by Core")

    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(double analysisTimeSeconds READ analysisTimeSeconds NOTIFY audioStatsChanged)
    Q_PROPERTY(double captureTimeSeconds READ captureTimeSeconds NOTIFY captureTimeChanged)
    Q_PROPERTY(bool analysisPending READ analysisPending NOTIFY analysisPendingChanged)

    Q_PROPERTY(Preset preset READ preset WRITE setPreset NOTIFY presetChanged)
    Q_PROPERTY(AnalysisMode analysisMode READ analysisMode WRITE setAnalysisMode NOTIFY analysisModeChanged)
    Q_PROPERTY(VoiceClass voiceClass READ voiceClass WRITE setVoiceClass NOTIFY voiceClassChanged)
    Q_PROPERTY(PitchMethod pitchMethod READ pitchMethod WRITE setPitchMethod NOTIFY pitchMethodChanged)
    Q_PROPERTY(OnsetMethod onsetMethod READ onsetMethod WRITE setOnsetMethod NOTIFY onsetMethodChanged)
    Q_PROPERTY(int expectedMidiNote READ expectedMidiNote WRITE setExpectedMidiNote NOTIFY expectedMidiNoteChanged)
    Q_PROPERTY(bool disregardOctaveDifference READ disregardOctaveDifference WRITE setDisregardOctaveDifference NOTIFY disregardOctaveDifferenceChanged)

    Q_PROPERTY(double targetBpm READ targetBpm WRITE setTargetBpm NOTIFY targetBpmChanged)
    Q_PROPERTY(double minimumExpectedOnsetIntervalMs READ minimumExpectedOnsetIntervalMs WRITE setMinimumExpectedOnsetIntervalMs NOTIFY
                   minimumExpectedOnsetIntervalMsChanged)
    Q_PROPERTY(double minimumPitchConfidence READ minimumPitchConfidence WRITE setMinimumPitchConfidence NOTIFY minimumPitchConfidenceChanged)
    Q_PROPERTY(double pitchSilenceDb READ pitchSilenceDb WRITE setPitchSilenceDb NOTIFY pitchSilenceDbChanged)
    Q_PROPERTY(double onsetThreshold READ onsetThreshold WRITE setOnsetThreshold NOTIFY onsetThresholdChanged)
    Q_PROPERTY(double inputGateLevel READ inputGateLevel WRITE setInputGateLevel NOTIFY inputGateLevelChanged)
    Q_PROPERTY(double noiseFloorLevel READ noiseFloorLevel NOTIFY noiseFloorLevelChanged)
    Q_PROPERTY(bool inputGateOpen READ inputGateOpen NOTIFY audioLevelChanged)
    Q_PROPERTY(bool noiseCalibrationActive READ noiseCalibrationActive NOTIFY noiseCalibrationActiveChanged)
    Q_PROPERTY(double minimumOnsetStrength READ minimumOnsetStrength WRITE setMinimumOnsetStrength NOTIFY minimumOnsetStrengthChanged)
    Q_PROPERTY(int requiredStablePitchFrames READ requiredStablePitchFrames WRITE setRequiredStablePitchFrames NOTIFY requiredStablePitchFramesChanged)
    Q_PROPERTY(int stablePitchFrameCount READ stablePitchFrameCount NOTIFY pitchChanged)

    Q_PROPERTY(QString inputDeviceDescription READ inputDeviceDescription NOTIFY inputDeviceDescriptionChanged)
    Q_PROPERTY(QVariantList inputDevices READ inputDevices NOTIFY inputDevicesChanged)
    Q_PROPERTY(bool inputDeviceAvailable READ inputDeviceAvailable NOTIFY inputDeviceAvailableChanged)
    Q_PROPERTY(QString inputDeviceId READ inputDeviceId WRITE setInputDeviceId NOTIFY inputDeviceIdChanged)
    Q_PROPERTY(double audioLevel READ audioLevel NOTIFY audioLevelChanged)
    Q_PROPERTY(double peakLevel READ peakLevel NOTIFY audioLevelChanged)
    Q_PROPERTY(quint64 bytesRead READ bytesRead NOTIFY audioStatsChanged)
    Q_PROPERTY(quint64 processedSamples READ processedSamples NOTIFY audioStatsChanged)

    Q_PROPERTY(double frequencyHz READ frequencyHz NOTIFY pitchChanged)
    Q_PROPERTY(QString noteName READ noteName NOTIFY pitchChanged)
    Q_PROPERTY(int midiNote READ midiNote NOTIFY pitchChanged)
    Q_PROPERTY(double cents READ cents NOTIFY pitchChanged)
    Q_PROPERTY(double pitchConfidence READ pitchConfidence NOTIFY pitchChanged)
    Q_PROPERTY(bool voiced READ voiced NOTIFY pitchChanged)
    Q_PROPERTY(QString pitchStatus READ pitchStatus NOTIFY pitchChanged)

    Q_PROPERTY(int onsetCount READ onsetCount NOTIFY rhythmChanged)
    Q_PROPERTY(double lastOnsetSeconds READ lastOnsetSeconds NOTIFY rhythmChanged)
    Q_PROPERTY(double detectedBpm READ detectedBpm NOTIFY rhythmChanged)
    Q_PROPERTY(double lastTimingErrorMs READ lastTimingErrorMs NOTIFY rhythmChanged)
    Q_PROPERTY(QString rhythmStatus READ rhythmStatus NOTIFY rhythmChanged)

public:
    enum Preset {
        Singing = 0,
        Clapping,
    };
    Q_ENUM(Preset)

    enum AnalysisMode {
        SingingPitchOnly = 0,
        ClappingOnsetOnly = 2,
    };
    Q_ENUM(AnalysisMode)

    enum VoiceClass {
        Soprano = 0,
        Alto,
        Tenor,
        Bass,
    };
    Q_ENUM(VoiceClass)

    enum PitchMethod {
        YinFft = 0,
        Yin,
        YinFast,
        MComb,
        Schmitt,
        SpecAcf,
        FComb,
    };
    Q_ENUM(PitchMethod)

    enum OnsetMethod {
        Complex = 0,
        Hfc,
        Energy,
        SpecFlux,
        Phase,
        SpecDiff,
        Kl,
        Mkl,
    };
    Q_ENUM(OnsetMethod)

    ~IMicrophoneInputController() override = default;

    virtual bool running() const = 0;
    virtual QString status() const = 0;
    virtual double analysisTimeSeconds() const = 0;
    virtual double captureTimeSeconds() const = 0;
    virtual bool analysisPending() const = 0;
    virtual Preset preset() const = 0;
    virtual AnalysisMode analysisMode() const = 0;
    virtual VoiceClass voiceClass() const = 0;
    virtual PitchMethod pitchMethod() const = 0;
    virtual OnsetMethod onsetMethod() const = 0;
    virtual int expectedMidiNote() const = 0;
    virtual bool disregardOctaveDifference() const = 0;
    virtual double targetBpm() const = 0;
    virtual double minimumExpectedOnsetIntervalMs() const = 0;
    virtual double minimumPitchConfidence() const = 0;
    virtual double pitchSilenceDb() const = 0;
    virtual double onsetThreshold() const = 0;
    virtual double inputGateLevel() const = 0;
    virtual double noiseFloorLevel() const = 0;
    virtual bool inputGateOpen() const = 0;
    virtual bool noiseCalibrationActive() const = 0;
    virtual double minimumOnsetStrength() const = 0;
    virtual int requiredStablePitchFrames() const = 0;
    virtual int stablePitchFrameCount() const = 0;
    virtual QString inputDeviceDescription() const = 0;
    virtual QVariantList inputDevices() const = 0;
    virtual bool inputDeviceAvailable() const = 0;
    virtual QString inputDeviceId() const = 0;
    virtual double audioLevel() const = 0;
    virtual double peakLevel() const = 0;
    virtual quint64 bytesRead() const = 0;
    virtual quint64 processedSamples() const = 0;
    virtual double frequencyHz() const = 0;
    virtual QString noteName() const = 0;
    virtual int midiNote() const = 0;
    virtual double cents() const = 0;
    virtual double pitchConfidence() const = 0;
    virtual bool voiced() const = 0;
    virtual QString pitchStatus() const = 0;
    virtual int onsetCount() const = 0;
    virtual double lastOnsetSeconds() const = 0;
    virtual double detectedBpm() const = 0;
    virtual double lastTimingErrorMs() const = 0;
    virtual QString rhythmStatus() const = 0;

public Q_SLOTS:
    virtual void setPreset(Preset preset) = 0;
    virtual void setAnalysisMode(AnalysisMode mode) = 0;
    virtual void setVoiceClass(VoiceClass voiceClass) = 0;
    virtual void setPitchMethod(PitchMethod pitchMethod) = 0;
    virtual void setOnsetMethod(OnsetMethod onsetMethod) = 0;
    virtual void setExpectedMidiNote(int midiNote) = 0;
    virtual void setDisregardOctaveDifference(bool disregard) = 0;
    virtual void setTargetBpm(double targetBpm) = 0;
    virtual void setMinimumExpectedOnsetIntervalMs(double intervalMs) = 0;
    virtual void setMinimumPitchConfidence(double confidence) = 0;
    virtual void setPitchSilenceDb(double silenceDb) = 0;
    virtual void setOnsetThreshold(double threshold) = 0;
    virtual void setInputGateLevel(double inputGateLevel) = 0;
    virtual void setMinimumOnsetStrength(double strength) = 0;
    virtual void setRequiredStablePitchFrames(int frames) = 0;
    virtual void setInputDeviceId(const QString &deviceId) = 0;
    virtual void start() = 0;
    virtual void stop() = 0;
    virtual void resetInputAnalysisState() = 0;
    virtual void finalizeInputAnalysis() = 0;
    virtual void calibrateNoiseFloor() = 0;

    virtual QString presetName(int preset) const = 0;
    virtual QString voiceClassName(int voiceClass) const = 0;
    virtual QString pitchMethodName(int pitchMethod) const = 0;
    virtual QString onsetMethodName(int onsetMethod) const = 0;

Q_SIGNALS:
    void runningChanged();
    void statusChanged();
    void captureTimeChanged();
    void analysisPendingChanged();
    void presetChanged();
    void analysisModeChanged();
    void voiceClassChanged();
    void pitchMethodChanged();
    void onsetMethodChanged();
    void expectedMidiNoteChanged();
    void disregardOctaveDifferenceChanged();
    void targetBpmChanged();
    void minimumExpectedOnsetIntervalMsChanged();
    void minimumPitchConfidenceChanged();
    void pitchSilenceDbChanged();
    void onsetThresholdChanged();
    void inputGateLevelChanged();
    void noiseFloorLevelChanged();
    void noiseCalibrationActiveChanged();
    void minimumOnsetStrengthChanged();
    void requiredStablePitchFramesChanged();
    void inputDeviceDescriptionChanged();
    void inputDevicesChanged();
    void inputDeviceAvailableChanged();
    void inputDeviceIdChanged();
    void audioLevelChanged();
    void audioStatsChanged();
    void pitchChanged();
    void rhythmChanged();
    void pitchDetected(double seconds, int midiNote, double cents, double confidence);
    void onsetDetected(double seconds, double strength);
    void inputAnalysisFinished();
    void inputAnalysisFailed(const QString &message);

protected:
    explicit IMicrophoneInputController(QObject *parent = nullptr);
};
}

Q_DECLARE_INTERFACE(Minuet::IMicrophoneInputController, "org.kde.minuet.IMicrophoneInputController")

#endif
