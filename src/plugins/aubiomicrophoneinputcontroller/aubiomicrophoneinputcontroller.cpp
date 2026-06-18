// SPDX-License-Identifier: GPL-2.0-or-later

#include "aubiomicrophoneinputcontroller.h"

#include <QAudioDevice>
#include <QAudioSource>
#include <QByteArray>
#include <QDebug>
#include <QIODevice>
#include <QMediaDevices>
#include <QStringList>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

namespace
{
template<typename T>
T readUnaligned(const char *data)
{
    T value;
    std::memcpy(&value, data, sizeof(T));
    return value;
}

double clamp01(double value)
{
    return std::clamp(value, 0.0, 1.0);
}

constexpr double broadVoiceMinHz = 65.0;
constexpr double broadVoiceMaxHz = 1200.0;
}

AubioMicrophoneInputController::AubioMicrophoneInputController(QObject *parent)
    : Minuet::IMicrophoneInputController(parent)
{
    m_pollTimer.setInterval(20);
    connect(&m_pollTimer, &QTimer::timeout, this, &AubioMicrophoneInputController::readAudioData);
    setStatus(QStringLiteral("Ready. Press Start and sing, speak, clap, or tap near the microphone."));
}

AubioMicrophoneInputController::~AubioMicrophoneInputController()
{
    stop();
    destroyAubioObjects();
    aubio_cleanup();
}

bool AubioMicrophoneInputController::running() const { return m_running; }
QString AubioMicrophoneInputController::status() const { return m_status; }
double AubioMicrophoneInputController::analysisTimeSeconds() const
{
    return m_sampleRate > 0 ? static_cast<double>(m_processedSamples) / static_cast<double>(m_sampleRate) : 0.0;
}
Minuet::IMicrophoneInputController::Preset AubioMicrophoneInputController::preset() const { return m_preset; }
Minuet::IMicrophoneInputController::VoiceClass AubioMicrophoneInputController::voiceClass() const { return m_voiceClass; }
Minuet::IMicrophoneInputController::PitchMethod AubioMicrophoneInputController::pitchMethod() const { return m_pitchMethod; }
Minuet::IMicrophoneInputController::OnsetMethod AubioMicrophoneInputController::onsetMethod() const { return m_onsetMethod; }
double AubioMicrophoneInputController::targetBpm() const { return m_targetBpm; }
double AubioMicrophoneInputController::minimumPitchConfidence() const { return m_minimumPitchConfidence; }
double AubioMicrophoneInputController::pitchSilenceDb() const { return m_pitchSilenceDb; }
double AubioMicrophoneInputController::onsetThreshold() const { return m_onsetThreshold; }
double AubioMicrophoneInputController::inputGateLevel() const { return m_inputGateLevel; }
double AubioMicrophoneInputController::noiseFloorLevel() const { return m_noiseFloorLevel; }
bool AubioMicrophoneInputController::inputGateOpen() const { return m_audioLevel >= m_inputGateLevel; }
bool AubioMicrophoneInputController::noiseCalibrationActive() const { return m_noiseCalibrationActive; }
double AubioMicrophoneInputController::minimumOnsetStrength() const { return m_minimumOnsetStrength; }
int AubioMicrophoneInputController::requiredStablePitchFrames() const { return m_requiredStablePitchFrames; }
int AubioMicrophoneInputController::stablePitchFrameCount() const { return m_stablePitchFrameCount; }
QString AubioMicrophoneInputController::inputDeviceDescription() const { return m_inputDeviceDescription; }
double AubioMicrophoneInputController::audioLevel() const { return m_audioLevel; }
double AubioMicrophoneInputController::peakLevel() const { return m_peakLevel; }
quint64 AubioMicrophoneInputController::bytesRead() const { return m_bytesRead; }
quint64 AubioMicrophoneInputController::processedSamples() const { return m_processedSamples; }
double AubioMicrophoneInputController::frequencyHz() const { return m_frequencyHz; }
int AubioMicrophoneInputController::midiNote() const { return m_midiNote; }
double AubioMicrophoneInputController::cents() const { return m_cents; }
double AubioMicrophoneInputController::pitchConfidence() const { return m_pitchConfidence; }
bool AubioMicrophoneInputController::voiced() const { return m_voiced; }
QString AubioMicrophoneInputController::pitchStatus() const { return m_pitchStatus; }
QString AubioMicrophoneInputController::detectedVoiceClass() const { return m_detectedVoiceClass; }
int AubioMicrophoneInputController::onsetCount() const { return m_onsetCount; }
double AubioMicrophoneInputController::lastOnsetSeconds() const { return m_lastOnsetSeconds; }
double AubioMicrophoneInputController::detectedBpm() const { return m_detectedBpm; }
double AubioMicrophoneInputController::lastTimingErrorMs() const { return m_lastTimingErrorMs; }
QString AubioMicrophoneInputController::rhythmStatus() const { return m_rhythmStatus; }

QString AubioMicrophoneInputController::noteName() const
{
    return noteNameForMidi(m_midiNote);
}

void AubioMicrophoneInputController::setPreset(Preset preset)
{
    if (m_preset == preset) {
        return;
    }
    applyPreset(preset, true);
}

