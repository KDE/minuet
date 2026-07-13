// SPDX-License-Identifier: GPL-2.0-or-later

#include "aubioanalysisworker.h"

#include <QAudioFormat>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>
#include <utility>
#include <vector>

namespace
{
template<typename T>
T readUnaligned(const char *data)
{
    T value;
    std::memcpy(&value, data, sizeof(T));
    return value;
}

double medianValue(std::deque<double> values)
{
    if (values.empty()) {
        return 0.0;
    }
    std::vector<double> sorted(values.begin(), values.end());
    std::sort(sorted.begin(), sorted.end());
    return sorted.at(sorted.size() / 2);
}

constexpr double BroadVoiceMinHz = 65.0;
constexpr double BroadVoiceMaxHz = 1200.0;
constexpr double PitchPublishIntervalSeconds = 0.05;
}

AubioAnalysisWorker::AubioAnalysisWorker(std::shared_ptr<std::atomic<quint64>> activeGeneration, QObject *parent)
    : QObject(parent)
    , m_activeGeneration(std::move(activeGeneration))
{
}

AubioAnalysisWorker::~AubioAnalysisWorker()
{
    destroyAubioObjects();
}

bool AubioAnalysisWorker::isCurrent(quint64 generation) const
{
    return generation == m_generation && generation == m_activeGeneration->load(std::memory_order_relaxed);
}

void AubioAnalysisWorker::initialize(quint64 generation, const Config &config, int sampleRate, int channelCount, int sampleFormat, int bytesPerSample)
{
    if (generation != m_activeGeneration->load(std::memory_order_relaxed)) {
        return;
    }
    m_generation = generation;
    m_config = config;
    m_sampleRate = sampleRate;
    m_channelCount = channelCount;
    m_sampleFormat = sampleFormat;
    m_bytesPerSample = bytesPerSample;
    m_processedSamples = 0;
    m_analysisStartSample = 0;
    m_lastStatsSample = 0;
    m_audioLevel = 0.0;
    m_peakLevel = 0.0;
    m_pendingSamples.clear();
    resetDetectionState();
    QString errorMessage;
    if (!createAubioObjects(&errorMessage)) {
        Q_EMIT initializationFailed(generation, errorMessage);
    }
}

void AubioAnalysisWorker::updateConfig(quint64 generation, const Config &config)
{
    if (!isCurrent(generation)) {
        return;
    }
    const bool pitchTargetChanged =
        config.expectedMidiNote != m_config.expectedMidiNote || config.disregardOctaveDifference != m_config.disregardOctaveDifference;
    m_config = config;
    if (m_pitch) {
        aubio_pitch_set_silence(m_pitch.get(), static_cast<smpl_t>(m_config.pitchSilenceDb));
    }
    if (m_onset) {
        aubio_onset_set_silence(m_onset.get(), static_cast<smpl_t>(m_config.pitchSilenceDb));
        aubio_onset_set_threshold(m_onset.get(), static_cast<smpl_t>(m_config.onsetThreshold));
    }
    if (pitchTargetChanged) {
        resetPitchCandidate();
        m_recentAcceptedFrequencies.clear();
    }
}

void AubioAnalysisWorker::resetAnalysis(quint64 generation, quint64 captureFrame)
{
    if (generation != m_activeGeneration->load(std::memory_order_relaxed)) {
        return;
    }
    m_generation = generation;
    m_processedSamples = captureFrame;
    m_analysisStartSample = captureFrame;
    m_lastStatsSample = captureFrame;
    m_pendingSamples.clear();
    resetDetectionState();
    QString errorMessage;
    if (!createAubioObjects(&errorMessage)) {
        Q_EMIT initializationFailed(generation, errorMessage);
        return;
    }
    if (m_onset) {
        m_onsetTimeOffsetSeconds = static_cast<double>(captureFrame) / m_sampleRate;
    }
}

