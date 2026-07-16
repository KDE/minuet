// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "aubioanalysisworker.h"

#include <interfaces/imicrophoneinputcontroller.h>

#include <QAudioFormat>
#include <QMediaDevices>
#include <QPointer>
#include <QString>
#include <QTimer>
#include <QThread>
#include <QVariantList>

#include <atomic>
#include <deque>
#include <memory>

class QAudioSource;
class QIODevice;

class AubioMicrophoneInputController : public Minuet::IMicrophoneInputController
{
    Q_OBJECT
#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    Q_PLUGIN_METADATA(IID "org.kde.minuet.IPlugin" FILE "aubiomicrophoneinputcontroller.json")
#endif
    Q_INTERFACES(Minuet::IPlugin)
    Q_INTERFACES(Minuet::IMicrophoneInputController)

public:
    explicit AubioMicrophoneInputController(QObject *parent = nullptr);
    ~AubioMicrophoneInputController() override;

    bool running() const override;
    QString status() const override;
    double analysisTimeSeconds() const override;
    double captureTimeSeconds() const override;
    bool analysisPending() const override;

    Preset preset() const override;
    void setPreset(Preset preset) override;

    AnalysisMode analysisMode() const override;
    void setAnalysisMode(AnalysisMode mode) override;

    VoiceClass voiceClass() const override;
    void setVoiceClass(VoiceClass voiceClass) override;

    PitchMethod pitchMethod() const override;
    void setPitchMethod(PitchMethod pitchMethod) override;

    OnsetMethod onsetMethod() const override;
    void setOnsetMethod(OnsetMethod onsetMethod) override;

    double minimumPitchConfidence() const override;
    void setMinimumPitchConfidence(double confidence) override;

    double pitchSilenceDb() const override;
    void setPitchSilenceDb(double silenceDb) override;

    double onsetThreshold() const override;
    void setOnsetThreshold(double threshold) override;

    double inputGateLevel() const override;
    void setInputGateLevel(double inputGateLevel) override;

    double noiseFloorLevel() const override;
    bool inputGateOpen() const override;
    bool noiseCalibrationActive() const override;

    double minimumOnsetStrength() const override;
    void setMinimumOnsetStrength(double strength) override;

    int requiredStablePitchFrames() const override;
    void setRequiredStablePitchFrames(int frames) override;
    int stablePitchFrameCount() const override;

    QString inputDeviceDescription() const override;
    QVariantList inputDevices() const override;
    bool inputDeviceAvailable() const override;
    QString inputDeviceId() const override;
    void setInputDeviceId(const QString &deviceId) override;
    double audioLevel() const override;
    double peakLevel() const override;
    quint64 bytesRead() const override;
    quint64 processedSamples() const override;

    double frequencyHz() const override;
    QString noteName() const override;
    int midiNote() const override;
    double cents() const override;
    double pitchConfidence() const override;
    bool voiced() const override;

    int onsetCount() const override;
    double lastOnsetSeconds() const override;

    Q_INVOKABLE void start() override;
    Q_INVOKABLE void stop() override;
    Q_INVOKABLE void resetInputAnalysisState() override;
    Q_INVOKABLE void finalizeInputAnalysis() override;
    Q_INVOKABLE void calibrateNoiseFloor() override;
    Q_INVOKABLE QString presetName(int preset) const override;
    Q_INVOKABLE QString voiceClassName(int voiceClass) const override;
    Q_INVOKABLE QString pitchMethodName(int pitchMethod) const override;
    Q_INVOKABLE QString onsetMethodName(int onsetMethod) const override;
    Q_INVOKABLE double voiceClassMinHz(int voiceClass) const;
    Q_INVOKABLE double voiceClassMaxHz(int voiceClass) const;

private:
    void setStatus(const QString &status);
    void resetRuntimeState();
    void resetDetectionState();
    bool ensureMicrophonePermission();
    bool configureAudioInput();
    void readAudioData();
    void applyUnvoicedResult(const QString &reason = QString());
    void applyCalibratedDetectorThresholds(double noiseFloor);
    void updateInputDevices();
    void resetIfRunning();
    void applyPreset(Preset preset, bool restartIfRunning);
    AubioAnalysisWorker::Config workerConfig() const;
    void updateWorkerConfig();
    void handleWorkerPitch(double seconds, bool voiced, double frequencyHz, double confidence, const QString &reason);
    void handleWorkerOnset(double onsetSeconds, double strength);
    void stopAudioCapture();

    static QString noteNameForMidi(int midiNote);
    static double frequencyForMidi(int midiNote);
    static double midiFromFrequency(double frequencyHz);
    static const char *aubioPitchMethodName(PitchMethod method);
    static const char *aubioOnsetMethodName(OnsetMethod method);

    double minFrequencyForCurrentVoiceClass() const;
    double maxFrequencyForCurrentVoiceClass() const;
    bool pitchDetectorEnabled() const;
    bool onsetDetectorEnabled() const;
    QString analysisModeName(AnalysisMode mode) const;

    bool m_running = false;
    bool m_analysisPending = false;
    QString m_status;
    bool m_microphonePermissionRequestPending = false;

    Preset m_preset = Singing;
    AnalysisMode m_analysisMode = SingingPitchOnly;
    VoiceClass m_voiceClass = Tenor;
    PitchMethod m_pitchMethod = YinFft;
    OnsetMethod m_onsetMethod = Hfc;
    double m_minimumPitchConfidence = 0.12;
    double m_pitchSilenceDb = -55.0;
    double m_onsetThreshold = 0.16;
    double m_inputGateLevel = 0.012;
    double m_noiseFloorLevel = 0.0;
    double m_minimumOnsetStrength = 0.01;
    int m_requiredStablePitchFrames = 4;
    double m_calibratedOnsetStrengthFloor = 0.0;

    bool m_noiseCalibrationActive = false;
    double m_noiseCalibrationSumSquares = 0.0;
    quint64 m_noiseCalibrationSamples = 0;

    int m_stablePitchFrameCount = 0;

    QString m_inputDeviceDescription;
    QVariantList m_inputDevices;
    QString m_inputDeviceId;
    double m_audioLevel = 0.0;
    double m_peakLevel = 0.0;
    quint64 m_bytesRead = 0;
    quint64 m_capturedSamples = 0;
    qsizetype m_queuedAnalysisBytes = 0;

    double m_frequencyHz = 0.0;
    int m_midiNote = -1;
    double m_cents = 0.0;
    double m_pitchConfidence = 0.0;
    bool m_voiced = false;

    int m_onsetCount = 0;
    double m_lastOnsetSeconds = -1.0;

    QAudioFormat m_audioFormat;
    QMediaDevices m_mediaDevices;
    std::unique_ptr<QAudioSource> m_audioSource;
    QPointer<QIODevice> m_audioDevice;
    QTimer m_pollTimer;

    int m_sampleRate = 48000;
    quint64 m_processedSamples = 0;

    QThread m_analysisThread;
    AubioAnalysisWorker *m_analysisWorker = nullptr;
    std::shared_ptr<std::atomic<quint64>> m_activeGeneration;
    quint64 m_generation = 0;
};