void AubioMicrophoneInputController::setVoiceClass(VoiceClass voiceClass)
{
    if (m_voiceClass == voiceClass) {
        return;
    }
    m_voiceClass = voiceClass;
    Q_EMIT voiceClassChanged();
    if (m_voiced) {
        m_pitchStatus = classifyPitch(m_frequencyHz, m_cents, m_pitchConfidence);
        Q_EMIT pitchChanged();
    }
}

void AubioMicrophoneInputController::setPitchMethod(PitchMethod pitchMethod)
{
    if (m_pitchMethod == pitchMethod) {
        return;
    }
    m_pitchMethod = pitchMethod;
    Q_EMIT pitchMethodChanged();
    resetIfRunning();
}

void AubioMicrophoneInputController::setOnsetMethod(OnsetMethod onsetMethod)
{
    if (m_onsetMethod == onsetMethod) {
        return;
    }
    m_onsetMethod = onsetMethod;
    Q_EMIT onsetMethodChanged();
    resetIfRunning();
}

void AubioMicrophoneInputController::setTargetBpm(double targetBpm)
{
    targetBpm = std::clamp(targetBpm, 30.0, 240.0);
    if (qFuzzyCompare(m_targetBpm, targetBpm)) {
        return;
    }
    m_targetBpm = targetBpm;
    Q_EMIT targetBpmChanged();
}

void AubioMicrophoneInputController::setMinimumPitchConfidence(double confidence)
{
    confidence = clamp01(confidence);
    if (qFuzzyCompare(m_minimumPitchConfidence, confidence)) {
        return;
    }
    m_minimumPitchConfidence = confidence;
    Q_EMIT minimumPitchConfidenceChanged();
}

void AubioMicrophoneInputController::setPitchSilenceDb(double silenceDb)
{
    silenceDb = std::clamp(silenceDb, -120.0, -10.0);
    if (qFuzzyCompare(m_pitchSilenceDb, silenceDb)) {
        return;
    }
    m_pitchSilenceDb = silenceDb;
    Q_EMIT pitchSilenceDbChanged();
    resetIfRunning();
}

void AubioMicrophoneInputController::setOnsetThreshold(double threshold)
{
    threshold = std::clamp(threshold, 0.01, 1.0);
    if (qFuzzyCompare(m_onsetThreshold, threshold)) {
        return;
    }
    m_onsetThreshold = threshold;
    if (m_onset) {
        aubio_onset_set_threshold(m_onset.get(), static_cast<smpl_t>(m_onsetThreshold));
    }
    Q_EMIT onsetThresholdChanged();
}

void AubioMicrophoneInputController::setInputGateLevel(double inputGateLevel)
{
    inputGateLevel = std::clamp(inputGateLevel, 0.0, 0.25);
    if (qFuzzyCompare(m_inputGateLevel, inputGateLevel)) {
        return;
    }
    m_inputGateLevel = inputGateLevel;
    Q_EMIT inputGateLevelChanged();
    Q_EMIT audioLevelChanged();
}

void AubioMicrophoneInputController::setMinimumOnsetStrength(double strength)
{
    strength = std::clamp(strength, 0.0, 1.0);
    if (qFuzzyCompare(m_minimumOnsetStrength, strength)) {
        return;
    }
    m_minimumOnsetStrength = strength;
    Q_EMIT minimumOnsetStrengthChanged();
}

void AubioMicrophoneInputController::setRequiredStablePitchFrames(int frames)
{
    frames = std::clamp(frames, 1, 10);
    if (m_requiredStablePitchFrames == frames) {
        return;
    }
    m_requiredStablePitchFrames = frames;
    resetPitchCandidate();
    Q_EMIT requiredStablePitchFramesChanged();
    Q_EMIT pitchChanged();
}

void AubioMicrophoneInputController::start()
{
    if (m_running) {
        return;
    }

    resetRuntimeState();

    if (!configureAudioInput()) {
        return;
    }
    if (!recreateAubioObjects()) {
        return;
    }

    m_audioDevice = m_audioSource->start();
    if (!m_audioDevice) {
        setStatus(QStringLiteral("Failed to start audio input."));
        destroyAubioObjects();
        return;
    }

    connect(m_audioDevice, &QIODevice::readyRead, this, &AubioMicrophoneInputController::readAudioData);
    m_pollTimer.start();

    m_running = true;
    Q_EMIT runningChanged();

    setStatus(QStringLiteral("Listening on %1. preset=%2, pitch=%3, onset=%4, selected SATB range=%5 (%6–%7 Hz).")
                  .arg(m_inputDeviceDescription,
                       presetName(m_preset),
                       QString::fromLatin1(aubioPitchMethodName(m_pitchMethod)),
                       QString::fromLatin1(aubioOnsetMethodName(m_onsetMethod)),
                       voiceClassName(m_voiceClass))
                  .arg(minFrequencyForCurrentVoiceClass(), 0, 'f', 0)
                  .arg(maxFrequencyForCurrentVoiceClass(), 0, 'f', 0));

    qInfo().noquote() << QStringLiteral("AubioMicrophoneInputController started: device='%1', sampleRate=%2, channels=%3, format=%4, preset=%5, pitch=%6, onset=%7, pitchConfThreshold=%8, onsetThreshold=%9, inputGate=%10, silenceDb=%11, minOnsetStrength=%12, stableFrames=%13")
        .arg(m_inputDeviceDescription)
        .arg(m_audioFormat.sampleRate())
        .arg(m_audioFormat.channelCount())
        .arg(static_cast<int>(m_audioFormat.sampleFormat()))
        .arg(presetName(m_preset))
        .arg(QString::fromLatin1(aubioPitchMethodName(m_pitchMethod)))
        .arg(QString::fromLatin1(aubioOnsetMethodName(m_onsetMethod)))
        .arg(m_minimumPitchConfidence, 0, 'f', 2)
        .arg(m_onsetThreshold, 0, 'f', 2)
        .arg(m_inputGateLevel, 0, 'f', 4)
        .arg(m_pitchSilenceDb, 0, 'f', 0)
        .arg(m_minimumOnsetStrength, 0, 'f', 3)
        .arg(m_requiredStablePitchFrames);

    readAudioData();
}