void AubioAnalysisWorker::processAudio(quint64 generation, const QByteArray &bytes)
{
    if (!isCurrent(generation)) {
        Q_EMIT chunkProcessed(generation, bytes.size());
        return;
    }
    appendSamples(bytes);
    processPendingSamples();
    Q_EMIT chunkProcessed(generation, bytes.size());
}

void AubioAnalysisWorker::startNoiseCalibration(quint64 generation)
{
    if (!isCurrent(generation)) {
        return;
    }
    m_noiseCalibrationActive = true;
    m_noiseCalibrationSumSquares = 0.0;
    m_noiseCalibrationSamples = 0;
}

void AubioAnalysisWorker::drain(quint64 generation)
{
    if (!isCurrent(generation)) {
        return;
    }
    flushPendingPitch();
    publishStats(true);
    Q_EMIT drained(generation);
}

bool AubioAnalysisWorker::createAubioObjects(QString *errorMessage)
{
    destroyAubioObjects();
    m_input.reset(new_fvec(m_hopSize));
    if (!m_input) {
        *errorMessage = QStringLiteral("Could not allocate aubio input buffer.");
        return false;
    }
    if (m_config.analysisMode != 2) {
        m_pitchOut.reset(new_fvec(1));
        m_pitch.reset(new_aubio_pitch(pitchMethodName(m_config.pitchMethod), m_pitchBufferSize, m_hopSize, m_sampleRate));
        if (!m_pitch || !m_pitchOut) {
            *errorMessage = QStringLiteral("Could not create aubio pitch detector.");
            return false;
        }
        aubio_pitch_set_unit(m_pitch.get(), "Hz");
        aubio_pitch_set_tolerance(m_pitch.get(), 0.8);
        aubio_pitch_set_silence(m_pitch.get(), static_cast<smpl_t>(m_config.pitchSilenceDb));
    }
    if (m_config.analysisMode != 0) {
        m_onsetOut.reset(new_fvec(1));
        m_onset.reset(new_aubio_onset(onsetMethodName(m_config.onsetMethod), m_onsetBufferSize, m_hopSize, m_sampleRate));
        if (!m_onset || !m_onsetOut) {
            *errorMessage = QStringLiteral("Could not create aubio onset detector.");
            return false;
        }
        aubio_onset_set_threshold(m_onset.get(), static_cast<smpl_t>(m_config.onsetThreshold));
        aubio_onset_set_silence(m_onset.get(), static_cast<smpl_t>(m_config.pitchSilenceDb));
    }
    return true;
}

void AubioAnalysisWorker::destroyAubioObjects()
{
    m_onsetOut.reset();
    m_pitchOut.reset();
    m_input.reset();
    m_onset.reset();
    m_pitch.reset();
}

void AubioAnalysisWorker::resetDetectionState()
{
    resetPitchCandidate();
    m_recentAcceptedFrequencies.clear();
    m_recentOnsetDescriptorValues.clear();
    m_lastAcceptedOnsetSeconds = -1.0;
    m_onsetTimeOffsetSeconds = 0.0;
    m_lastPublishedVoiced = false;
    m_lastPublishedMidi = -1;
    m_lastPitchPublishSeconds = -1.0;
    m_pendingPitchValid = false;
}

