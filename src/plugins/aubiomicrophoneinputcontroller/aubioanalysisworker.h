// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QByteArray>
#include <QObject>
#include <QString>

#include <aubio/aubio.h>

#include <atomic>
#include <deque>
#include <memory>

class AubioAnalysisWorker : public QObject
{
    Q_OBJECT

public:
    struct Config {
        int preset = 0;
        int analysisMode = 0;
        int pitchMethod = 1;
        int onsetMethod = 1;
        int expectedMidiNote = -1;
        bool disregardOctaveDifference = true;
        double voiceMinHz = 80.0;
        double voiceMaxHz = 1000.0;
        double targetBpm = 90.0;
        double minimumExpectedOnsetIntervalMs = 0.0;
        double minimumPitchConfidence = 0.12;
        double pitchSilenceDb = -55.0;
        double onsetThreshold = 0.16;
        double inputGateLevel = 0.012;
        double minimumOnsetStrength = 0.01;
        double calibratedOnsetStrengthFloor = 0.0;
        int requiredStablePitchFrames = 4;
    };

    explicit AubioAnalysisWorker(std::shared_ptr<std::atomic<quint64>> activeGeneration, QObject *parent = nullptr);
    ~AubioAnalysisWorker() override;

    void initialize(quint64 generation, const Config &config, int sampleRate, int channelCount, int sampleFormat, int bytesPerSample);
    void updateConfig(quint64 generation, const Config &config);
    void resetAnalysis(quint64 generation, quint64 captureFrame);
    void processAudio(quint64 generation, const QByteArray &bytes);
    void startNoiseCalibration(quint64 generation);
    void drain(quint64 generation);

Q_SIGNALS:
    void initializationFailed(quint64 generation, const QString &message);
    void chunkProcessed(quint64 generation, qsizetype byteCount);
    void statsUpdated(quint64 generation, quint64 processedSamples, double audioLevel, double peakLevel, int stablePitchFrames);
    void pitchResult(quint64 generation, double seconds, bool voiced, double frequencyHz, double confidence, const QString &reason);
    void onsetResult(quint64 generation, double seconds, double strength);
    void noiseCalibrationFinished(quint64 generation, double noiseFloor);
    void drained(quint64 generation);

private:
    struct PitchDeleter {
        void operator()(aubio_pitch_t *value) const
        {
            if (value)
                del_aubio_pitch(value);
        }
    };
    struct OnsetDeleter {
        void operator()(aubio_onset_t *value) const
        {
            if (value)
                del_aubio_onset(value);
        }
    };
    struct FVecDeleter {
        void operator()(fvec_t *value) const
        {
            if (value)
                del_fvec(value);
        }
    };

    using PitchPtr = std::unique_ptr<aubio_pitch_t, PitchDeleter>;
    using OnsetPtr = std::unique_ptr<aubio_onset_t, OnsetDeleter>;
    using FVecPtr = std::unique_ptr<fvec_t, FVecDeleter>;

    bool isCurrent(quint64 generation) const;
    bool createAubioObjects(QString *errorMessage);
    void destroyAubioObjects();
    void resetDetectionState();
    void appendSamples(const QByteArray &bytes);
    void processPendingSamples();
    void processHop();
    void processPitchFrame(double seconds);
    void processOnsetFrame(double fallbackSeconds);
    void publishUnvoiced(double seconds, const QString &reason);
    void publishAcceptedPitch(double seconds, double frequencyHz, double confidence);
    void flushPendingPitch();
    bool acceptStablePitchCandidate(double frequencyHz);
    double scoreConstrainedFrequency(double frequencyHz) const;
    double smoothedAcceptedFrequency(double frequencyHz);
    void resetPitchCandidate();
    void rememberOnsetDescriptor(double strength);
    double adaptiveMinimumOnsetStrength() const;
    void updateNoiseCalibration(double sumSquares, int sampleCount);
    void publishStats(bool force = false);

    static double midiFromFrequency(double frequencyHz);
    static const char *pitchMethodName(int method);
    static const char *onsetMethodName(int method);

    std::shared_ptr<std::atomic<quint64>> m_activeGeneration;
    quint64 m_generation = 0;
    Config m_config;
    int m_sampleRate = 48000;
    int m_channelCount = 1;
    int m_sampleFormat = 1;
    int m_bytesPerSample = 2;
    uint_t m_pitchBufferSize = 4096;
    uint_t m_onsetBufferSize = 2048;
    uint_t m_hopSize = 512;
    quint64 m_processedSamples = 0;
    quint64 m_analysisStartSample = 0;
    quint64 m_lastStatsSample = 0;
    double m_onsetTimeOffsetSeconds = 0.0;

    PitchPtr m_pitch;
    OnsetPtr m_onset;
    FVecPtr m_input;
    FVecPtr m_pitchOut;
    FVecPtr m_onsetOut;
    std::deque<float> m_pendingSamples;

    double m_audioLevel = 0.0;
    double m_peakLevel = 0.0;
    double m_candidateFrequencyHz = 0.0;
    int m_candidateMidiNote = -1;
    int m_stablePitchFrameCount = 0;
    std::deque<double> m_recentAcceptedFrequencies;
    std::deque<double> m_recentOnsetDescriptorValues;
    double m_lastAcceptedOnsetSeconds = -1.0;

    bool m_lastPublishedVoiced = false;
    int m_lastPublishedMidi = -1;
    double m_lastPitchPublishSeconds = -1.0;
    bool m_pendingPitchValid = false;
    double m_pendingPitchSeconds = 0.0;
    double m_pendingPitchFrequency = 0.0;
    double m_pendingPitchConfidence = 0.0;

    bool m_noiseCalibrationActive = false;
    double m_noiseCalibrationSumSquares = 0.0;
    quint64 m_noiseCalibrationSamples = 0;
};