void AubioMicrophoneInputController::calibrateNoiseFloor()
{
    if (!m_running) {
        setStatus(QStringLiteral("Start listening first, then keep silent and press Calibrate silence."));
        return;
    }

    m_noiseCalibrationActive = true;
    m_noiseCalibrationSumSquares = 0.0;
    m_noiseCalibrationSamples = 0;
    Q_EMIT noiseCalibrationActiveChanged();
    setStatus(QStringLiteral("Calibrating noise floor: keep silent for about one second..."));
    qInfo() << "Noise calibration started";
}

void AubioMicrophoneInputController::stop()
{
    if (!m_running && !m_audioSource) {
        return;
    }

    m_pollTimer.stop();

    if (m_audioSource) {
        m_audioSource->stop();
    }

    if (m_audioDevice) {
        disconnect(m_audioDevice, nullptr, this, nullptr);
        m_audioDevice.clear();
    }

    m_audioSource.reset();
    destroyAubioObjects();

    if (m_noiseCalibrationActive) {
        m_noiseCalibrationActive = false;
        m_noiseCalibrationSumSquares = 0.0;
        m_noiseCalibrationSamples = 0;
        Q_EMIT noiseCalibrationActiveChanged();
    }

    const bool wasRunning = m_running;
    m_running = false;
    if (wasRunning) {
        Q_EMIT runningChanged();
    }
    setStatus(QStringLiteral("Stopped."));
}

QString AubioMicrophoneInputController::presetName(int preset) const
{
    switch (static_cast<Preset>(preset)) {
    case Singing: return QStringLiteral("Singing");
    case Clapping: return QStringLiteral("Clapping");
    }
    return QStringLiteral("Unknown");
}

QString AubioMicrophoneInputController::voiceClassName(int voiceClass) const
{
    switch (static_cast<VoiceClass>(voiceClass)) {
    case Soprano: return QStringLiteral("Soprano");
    case Alto: return QStringLiteral("Alto");
    case Tenor: return QStringLiteral("Tenor");
    case Bass: return QStringLiteral("Bass");
    }
    return QStringLiteral("Unknown");
}

QString AubioMicrophoneInputController::pitchMethodName(int pitchMethod) const
{
    return QString::fromLatin1(aubioPitchMethodName(static_cast<PitchMethod>(pitchMethod)));
}

QString AubioMicrophoneInputController::onsetMethodName(int onsetMethod) const
{
    return QString::fromLatin1(aubioOnsetMethodName(static_cast<OnsetMethod>(onsetMethod)));
}

double AubioMicrophoneInputController::voiceClassMinHz(int voiceClass) const
{
    switch (static_cast<VoiceClass>(voiceClass)) {
    case Soprano: return 261.63; // C4
    case Alto: return 196.00; // G3
    case Tenor: return 130.81; // C3
    case Bass: return 82.41; // E2
    }
    return 80.0;
}

double AubioMicrophoneInputController::voiceClassMaxHz(int voiceClass) const
{
    switch (static_cast<VoiceClass>(voiceClass)) {
    case Soprano: return 1046.50; // C6
    case Alto: return 698.46; // F5
    case Tenor: return 523.25; // C5
    case Bass: return 329.63; // E4
    }
    return 1000.0;
}

void AubioMicrophoneInputController::setStatus(const QString &status)
{
    if (m_status == status) {
        return;
    }
    m_status = status;
    Q_EMIT statusChanged();
}

void AubioMicrophoneInputController::resetRuntimeState()
{
    m_pendingSamples.clear();
    m_processedSamples = 0;
    resetPitchCandidate();
    m_noiseCalibrationActive = false;
    m_noiseCalibrationSumSquares = 0.0;
    m_noiseCalibrationSamples = 0;
    Q_EMIT noiseCalibrationActiveChanged();
    m_lastDebugSample = 0;
    m_bytesRead = 0;
    m_audioLevel = 0.0;
    m_peakLevel = 0.0;
    Q_EMIT audioLevelChanged();
    Q_EMIT audioStatsChanged();

    m_frequencyHz = 0.0;
    m_midiNote = -1;
    m_cents = 0.0;
    m_pitchConfidence = 0.0;
    m_voiced = false;
    m_detectedVoiceClass = QStringLiteral("-");
    m_pitchStatus = QStringLiteral("No stable voice detected");
    Q_EMIT pitchChanged();

    m_onsetCount = 0;
    m_lastOnsetSeconds = -1.0;
    m_previousOnsetSeconds = -1.0;
    m_referenceOnsetSeconds = -1.0;
    m_detectedBpm = 0.0;
    m_lastTimingErrorMs = 0.0;
    m_rhythmStatus = QStringLiteral("No onset detected yet");
    Q_EMIT rhythmChanged();
}