void AubioAnalysisWorker::appendSamples(const QByteArray &bytes)
{
    const int bytesPerFrame = m_bytesPerSample * m_channelCount;
    if (bytesPerFrame <= 0) {
        return;
    }
    const int frameCount = bytes.size() / bytesPerFrame;
    const char *data = bytes.constData();
    double sumSquares = 0.0;
    double peak = 0.0;
    for (int frame = 0; frame < frameCount; ++frame) {
        const char *frameData = data + frame * bytesPerFrame;
        double mono = 0.0;
        for (int channel = 0; channel < m_channelCount; ++channel) {
            const char *sampleData = frameData + channel * m_bytesPerSample;
            switch (static_cast<QAudioFormat::SampleFormat>(m_sampleFormat)) {
            case QAudioFormat::UInt8:
                mono += (static_cast<int>(readUnaligned<quint8>(sampleData)) - 128) / 128.0;
                break;
            case QAudioFormat::Int16:
                mono += readUnaligned<qint16>(sampleData) / 32768.0;
                break;
            case QAudioFormat::Int32:
                mono += readUnaligned<qint32>(sampleData) / 2147483648.0;
                break;
            case QAudioFormat::Float:
                mono += readUnaligned<float>(sampleData);
                break;
            default:
                break;
            }
        }
        mono = std::clamp(mono / m_channelCount, -1.0, 1.0);
        sumSquares += mono * mono;
        peak = std::max(peak, std::abs(mono));
        m_pendingSamples.push_back(static_cast<float>(mono));
    }
    if (frameCount > 0) {
        const double rms = std::sqrt(sumSquares / frameCount);
        m_audioLevel = 0.80 * m_audioLevel + 0.20 * rms;
        m_peakLevel = std::max(peak, 0.90 * m_peakLevel);
        updateNoiseCalibration(sumSquares, frameCount);
    }
}

void AubioAnalysisWorker::processPendingSamples()
{
    while (m_input && m_pendingSamples.size() >= m_hopSize) {
        processHop();
    }
}

void AubioAnalysisWorker::processHop()
{
    for (uint_t i = 0; i < m_hopSize; ++i) {
        fvec_set_sample(m_input.get(), static_cast<smpl_t>(m_pendingSamples.front()), i);
        m_pendingSamples.pop_front();
    }
    const double seconds = static_cast<double>(m_processedSamples) / m_sampleRate;
    if (m_pitch && m_pitchOut) {
        processPitchFrame(seconds);
    }
    if (m_onset && m_onsetOut) {
        processOnsetFrame(seconds);
    }
    m_processedSamples += m_hopSize;
    publishStats();
}

void AubioAnalysisWorker::processPitchFrame(double seconds)
{
    const double analysisStartSeconds = static_cast<double>(m_analysisStartSample) / m_sampleRate;
    const double pitchLatencySeconds = static_cast<double>(m_pitchBufferSize) / m_sampleRate;
    const double resultSeconds = std::max(analysisStartSeconds, seconds - pitchLatencySeconds);
    aubio_pitch_do(m_pitch.get(), m_input.get(), m_pitchOut.get());
    const double frequency = fvec_get_sample(m_pitchOut.get(), 0);
    const double confidence = aubio_pitch_get_confidence(m_pitch.get());
    if (m_audioLevel < m_config.inputGateLevel) {
        resetPitchCandidate();
        publishUnvoiced(resultSeconds, QStringLiteral("Input below gate."));
        return;
    }
    if (!std::isfinite(frequency) || frequency < BroadVoiceMinHz || frequency > BroadVoiceMaxHz) {
        resetPitchCandidate();
        publishUnvoiced(resultSeconds, QStringLiteral("No stable voice detected"));
        return;
    }
    const double constrained = scoreConstrainedFrequency(frequency);
    if (constrained < m_config.voiceMinHz || constrained > m_config.voiceMaxHz || confidence < m_config.minimumPitchConfidence) {
        resetPitchCandidate();
        publishUnvoiced(resultSeconds, QStringLiteral("Pitch candidate rejected."));
        return;
    }
    if (!acceptStablePitchCandidate(constrained)) {
        return;
    }
    publishAcceptedPitch(resultSeconds, smoothedAcceptedFrequency(constrained), confidence);
}

