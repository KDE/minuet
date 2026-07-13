// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <interfaces/imicrophoneinputcontroller.h>

#include <QAudioFormat>
#include <QMediaDevices>
#include <QPointer>
#include <QString>
#include <QTimer>
#include <QVariantList>

#include <aubio/aubio.h>

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

    int expectedMidiNote() const override;
    void setExpectedMidiNote(int midiNote) override;

    bool disregardOctaveDifference() const override;
    void setDisregardOctaveDifference(bool disregard) override;

    double targetBpm() const override;
    void setTargetBpm(double targetBpm) override;

    double minimumExpectedOnsetIntervalMs() const override;
    void setMinimumExpectedOnsetIntervalMs(double intervalMs) override;

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
    QString pitchStatus() const override;
    QString detectedVoiceClass() const;

    int onsetCount() const override;
    double lastOnsetSeconds() const override;
    double detectedBpm() const override;
    double lastTimingErrorMs() const override;
    QString rhythmStatus() const override;

    Q_INVOKABLE void start() override;
    Q_INVOKABLE void stop() override;
    Q_INVOKABLE void resetInputAnalysisState() override;
    Q_INVOKABLE void calibrateNoiseFloor() override;
    Q_INVOKABLE QString presetName(int preset) const override;
    Q_INVOKABLE QString voiceClassName(int voiceClass) const override;
    Q_INVOKABLE QString pitchMethodName(int pitchMethod) const override;
    Q_INVOKABLE QString onsetMethodName(int onsetMethod) const override;
    Q_INVOKABLE double voiceClassMinHz(int voiceClass) const;
    Q_INVOKABLE double voiceClassMaxHz(int voiceClass) const;

private:
    struct AubioPitchDeleter {
        void operator()(aubio_pitch_t *pitch) const { if (pitch) del_aubio_pitch(pitch); }
    };
    struct AubioOnsetDeleter {
        void operator()(aubio_onset_t *onset) const { if (onset) del_aubio_onset(onset); }
    };
    struct AubioFVecDeleter {
        void operator()(fvec_t *vec) const { if (vec) del_fvec(vec); }
    };

    using PitchPtr = std::unique_ptr<aubio_pitch_t, AubioPitchDeleter>;
    using OnsetPtr = std::unique_ptr<aubio_onset_t, AubioOnsetDeleter>;
    using FVecPtr = std::unique_ptr<fvec_t, AubioFVecDeleter>;

    void setStatus(const QString &status);
    void resetRuntimeState();
    void resetDetectionState();
    bool ensureMicrophonePermission();
    bool configureAudioInput();
    bool recreateAubioObjects();
    void destroyAubioObjects();
    void readAudioData();
    void appendSamplesFromBytes(const QByteArray &bytes);
    void processPendingSamples();
    void processHop();
    void processPitchFrame(double timeSeconds);
    void processOnsetFrame(double fallbackTimeSeconds);
    void applyPitchResult(double timeSeconds, double frequencyHz, double confidence);
    void applyUnvoicedResult(const QString &reason = QString());
    bool acceptStablePitchCandidate(double frequencyHz);
    double scoreConstrainedFrequency(double frequencyHz) const;
    double smoothedAcceptedFrequency(double frequencyHz);
    void resetPitchCandidate();
    void rememberOnsetDescriptor(double strength);
    double adaptiveMinimumOnsetStrength() const;
    void updateNoiseCalibration(double sumSquares, int sampleCount);
    void applyCalibratedDetectorThresholds(double noiseFloor);
    void updateInputDevices();
    void registerOnset(double onsetSeconds, double strength);
    void updateDetectedTempo(double onsetSeconds);
    void resetIfRunning();
    void applyPreset(Preset preset, bool restartIfRunning);
    void maybePrintDebug(double timeSeconds, double frequencyHz, double confidence);

    static QString noteNameForMidi(int midiNote);
    static double frequencyForMidi(int midiNote);
    static double midiFromFrequency(double frequencyHz);
    static const char *aubioPitchMethodName(PitchMethod method);
    static const char *aubioOnsetMethodName(OnsetMethod method);

    double minFrequencyForCurrentVoiceClass() const;
    double maxFrequencyForCurrentVoiceClass() const;
    QString voiceClassForFrequency(double frequencyHz) const;
    QString classifyPitch(double frequencyHz, double cents, double confidence) const;
    QString classifyRhythm(double timingErrorMs) const;
    bool pitchDetectorEnabled() const;
    bool onsetDetectorEnabled() const;
    QString analysisModeName(AnalysisMode mode) const;

    bool m_running = false;
    QString m_status;
    bool m_microphonePermissionRequestPending = false;

    Preset m_preset = Singing;
    AnalysisMode m_analysisMode = SingingPitchOnly;
    VoiceClass m_voiceClass = Tenor;
    PitchMethod m_pitchMethod = YinFft;
    OnsetMethod m_onsetMethod = Hfc;
    int m_expectedMidiNote = -1;
    bool m_disregardOctaveDifference = true;

    double m_targetBpm = 90.0;
    double m_minimumExpectedOnsetIntervalMs = 0.0;
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

    double m_candidateFrequencyHz = 0.0;
    int m_candidateMidiNote = -1;
    int m_stablePitchFrameCount = 0;
    std::deque<double> m_recentAcceptedFrequencies;
    std::deque<double> m_recentOnsetDescriptorValues;

    QString m_inputDeviceDescription;
    QVariantList m_inputDevices;
    QString m_inputDeviceId;
    double m_audioLevel = 0.0;
    double m_peakLevel = 0.0;
    quint64 m_bytesRead = 0;

    double m_frequencyHz = 0.0;
    int m_midiNote = -1;
    double m_cents = 0.0;
    double m_pitchConfidence = 0.0;
    bool m_voiced = false;
    QString m_pitchStatus = QStringLiteral("No stable voice detected");
    QString m_detectedVoiceClass = QStringLiteral("-");

    int m_onsetCount = 0;
    double m_lastOnsetSeconds = -1.0;
    double m_previousOnsetSeconds = -1.0;
    double m_referenceOnsetSeconds = -1.0;
    double m_detectedBpm = 0.0;
    double m_lastTimingErrorMs = 0.0;
    QString m_rhythmStatus = QStringLiteral("No onset detected yet");
    std::deque<double> m_recentOnsetSeconds;

    QAudioFormat m_audioFormat;
    QMediaDevices m_mediaDevices;
    std::unique_ptr<QAudioSource> m_audioSource;
    QPointer<QIODevice> m_audioDevice;
    QTimer m_pollTimer;

    uint_t m_sampleRate = 48000;
    uint_t m_pitchBufferSize = 4096;
    uint_t m_onsetBufferSize = 2048;
    uint_t m_hopSize = 512;
    quint64 m_processedSamples = 0;
    quint64 m_lastDebugSample = 0;
    double m_onsetTimeOffsetSeconds = 0.0;

    PitchPtr m_pitch;
    OnsetPtr m_onset;
    FVecPtr m_input;
    FVecPtr m_pitchOut;
    FVecPtr m_onsetOut;

    std::deque<float> m_pendingSamples;
};