bool AubioMicrophoneInputController::configureAudioInput()
{
    const QAudioDevice inputDevice = QMediaDevices::defaultAudioInput();
    if (inputDevice.isNull()) {
        setStatus(QStringLiteral("No default audio input device found."));
        return false;
    }

    QAudioFormat desired;
    desired.setSampleRate(48000);
    desired.setChannelCount(1);
    desired.setSampleFormat(QAudioFormat::Int16);

    m_audioFormat = desired;
    if (!inputDevice.isFormatSupported(m_audioFormat)) {
        m_audioFormat = inputDevice.preferredFormat();
    }

    if (m_audioFormat.sampleRate() <= 0 || m_audioFormat.channelCount() <= 0 || m_audioFormat.sampleFormat() == QAudioFormat::Unknown) {
        setStatus(QStringLiteral("The default audio input has an unsupported format."));
        return false;
    }

    m_sampleRate = static_cast<uint_t>(m_audioFormat.sampleRate());
    m_inputDeviceDescription = inputDevice.description();
    Q_EMIT inputDeviceDescriptionChanged();

    m_audioSource = std::make_unique<QAudioSource>(inputDevice, m_audioFormat);
    m_audioSource->setBufferSize(static_cast<int>(m_audioFormat.bytesForDuration(200000))); // about 200 ms

    qInfo() << "Audio input:" << inputDevice.description()
            << "sampleRate" << m_audioFormat.sampleRate()
            << "channels" << m_audioFormat.channelCount()
            << "sampleFormat" << m_audioFormat.sampleFormat()
            << "bytesPerSample" << m_audioFormat.bytesPerSample();

    return true;
}

bool AubioMicrophoneInputController::recreateAubioObjects()
{
    destroyAubioObjects();

    m_input.reset(new_fvec(m_hopSize));
    m_pitchOut.reset(new_fvec(1));
    m_onsetOut.reset(new_fvec(1));
    if (!m_input || !m_pitchOut || !m_onsetOut) {
        setStatus(QStringLiteral("Could not allocate aubio buffers."));
        destroyAubioObjects();
        return false;
    }

    m_pitch.reset(new_aubio_pitch(aubioPitchMethodName(m_pitchMethod), m_pitchBufferSize, m_hopSize, m_sampleRate));
    if (!m_pitch) {
        setStatus(QStringLiteral("Could not create aubio pitch detector '%1'.")
                      .arg(QString::fromLatin1(aubioPitchMethodName(m_pitchMethod))));
        destroyAubioObjects();
        return false;
    }

    aubio_pitch_set_unit(m_pitch.get(), "Hz");
    aubio_pitch_set_tolerance(m_pitch.get(), 0.8);
    aubio_pitch_set_silence(m_pitch.get(), static_cast<smpl_t>(m_pitchSilenceDb));

    m_onset.reset(new_aubio_onset(aubioOnsetMethodName(m_onsetMethod), m_onsetBufferSize, m_hopSize, m_sampleRate));
    if (!m_onset) {
        setStatus(QStringLiteral("Could not create aubio onset detector '%1'.")
                      .arg(QString::fromLatin1(aubioOnsetMethodName(m_onsetMethod))));
        destroyAubioObjects();
        return false;
    }

    aubio_onset_set_threshold(m_onset.get(), static_cast<smpl_t>(m_onsetThreshold));
    aubio_onset_set_silence(m_onset.get(), static_cast<smpl_t>(m_pitchSilenceDb));

    return true;
}

void AubioMicrophoneInputController::destroyAubioObjects()
{
    m_onsetOut.reset();
    m_pitchOut.reset();
    m_input.reset();
    m_onset.reset();
    m_pitch.reset();
}

void AubioMicrophoneInputController::readAudioData()
{
    if (!m_audioDevice) {
        return;
    }

    const QByteArray bytes = m_audioDevice->readAll();
    if (bytes.isEmpty()) {
        return;
    }

    m_bytesRead += static_cast<quint64>(bytes.size());
    appendSamplesFromBytes(bytes);
    processPendingSamples();
    Q_EMIT audioStatsChanged();
}