void AubioAnalysisWorker::processOnsetFrame(double fallbackSeconds)
{
    aubio_onset_do(m_onset.get(), m_input.get(), m_onsetOut.get());
    const double strength = aubio_onset_get_descriptor(m_onset.get());
    rememberOnsetDescriptor(strength);
    if (fvec_get_sample(m_onsetOut.get(), 0) <= 0.0) {
        return;
    }
    double seconds = aubio_onset_get_last_s(m_onset.get());
    seconds = std::isfinite(seconds) && seconds >= 0.0 ? seconds + m_onsetTimeOffsetSeconds : fallbackSeconds;
    if (m_config.preset != 1 && m_audioLevel < m_config.inputGateLevel) {
        return;
    }
    if (strength < adaptiveMinimumOnsetStrength()) {
        return;
    }
    const double beatDuration = 60.0 / m_config.targetBpm;
    const double expectedInterval = m_config.minimumExpectedOnsetIntervalMs > 0.0 ? m_config.minimumExpectedOnsetIntervalMs / 1000.0 : beatDuration;
    const double duplicateWindow = std::min(0.18, expectedInterval * 0.35);
    if (m_lastAcceptedOnsetSeconds >= 0.0 && seconds - m_lastAcceptedOnsetSeconds < duplicateWindow) {
        return;
    }
    m_lastAcceptedOnsetSeconds = seconds;
    Q_EMIT onsetResult(m_generation, seconds, strength);
}

void AubioAnalysisWorker::publishUnvoiced(double seconds, const QString &reason)
{
    m_pendingPitchValid = false;
    if (m_lastPublishedVoiced) {
        m_lastPublishedVoiced = false;
        m_lastPublishedMidi = -1;
        m_lastPitchPublishSeconds = seconds;
        Q_EMIT pitchResult(m_generation, seconds, false, 0.0, 0.0, reason);
    }
}

void AubioAnalysisWorker::publishAcceptedPitch(double seconds, double frequencyHz, double confidence)
{
    const int midi = static_cast<int>(std::llround(midiFromFrequency(frequencyHz)));
    const bool publishImmediately = !m_lastPublishedVoiced || midi != m_lastPublishedMidi;
    if (publishImmediately || m_lastPitchPublishSeconds < 0.0 || seconds - m_lastPitchPublishSeconds >= PitchPublishIntervalSeconds) {
        m_lastPublishedVoiced = true;
        m_lastPublishedMidi = midi;
        m_lastPitchPublishSeconds = seconds;
        m_pendingPitchValid = false;
        Q_EMIT pitchResult(m_generation, seconds, true, frequencyHz, confidence, QString());
        return;
    }
    m_pendingPitchValid = true;
    m_pendingPitchSeconds = seconds;
    m_pendingPitchFrequency = frequencyHz;
    m_pendingPitchConfidence = confidence;
}

void AubioAnalysisWorker::flushPendingPitch()
{
    if (!m_pendingPitchValid) {
        return;
    }
    m_pendingPitchValid = false;
    m_lastPublishedVoiced = true;
    m_lastPublishedMidi = static_cast<int>(std::llround(midiFromFrequency(m_pendingPitchFrequency)));
    m_lastPitchPublishSeconds = m_pendingPitchSeconds;
    Q_EMIT pitchResult(m_generation, m_pendingPitchSeconds, true, m_pendingPitchFrequency, m_pendingPitchConfidence, QString());
}

bool AubioAnalysisWorker::acceptStablePitchCandidate(double frequencyHz)
{
    const int midi = static_cast<int>(std::llround(midiFromFrequency(frequencyHz)));
    bool similar = false;
    if (m_candidateFrequencyHz > 0.0) {
        const double centsDelta = 1200.0 * std::log2(frequencyHz / m_candidateFrequencyHz);
        similar = std::abs(centsDelta) <= 80.0 || midi == m_candidateMidiNote;
    }
    if (!similar) {
        m_candidateFrequencyHz = frequencyHz;
        m_candidateMidiNote = midi;
        m_stablePitchFrameCount = 1;
        return m_config.requiredStablePitchFrames <= 1;
    }
    m_candidateFrequencyHz = 0.70 * m_candidateFrequencyHz + 0.30 * frequencyHz;
    m_candidateMidiNote = midi;
    m_stablePitchFrameCount = std::min(m_stablePitchFrameCount + 1, m_config.requiredStablePitchFrames);
    return m_stablePitchFrameCount >= m_config.requiredStablePitchFrames;
}