void AubioMicrophoneInputController::appendSamplesFromBytes(const QByteArray &bytes)
{
    const int channelCount = m_audioFormat.channelCount();
    const int bytesPerSample = m_audioFormat.bytesPerSample();
    const int bytesPerFrame = bytesPerSample * channelCount;
    if (bytesPerFrame <= 0) {
        return;
    }

    const int frameCount = bytes.size() / bytesPerFrame;
    const char *data = bytes.constData();
    double sumSquares = 0.0;
    double peak = 0.0;

    for (int frame = 0; frame < frameCount; ++frame) {
        double mono = 0.0;
        const char *frameData = data + frame * bytesPerFrame;

        for (int channel = 0; channel < channelCount; ++channel) {
            const char *sampleData = frameData + channel * bytesPerSample;
            double sample = 0.0;

            switch (m_audioFormat.sampleFormat()) {
            case QAudioFormat::UInt8:
                sample = (static_cast<int>(readUnaligned<quint8>(sampleData)) - 128) / 128.0;
                break;
            case QAudioFormat::Int16:
                sample = readUnaligned<qint16>(sampleData) / 32768.0;
                break;
            case QAudioFormat::Int32:
                sample = readUnaligned<qint32>(sampleData) / 2147483648.0;
                break;
            case QAudioFormat::Float:
                sample = readUnaligned<float>(sampleData);
                break;
            case QAudioFormat::Unknown:
                break;
            }
            mono += sample;
        }

        mono /= channelCount;
        mono = std::clamp(mono, -1.0, 1.0);
        sumSquares += mono * mono;
        peak = std::max(peak, std::abs(mono));
        m_pendingSamples.push_back(static_cast<float>(mono));
    }

    if (frameCount > 0) {
        const double rms = std::sqrt(sumSquares / frameCount);
        const double smoothedRms = 0.80 * m_audioLevel + 0.20 * rms;
        const double smoothedPeak = std::max(peak, 0.90 * m_peakLevel);
        updateNoiseCalibration(sumSquares, frameCount);

        if (std::abs(smoothedRms - m_audioLevel) > 0.002 || std::abs(smoothedPeak - m_peakLevel) > 0.002) {
            m_audioLevel = smoothedRms;
            m_peakLevel = smoothedPeak;
            Q_EMIT audioLevelChanged();
        }
    }
}

void AubioMicrophoneInputController::processPendingSamples()
{
    while (m_running && m_input && m_pitch && m_onset && m_pendingSamples.size() >= m_hopSize) {
        processHop();
    }
    if (!m_running || !m_input || !m_pitch || !m_onset) {
        m_pendingSamples.clear();
    }
}

void AubioMicrophoneInputController::processHop()
{
    if (!m_input || !m_pitch || !m_onset) {
        return;
    }

    for (uint_t i = 0; i < m_hopSize; ++i) {
        fvec_set_sample(m_input.get(), static_cast<smpl_t>(m_pendingSamples.front()), i);
        m_pendingSamples.pop_front();
    }

    const double frameTimeSeconds = static_cast<double>(m_processedSamples) / static_cast<double>(m_sampleRate);
    processPitchFrame(frameTimeSeconds);
    processOnsetFrame(frameTimeSeconds);
    m_processedSamples += m_hopSize;
}

void AubioMicrophoneInputController::processPitchFrame(double timeSeconds)
{
    aubio_pitch_do(m_pitch.get(), m_input.get(), m_pitchOut.get());

    const double frequency = fvec_get_sample(m_pitchOut.get(), 0);
    const double confidence = aubio_pitch_get_confidence(m_pitch.get());

    maybePrintDebug(timeSeconds, frequency, confidence);
    applyPitchResult(timeSeconds, frequency, confidence);
}

void AubioMicrophoneInputController::processOnsetFrame(double fallbackTimeSeconds)
{
    aubio_onset_do(m_onset.get(), m_input.get(), m_onsetOut.get());

    const double onsetDetected = fvec_get_sample(m_onsetOut.get(), 0);
    if (onsetDetected <= 0.0) {
        return;
    }

    double onsetSeconds = aubio_onset_get_last_s(m_onset.get());
    if (!(onsetSeconds >= 0.0) || !std::isfinite(onsetSeconds)) {
        onsetSeconds = fallbackTimeSeconds;
    }

    const double strength = aubio_onset_get_descriptor(m_onset.get());
    registerOnset(onsetSeconds, strength);
}

void AubioMicrophoneInputController::applyPitchResult(double timeSeconds, double frequencyHz, double confidence)
{
    if (!inputGateOpen()) {
        resetPitchCandidate();
        applyUnvoicedResult(QStringLiteral("Input below gate. Raise your voice, move closer to the microphone, or lower the input gate."));
        return;
    }

    if (!std::isfinite(frequencyHz) || frequencyHz < broadVoiceMinHz || frequencyHz > broadVoiceMaxHz) {
        resetPitchCandidate();
        applyUnvoicedResult(QStringLiteral("Audio present, but aubio has not found a stable voice F0 yet"));
        return;
    }

    const double clampedConfidence = clamp01(confidence);
    if (clampedConfidence < m_minimumPitchConfidence) {
        resetPitchCandidate();
        applyUnvoicedResult(QStringLiteral("Pitch candidate rejected: confidence below threshold"));
        return;
    }

    if (!acceptStablePitchCandidate(frequencyHz)) {
        applyUnvoicedResult(QStringLiteral("Waiting for stable pitch (%1/%2 frames)")
                                .arg(m_stablePitchFrameCount)
                                .arg(m_requiredStablePitchFrames));
        return;
    }

    const double midi = midiFromFrequency(frequencyHz);
    const int nearestMidi = static_cast<int>(std::llround(midi));
    const double nearestHz = frequencyForMidi(nearestMidi);
    const double cents = 1200.0 * std::log2(frequencyHz / nearestHz);

    const bool changed = !m_voiced
        || std::abs(m_frequencyHz - frequencyHz) > 0.5
        || m_midiNote != nearestMidi
        || std::abs(m_cents - cents) > 0.5
        || std::abs(m_pitchConfidence - clampedConfidence) > 0.01;

    m_frequencyHz = frequencyHz;
    m_midiNote = nearestMidi;
    m_cents = cents;
    m_pitchConfidence = clampedConfidence;
    m_voiced = true;
    m_detectedVoiceClass = voiceClassForFrequency(frequencyHz);
    m_pitchStatus = classifyPitch(frequencyHz, cents, clampedConfidence);

    if (changed) {
        Q_EMIT pitchChanged();
    }
    Q_EMIT pitchDetected(timeSeconds, m_midiNote, m_cents, m_pitchConfidence);
}

bool AubioMicrophoneInputController::acceptStablePitchCandidate(double frequencyHz)
{
    const int midi = static_cast<int>(std::llround(midiFromFrequency(frequencyHz)));

    bool similarToCandidate = false;
    if (m_candidateFrequencyHz > 0.0 && std::isfinite(m_candidateFrequencyHz)) {
        const double centsDelta = 1200.0 * std::log2(frequencyHz / m_candidateFrequencyHz);
        similarToCandidate = std::abs(centsDelta) <= 80.0 || midi == m_candidateMidiNote;
    }

    if (!similarToCandidate) {
        m_candidateFrequencyHz = frequencyHz;
        m_candidateMidiNote = midi;
        m_stablePitchFrameCount = 1;
        Q_EMIT pitchChanged();
        return m_requiredStablePitchFrames <= 1;
    }

    m_candidateFrequencyHz = 0.70 * m_candidateFrequencyHz + 0.30 * frequencyHz;
    m_candidateMidiNote = midi;
    if (m_stablePitchFrameCount < m_requiredStablePitchFrames) {
        ++m_stablePitchFrameCount;
        Q_EMIT pitchChanged();
    }

    return m_stablePitchFrameCount >= m_requiredStablePitchFrames;
}

void AubioMicrophoneInputController::resetPitchCandidate()
{
    m_candidateFrequencyHz = 0.0;
    m_candidateMidiNote = -1;
    m_stablePitchFrameCount = 0;
}

void AubioMicrophoneInputController::updateNoiseCalibration(double sumSquares, int sampleCount)
{
    if (!m_noiseCalibrationActive || sampleCount <= 0) {
        return;
    }

    m_noiseCalibrationSumSquares += sumSquares;
    m_noiseCalibrationSamples += static_cast<quint64>(sampleCount);

    if (m_noiseCalibrationSamples < m_sampleRate) {
        return;
    }

    const double noiseFloor = std::sqrt(m_noiseCalibrationSumSquares / static_cast<double>(m_noiseCalibrationSamples));
    m_noiseFloorLevel = noiseFloor;

    // +15 dB above measured RMS floor. Keep a small minimum so denormalized silence
    // does not create an unusably sensitive gate.
    const double calibratedGate = std::clamp(noiseFloor * 5.6234132519, 0.003, 0.25);
    m_inputGateLevel = calibratedGate;

    m_noiseCalibrationActive = false;
    m_noiseCalibrationSumSquares = 0.0;
    m_noiseCalibrationSamples = 0;

    Q_EMIT noiseFloorLevelChanged();
    Q_EMIT inputGateLevelChanged();
    Q_EMIT audioLevelChanged();
    Q_EMIT noiseCalibrationActiveChanged();

    setStatus(QStringLiteral("Noise calibration done: floor=%1%, input gate=%2% (+15 dB).")
                  .arg(m_noiseFloorLevel * 100.0, 0, 'f', 2)
                  .arg(m_inputGateLevel * 100.0, 0, 'f', 2));
    qInfo().noquote() << QStringLiteral("Noise calibration done: floor=%1 gate=%2")
        .arg(m_noiseFloorLevel, 0, 'f', 6)
        .arg(m_inputGateLevel, 0, 'f', 6);
}

void AubioMicrophoneInputController::applyUnvoicedResult(const QString &reason)
{
    const QString nextStatus = reason.isEmpty() ? QStringLiteral("No stable voice detected") : reason;
    const bool changed = m_voiced || m_frequencyHz != 0.0 || m_pitchConfidence != 0.0 || m_midiNote != -1 || m_pitchStatus != nextStatus;

    m_frequencyHz = 0.0;
    m_midiNote = -1;
    m_cents = 0.0;
    m_pitchConfidence = 0.0;
    m_voiced = false;
    m_detectedVoiceClass = QStringLiteral("-");
    m_pitchStatus = nextStatus;

    if (changed) {
        Q_EMIT pitchChanged();
    }
}