double AubioAnalysisWorker::scoreConstrainedFrequency(double frequencyHz) const
{
    if (m_config.expectedMidiNote < 0 || !m_config.disregardOctaveDifference) {
        return frequencyHz;
    }
    double bestFrequency = frequencyHz;
    double bestDistance = std::numeric_limits<double>::max();
    for (int shift = -4; shift <= 4; ++shift) {
        const double shifted = frequencyHz * std::pow(2.0, shift);
        if (shifted < BroadVoiceMinHz || shifted > BroadVoiceMaxHz) {
            continue;
        }
        const double distance = std::abs(midiFromFrequency(shifted) - m_config.expectedMidiNote);
        if (distance < bestDistance) {
            bestDistance = distance;
            bestFrequency = shifted;
        }
    }
    return bestFrequency;
}

double AubioAnalysisWorker::smoothedAcceptedFrequency(double frequencyHz)
{
    m_recentAcceptedFrequencies.push_back(frequencyHz);
    while (m_recentAcceptedFrequencies.size() > 5) {
        m_recentAcceptedFrequencies.pop_front();
    }
    return medianValue(m_recentAcceptedFrequencies);
}

void AubioAnalysisWorker::resetPitchCandidate()
{
    m_candidateFrequencyHz = 0.0;
    m_candidateMidiNote = -1;
    m_stablePitchFrameCount = 0;
}

void AubioAnalysisWorker::rememberOnsetDescriptor(double strength)
{
    if (!std::isfinite(strength) || strength < 0.0) {
        return;
    }
    m_recentOnsetDescriptorValues.push_back(strength);
    while (m_recentOnsetDescriptorValues.size() > 48) {
        m_recentOnsetDescriptorValues.pop_front();
    }
}

double AubioAnalysisWorker::adaptiveMinimumOnsetStrength() const
{
    return std::max({m_config.minimumOnsetStrength, m_config.calibratedOnsetStrengthFloor, medianValue(m_recentOnsetDescriptorValues) * 2.5});
}

void AubioAnalysisWorker::updateNoiseCalibration(double sumSquares, int sampleCount)
{
    if (!m_noiseCalibrationActive || sampleCount <= 0) {
        return;
    }
    m_noiseCalibrationSumSquares += sumSquares;
    m_noiseCalibrationSamples += sampleCount;
    if (m_noiseCalibrationSamples < static_cast<quint64>(m_sampleRate)) {
        return;
    }
    const double floor = std::sqrt(m_noiseCalibrationSumSquares / m_noiseCalibrationSamples);
    m_noiseCalibrationActive = false;
    m_noiseCalibrationSumSquares = 0.0;
    m_noiseCalibrationSamples = 0;
    Q_EMIT noiseCalibrationFinished(m_generation, floor);
}

void AubioAnalysisWorker::publishStats(bool force)
{
    if (!force && m_processedSamples - m_lastStatsSample < static_cast<quint64>(m_sampleRate / 20)) {
        return;
    }
    m_lastStatsSample = m_processedSamples;
    Q_EMIT statsUpdated(m_generation, m_processedSamples, m_audioLevel, m_peakLevel, m_stablePitchFrameCount);
}

double AubioAnalysisWorker::midiFromFrequency(double frequencyHz)
{
    return 69.0 + 12.0 * std::log2(frequencyHz / 440.0);
}

const char *AubioAnalysisWorker::pitchMethodName(int method)
{
    static const char *names[] = {"yinfft", "yin", "yinfast", "mcomb", "schmitt", "specacf", "fcomb"};
    return names[std::clamp(method, 0, 6)];
}

const char *AubioAnalysisWorker::onsetMethodName(int method)
{
    static const char *names[] = {"complex", "hfc", "energy", "specflux", "phase", "specdiff", "kl", "mkl"};
    return names[std::clamp(method, 0, 7)];
}