void AubioMicrophoneInputController::registerOnset(double onsetSeconds, double strength)
{
    if (!inputGateOpen()) {
        return;
    }

    if (strength < m_minimumOnsetStrength) {
        return;
    }

    if (m_lastOnsetSeconds >= 0.0 && onsetSeconds - m_lastOnsetSeconds < 0.08) {
        return; // debounce duplicate detections within 80 ms
    }

    m_previousOnsetSeconds = m_lastOnsetSeconds;
    m_lastOnsetSeconds = onsetSeconds;
    ++m_onsetCount;

    if (m_referenceOnsetSeconds < 0.0) {
        m_referenceOnsetSeconds = onsetSeconds;
        m_lastTimingErrorMs = 0.0;
        m_rhythmStatus = QStringLiteral("First onset: timing reference set");
    } else {
        const double beatDuration = 60.0 / m_targetBpm;
        const double relativeTime = onsetSeconds - m_referenceOnsetSeconds;
        const double nearestBeat = std::round(relativeTime / beatDuration) * beatDuration;
        m_lastTimingErrorMs = (relativeTime - nearestBeat) * 1000.0;
        m_rhythmStatus = classifyRhythm(m_lastTimingErrorMs);
    }

    if (m_previousOnsetSeconds >= 0.0) {
        const double interval = onsetSeconds - m_previousOnsetSeconds;
        if (interval > 0.12 && interval < 4.0) {
            const double instantBpm = 60.0 / interval;
            if (m_detectedBpm <= 0.0) {
                m_detectedBpm = instantBpm;
            } else {
                m_detectedBpm = 0.75 * m_detectedBpm + 0.25 * instantBpm;
            }
        }
    }

    qInfo().noquote() << QStringLiteral("aubio onset #%1 t=%2s strength=%3 timingError=%4ms bpm=%5")
        .arg(m_onsetCount)
        .arg(onsetSeconds, 0, 'f', 3)
        .arg(strength, 0, 'f', 3)
        .arg(m_lastTimingErrorMs, 0, 'f', 1)
        .arg(m_detectedBpm, 0, 'f', 1);

    Q_EMIT rhythmChanged();
    Q_EMIT onsetDetected(onsetSeconds, strength);
}

void AubioMicrophoneInputController::resetIfRunning()
{
    if (!m_running) {
        return;
    }
    stop();
    start();
}

void AubioMicrophoneInputController::applyPreset(Preset preset, bool restartIfRunning)
{
    const bool wasRunning = m_running;
    if (wasRunning && restartIfRunning) {
        stop();
    }

    m_preset = preset;

    switch (preset) {
    case Singing:
        // Singing favors softer vocal attacks and stable low-confidence F0 frames.
        // These values are intentionally permissive enough for laptop, webcam,
        // phone, and tablet microphones across SATB ranges; the app-level input
        // gate and stable-frame filter do most of the false-positive rejection.
        m_pitchMethod = Yin;
        m_onsetMethod = Hfc;
        m_minimumPitchConfidence = 0.05;
        m_pitchSilenceDb = -65.0;
        m_onsetThreshold = 0.14;
        m_inputGateLevel = 0.006;
        m_minimumOnsetStrength = 0.006;
        m_requiredStablePitchFrames = 2;
        break;
    case Clapping:
        // Clapping is percussive: ignore weak background changes, require a
        // stronger transient, and use aubio's complex onset detector. Pitch is
        // still computed for diagnostics but is not expected to be meaningful.
        m_pitchMethod = YinFft;
        m_onsetMethod = Complex;
        m_minimumPitchConfidence = 0.70;
        m_pitchSilenceDb = -45.0;
        m_onsetThreshold = 0.32;
        m_inputGateLevel = 0.025;
        m_minimumOnsetStrength = 0.040;
        m_requiredStablePitchFrames = 2;
        break;
    }

    resetPitchCandidate();

    Q_EMIT presetChanged();
    Q_EMIT pitchMethodChanged();
    Q_EMIT onsetMethodChanged();
    Q_EMIT minimumPitchConfidenceChanged();
    Q_EMIT pitchSilenceDbChanged();
    Q_EMIT onsetThresholdChanged();
    Q_EMIT inputGateLevelChanged();
    Q_EMIT minimumOnsetStrengthChanged();
    Q_EMIT requiredStablePitchFramesChanged();
    Q_EMIT audioLevelChanged();
    Q_EMIT pitchChanged();

    setStatus(QStringLiteral("%1 preset applied. Start listening, then calibrate silence for this microphone/environment.")
                  .arg(presetName(m_preset)));

    qInfo().noquote() << QStringLiteral("Preset applied: %1 pitch=%2 onset=%3 pitchConf=%4 silenceDb=%5 onsetThreshold=%6 inputGate=%7 minOnsetStrength=%8 stableFrames=%9")
        .arg(presetName(m_preset),
             QString::fromLatin1(aubioPitchMethodName(m_pitchMethod)),
             QString::fromLatin1(aubioOnsetMethodName(m_onsetMethod)))
        .arg(m_minimumPitchConfidence, 0, 'f', 2)
        .arg(m_pitchSilenceDb, 0, 'f', 0)
        .arg(m_onsetThreshold, 0, 'f', 2)
        .arg(m_inputGateLevel, 0, 'f', 4)
        .arg(m_minimumOnsetStrength, 0, 'f', 3)
        .arg(m_requiredStablePitchFrames);

    if (wasRunning && restartIfRunning) {
        start();
    } else if (m_onset) {
        aubio_onset_set_threshold(m_onset.get(), static_cast<smpl_t>(m_onsetThreshold));
        aubio_onset_set_silence(m_onset.get(), static_cast<smpl_t>(m_pitchSilenceDb));
    }
    if (!wasRunning && m_pitch) {
        aubio_pitch_set_silence(m_pitch.get(), static_cast<smpl_t>(m_pitchSilenceDb));
    }
}

void AubioMicrophoneInputController::maybePrintDebug(double timeSeconds, double frequencyHz, double confidence)
{
    if (m_processedSamples - m_lastDebugSample < m_sampleRate) {
        return;
    }
    m_lastDebugSample = m_processedSamples;
    qInfo().noquote() << QStringLiteral("aubio frame t=%1s bytes=%2 samples=%3 level=%4 peak=%5 gate=%6 gateOpen=%7 noiseFloor=%8 stable=%9/%10 f0=%11Hz confidence=%12 pending=%13")
        .arg(timeSeconds, 0, 'f', 2)
        .arg(m_bytesRead)
        .arg(m_processedSamples)
        .arg(m_audioLevel, 0, 'f', 4)
        .arg(m_peakLevel, 0, 'f', 4)
        .arg(m_inputGateLevel, 0, 'f', 4)
        .arg(inputGateOpen() ? QStringLiteral("yes") : QStringLiteral("no"))
        .arg(m_noiseFloorLevel, 0, 'f', 4)
        .arg(m_stablePitchFrameCount)
        .arg(m_requiredStablePitchFrames)
        .arg(frequencyHz, 0, 'f', 2)
        .arg(confidence, 0, 'f', 3)
        .arg(m_pendingSamples.size());
}

QString AubioMicrophoneInputController::noteNameForMidi(int midiNote)
{
    if (midiNote < 0) {
        return QStringLiteral("-");
    }
    static constexpr const char *names[] = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
    const int noteIndex = ((midiNote % 12) + 12) % 12;
    const int octave = midiNote / 12 - 1;
    return QStringLiteral("%1%2").arg(QString::fromUtf8(names[noteIndex])).arg(octave);
}

double AubioMicrophoneInputController::frequencyForMidi(int midiNote)
{
    return 440.0 * std::pow(2.0, (static_cast<double>(midiNote) - 69.0) / 12.0);
}

double AubioMicrophoneInputController::midiFromFrequency(double frequencyHz)
{
    return 69.0 + 12.0 * std::log2(frequencyHz / 440.0);
}

const char *AubioMicrophoneInputController::aubioPitchMethodName(PitchMethod method)
{
    switch (method) {
    case YinFft: return "yinfft";
    case Yin: return "yin";
    case YinFast: return "yinfast";
    case MComb: return "mcomb";
    case Schmitt: return "schmitt";
    case SpecAcf: return "specacf";
    case FComb: return "fcomb";
    }
    return "yinfft";
}

const char *AubioMicrophoneInputController::aubioOnsetMethodName(OnsetMethod method)
{
    switch (method) {
    case Complex: return "complex";
    case Hfc: return "hfc";
    case Energy: return "energy";
    case SpecFlux: return "specflux";
    case Phase: return "phase";
    case SpecDiff: return "specdiff";
    case Kl: return "kl";
    case Mkl: return "mkl";
    }
    return "complex";
}

double AubioMicrophoneInputController::minFrequencyForCurrentVoiceClass() const
{
    return voiceClassMinHz(m_voiceClass);
}

double AubioMicrophoneInputController::maxFrequencyForCurrentVoiceClass() const
{
    return voiceClassMaxHz(m_voiceClass);
}

QString AubioMicrophoneInputController::voiceClassForFrequency(double frequencyHz) const
{
    QStringList classes;
    for (int i = Soprano; i <= Bass; ++i) {
        if (frequencyHz >= voiceClassMinHz(i) && frequencyHz <= voiceClassMaxHz(i)) {
            classes.append(voiceClassName(i));
        }
    }
    return classes.isEmpty() ? QStringLiteral("outside SATB") : classes.join(QStringLiteral(" / "));
}

QString AubioMicrophoneInputController::classifyPitch(double frequencyHz, double cents, double confidence) const
{
    const bool insideSelectedRange = frequencyHz >= minFrequencyForCurrentVoiceClass() && frequencyHz <= maxFrequencyForCurrentVoiceClass();
    const QString rangeText = insideSelectedRange
        ? QStringLiteral("inside selected %1 range").arg(voiceClassName(m_voiceClass))
        : QStringLiteral("outside selected %1 range").arg(voiceClassName(m_voiceClass));

    QString quality;
    if (confidence < m_minimumPitchConfidence) {
        quality = QStringLiteral("Low confidence F0");
    } else {
        const double absCents = std::abs(cents);
        if (absCents < 10.0) {
            quality = QStringLiteral("Excellent intonation");
        } else if (absCents < 25.0) {
            quality = cents > 0.0 ? QStringLiteral("Good, slightly sharp") : QStringLiteral("Good, slightly flat");
        } else if (absCents < 50.0) {
            quality = cents > 0.0 ? QStringLiteral("Sharp") : QStringLiteral("Flat");
        } else {
            quality = cents > 0.0 ? QStringLiteral("Too sharp / maybe wrong note") : QStringLiteral("Too flat / maybe wrong note");
        }
    }

    return QStringLiteral("%1; %2; detected class: %3")
        .arg(quality, rangeText, voiceClassForFrequency(frequencyHz));
}

QString AubioMicrophoneInputController::classifyRhythm(double timingErrorMs) const
{
    const double absError = std::abs(timingErrorMs);
    if (absError < 40.0) {
        return QStringLiteral("Excellent timing");
    }
    if (absError < 80.0) {
        return timingErrorMs > 0.0 ? QStringLiteral("Good, slightly late") : QStringLiteral("Good, slightly early");
    }
    if (absError < 150.0) {
        return timingErrorMs > 0.0 ? QStringLiteral("Late") : QStringLiteral("Early");
    }
    return timingErrorMs > 0.0 ? QStringLiteral("Very late") : QStringLiteral("Very early");
}
