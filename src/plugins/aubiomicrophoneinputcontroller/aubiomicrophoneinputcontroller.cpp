// SPDX-License-Identifier: GPL-2.0-or-later

#include "aubiomicrophoneinputcontroller.h"

#include <QAudioDevice>
#include <QAudio>
#include <QAudioSource>
#include <QByteArray>
#include <QCoreApplication>
#include <QDebug>
#include <QIODevice>
#include <QMediaDevices>
#include <QPermissions>
#include <QStringList>
#include <QVariantMap>

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace
{
double clamp01(double value)
{
    return std::clamp(value, 0.0, 1.0);
}

double amplitudeToDbFs(double amplitude)
{
    return amplitude > 0.0 ? 20.0 * std::log10(amplitude) : -120.0;
}
}

AubioMicrophoneInputController::AubioMicrophoneInputController(QObject *parent)
    : Minuet::IMicrophoneInputController(parent)
    , m_activeGeneration(std::make_shared<std::atomic<quint64>>(0))
{
    m_analysisWorker = new AubioAnalysisWorker(m_activeGeneration);
    m_analysisWorker->moveToThread(&m_analysisThread);
    connect(&m_analysisThread, &QThread::finished, m_analysisWorker, &QObject::deleteLater);
    connect(m_analysisWorker, &AubioAnalysisWorker::initializationFailed, this, [this](quint64 generation, const QString &message) {
        if (generation != m_generation) {
            return;
        }
        stop();
        setStatus(message);
        Q_EMIT inputAnalysisFailed(message);
    });
    connect(m_analysisWorker, &AubioAnalysisWorker::chunkProcessed, this, [this](quint64 generation, qsizetype byteCount) {
        if (generation == m_generation) {
            m_queuedAnalysisBytes = std::max<qsizetype>(0, m_queuedAnalysisBytes - byteCount);
        }
    });
    connect(m_analysisWorker,
            &AubioAnalysisWorker::statsUpdated,
            this,
            [this](quint64 generation, quint64 processedSamples, double audioLevel, double peakLevel, int stablePitchFrames) {
                if (generation != m_generation) {
                    return;
                }
                const bool levelChanged = std::abs(m_audioLevel - audioLevel) > 0.002 || std::abs(m_peakLevel - peakLevel) > 0.002;
                m_processedSamples = processedSamples;
                m_audioLevel = audioLevel;
                m_peakLevel = peakLevel;
                m_stablePitchFrameCount = stablePitchFrames;
                if (levelChanged) {
                    Q_EMIT audioLevelChanged();
                }
                Q_EMIT audioStatsChanged();
            });
    connect(m_analysisWorker,
            &AubioAnalysisWorker::pitchResult,
            this,
            [this](quint64 generation, double seconds, bool voiced, double frequencyHz, double confidence, const QString &reason) {
                if (generation == m_generation) {
                    handleWorkerPitch(seconds, voiced, frequencyHz, confidence, reason);
                }
            });
    connect(m_analysisWorker, &AubioAnalysisWorker::onsetResult, this, [this](quint64 generation, double seconds, double strength) {
        if (generation == m_generation) {
            handleWorkerOnset(seconds, strength);
        }
    });
    connect(m_analysisWorker, &AubioAnalysisWorker::noiseCalibrationFinished, this, [this](quint64 generation, double noiseFloor) {
        if (generation != m_generation) {
            return;
        }
        m_noiseFloorLevel = noiseFloor;
        m_inputGateLevel = std::clamp(noiseFloor * 5.6234132519, 0.003, 0.25);
        applyCalibratedDetectorThresholds(noiseFloor);
        m_noiseCalibrationActive = false;
        Q_EMIT noiseFloorLevelChanged();
        Q_EMIT inputGateLevelChanged();
        Q_EMIT audioLevelChanged();
        Q_EMIT noiseCalibrationActiveChanged();
        updateWorkerConfig();
        setStatus(QStringLiteral("Noise calibration done: floor=%1%, input gate=%2% (+15 dB).")
                      .arg(m_noiseFloorLevel * 100.0, 0, 'f', 2)
                      .arg(m_inputGateLevel * 100.0, 0, 'f', 2));
    });
    connect(m_analysisWorker, &AubioAnalysisWorker::drained, this, [this](quint64 generation) {
        if (generation != m_generation || !m_analysisPending) {
            return;
        }
        m_analysisPending = false;
        Q_EMIT analysisPendingChanged();
        setStatus(QStringLiteral("Analysis complete."));
        Q_EMIT inputAnalysisFinished();
    });
    m_analysisThread.setObjectName(QStringLiteral("Minuet Aubio analysis"));
    m_analysisThread.start();

    m_pollTimer.setInterval(20);
    connect(&m_pollTimer, &QTimer::timeout, this, &AubioMicrophoneInputController::readAudioData);
    connect(&m_mediaDevices, &QMediaDevices::audioInputsChanged, this, &AubioMicrophoneInputController::updateInputDevices);
    updateInputDevices();
    setStatus(QStringLiteral("Ready. Press Start and sing, speak, clap, or tap near the microphone."));
}

AubioMicrophoneInputController::~AubioMicrophoneInputController()
{
    stop();
    m_analysisThread.quit();
    m_analysisThread.wait();
    aubio_cleanup();
}

bool AubioMicrophoneInputController::running() const { return m_running; }
QString AubioMicrophoneInputController::status() const { return m_status; }
double AubioMicrophoneInputController::analysisTimeSeconds() const
{
    return m_sampleRate > 0 ? static_cast<double>(m_processedSamples) / static_cast<double>(m_sampleRate) : 0.0;
}
double AubioMicrophoneInputController::captureTimeSeconds() const
{
    return m_sampleRate > 0 ? static_cast<double>(m_capturedSamples) / static_cast<double>(m_sampleRate) : 0.0;
}
bool AubioMicrophoneInputController::analysisPending() const { return m_analysisPending; }
Minuet::IMicrophoneInputController::Preset AubioMicrophoneInputController::preset() const { return m_preset; }
Minuet::IMicrophoneInputController::AnalysisMode AubioMicrophoneInputController::analysisMode() const { return m_analysisMode; }
Minuet::IMicrophoneInputController::VoiceClass AubioMicrophoneInputController::voiceClass() const { return m_voiceClass; }
Minuet::IMicrophoneInputController::PitchMethod AubioMicrophoneInputController::pitchMethod() const { return m_pitchMethod; }
Minuet::IMicrophoneInputController::OnsetMethod AubioMicrophoneInputController::onsetMethod() const { return m_onsetMethod; }
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
QVariantList AubioMicrophoneInputController::inputDevices() const { return m_inputDevices; }
bool AubioMicrophoneInputController::inputDeviceAvailable() const { return !m_inputDevices.isEmpty(); }
QString AubioMicrophoneInputController::inputDeviceId() const { return m_inputDeviceId; }
double AubioMicrophoneInputController::audioLevel() const { return m_audioLevel; }
double AubioMicrophoneInputController::peakLevel() const { return m_peakLevel; }
quint64 AubioMicrophoneInputController::bytesRead() const { return m_bytesRead; }
quint64 AubioMicrophoneInputController::processedSamples() const { return m_processedSamples; }
double AubioMicrophoneInputController::frequencyHz() const { return m_frequencyHz; }
int AubioMicrophoneInputController::midiNote() const { return m_midiNote; }
double AubioMicrophoneInputController::cents() const { return m_cents; }
double AubioMicrophoneInputController::pitchConfidence() const { return m_pitchConfidence; }
bool AubioMicrophoneInputController::voiced() const { return m_voiced; }
int AubioMicrophoneInputController::onsetCount() const { return m_onsetCount; }
double AubioMicrophoneInputController::lastOnsetSeconds() const { return m_lastOnsetSeconds; }

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

void AubioMicrophoneInputController::setAnalysisMode(AnalysisMode mode)
{
    if (m_analysisMode == mode) {
        return;
    }
    m_analysisMode = mode;
    Q_EMIT analysisModeChanged();
    resetIfRunning();
}

void AubioMicrophoneInputController::setVoiceClass(VoiceClass voiceClass)
{
    if (m_voiceClass == voiceClass) {
        return;
    }
    m_voiceClass = voiceClass;
    Q_EMIT voiceClassChanged();
    updateWorkerConfig();
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

void AubioMicrophoneInputController::setMinimumPitchConfidence(double confidence)
{
    confidence = clamp01(confidence);
    if (qFuzzyCompare(m_minimumPitchConfidence, confidence)) {
        return;
    }
    m_minimumPitchConfidence = confidence;
    Q_EMIT minimumPitchConfidenceChanged();
    updateWorkerConfig();
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
    Q_EMIT onsetThresholdChanged();
    updateWorkerConfig();
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
    updateWorkerConfig();
}

void AubioMicrophoneInputController::setMinimumOnsetStrength(double strength)
{
    strength = std::clamp(strength, 0.0, 1.0);
    if (qFuzzyCompare(m_minimumOnsetStrength, strength)) {
        return;
    }
    m_minimumOnsetStrength = strength;
    Q_EMIT minimumOnsetStrengthChanged();
    updateWorkerConfig();
}

void AubioMicrophoneInputController::setRequiredStablePitchFrames(int frames)
{
    frames = std::clamp(frames, 1, 10);
    if (m_requiredStablePitchFrames == frames) {
        return;
    }
    m_requiredStablePitchFrames = frames;
    Q_EMIT requiredStablePitchFramesChanged();
    Q_EMIT pitchChanged();
    updateWorkerConfig();
}

void AubioMicrophoneInputController::setInputDeviceId(const QString &deviceId)
{
    if (m_inputDeviceId == deviceId) {
        return;
    }

    m_inputDeviceId = deviceId;
    Q_EMIT inputDeviceIdChanged();
    resetIfRunning();
}

void AubioMicrophoneInputController::start()
{
    if (m_running) {
        return;
    }

    resetRuntimeState();

    if (!ensureMicrophonePermission()) {
        return;
    }

    if (!configureAudioInput()) {
        return;
    }

    m_generation = m_activeGeneration->fetch_add(1, std::memory_order_relaxed) + 1;
    const quint64 generation = m_generation;
    const AubioAnalysisWorker::Config config = workerConfig();
    const int sampleRate = m_audioFormat.sampleRate();
    const int channelCount = m_audioFormat.channelCount();
    const int sampleFormat = static_cast<int>(m_audioFormat.sampleFormat());
    const int bytesPerSample = m_audioFormat.bytesPerSample();
    QMetaObject::invokeMethod(m_analysisWorker, [worker = m_analysisWorker, generation, config, sampleRate, channelCount, sampleFormat, bytesPerSample] {
        worker->initialize(generation, config, sampleRate, channelCount, sampleFormat, bytesPerSample);
    });

    m_audioDevice = m_audioSource->start();
    if (!m_audioDevice) {
        setStatus(QStringLiteral("Failed to start audio input."));
        m_generation = m_activeGeneration->fetch_add(1, std::memory_order_relaxed) + 1;
        m_audioSource.reset();
        return;
    }

    connect(m_audioDevice, &QIODevice::readyRead, this, &AubioMicrophoneInputController::readAudioData);
    m_pollTimer.start();

    m_running = true;
    Q_EMIT runningChanged();

    const QString pitchText = pitchDetectorEnabled() ? QString::fromLatin1(aubioPitchMethodName(m_pitchMethod)) : QStringLiteral("off");
    const QString onsetText = onsetDetectorEnabled() ? QString::fromLatin1(aubioOnsetMethodName(m_onsetMethod)) : QStringLiteral("off");
    setStatus(QStringLiteral("Listening on %1. mode=%2, preset=%3, pitch=%4, onset=%5, selected SATB range=%6 (%7–%8 Hz).")
                  .arg(m_inputDeviceDescription,
                       analysisModeName(m_analysisMode),
                       presetName(m_preset),
                       pitchText,
                       onsetText,
                       voiceClassName(m_voiceClass))
                  .arg(minFrequencyForCurrentVoiceClass(), 0, 'f', 0)
                  .arg(maxFrequencyForCurrentVoiceClass(), 0, 'f', 0));

    qInfo().noquote() << QStringLiteral("AubioMicrophoneInputController started: device='%1', sampleRate=%2, channels=%3, format=%4, mode=%5, preset=%6, pitch=%7, onset=%8, pitchConfThreshold=%9, onsetThreshold=%10, inputGate=%11, silenceDb=%12, minOnsetStrength=%13, stableFrames=%14")
        .arg(m_inputDeviceDescription)
        .arg(m_audioFormat.sampleRate())
        .arg(m_audioFormat.channelCount())
        .arg(static_cast<int>(m_audioFormat.sampleFormat()))
        .arg(analysisModeName(m_analysisMode))
        .arg(presetName(m_preset))
        .arg(pitchText)
        .arg(onsetText)
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
    const quint64 generation = m_generation;
    QMetaObject::invokeMethod(m_analysisWorker, [worker = m_analysisWorker, generation] {
        worker->startNoiseCalibration(generation);
    });
}

void AubioMicrophoneInputController::resetInputAnalysisState()
{
    resetDetectionState();
    m_generation = m_activeGeneration->fetch_add(1, std::memory_order_relaxed) + 1;
    m_queuedAnalysisBytes = 0;
    const quint64 generation = m_generation;
    const quint64 captureFrame = m_capturedSamples;
    const AubioAnalysisWorker::Config config = workerConfig();
    QMetaObject::invokeMethod(m_analysisWorker, [worker = m_analysisWorker, generation, config, captureFrame] {
        worker->resetAnalysis(generation, captureFrame);
        worker->updateConfig(generation, config);
    });
    qInfo().noquote() << QStringLiteral("Input analysis state reset: mode=%1 preset=%2 threshold=%3 minOnsetStrength=%4")
        .arg(analysisModeName(m_analysisMode),
             presetName(m_preset))
        .arg(m_onsetThreshold, 0, 'f', 2)
        .arg(m_minimumOnsetStrength, 0, 'f', 3);
}

void AubioMicrophoneInputController::stop()
{
    if (!m_running && !m_audioSource && !m_analysisPending) {
        return;
    }

    m_generation = m_activeGeneration->fetch_add(1, std::memory_order_relaxed) + 1;
    stopAudioCapture();
    m_queuedAnalysisBytes = 0;
    if (m_analysisPending) {
        m_analysisPending = false;
        Q_EMIT analysisPendingChanged();
    }

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

void AubioMicrophoneInputController::finalizeInputAnalysis()
{
    if (m_analysisPending) {
        return;
    }
    if (!m_running) {
        Q_EMIT inputAnalysisFinished();
        return;
    }

    readAudioData();
    if (!m_running) {
        return;
    }
    stopAudioCapture();
    const bool wasRunning = m_running;
    m_running = false;
    if (wasRunning) {
        Q_EMIT runningChanged();
    }
    m_analysisPending = true;
    Q_EMIT analysisPendingChanged();
    setStatus(QStringLiteral("Analyzing..."));
    const quint64 generation = m_generation;
    QMetaObject::invokeMethod(m_analysisWorker, [worker = m_analysisWorker, generation] {
        worker->drain(generation);
    });
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
    m_processedSamples = 0;
    resetDetectionState();
    m_noiseCalibrationActive = false;
    m_noiseCalibrationSumSquares = 0.0;
    m_noiseCalibrationSamples = 0;
    Q_EMIT noiseCalibrationActiveChanged();
    m_bytesRead = 0;
    m_capturedSamples = 0;
    m_queuedAnalysisBytes = 0;
    if (m_analysisPending) {
        m_analysisPending = false;
        Q_EMIT analysisPendingChanged();
    }
    m_audioLevel = 0.0;
    m_peakLevel = 0.0;
    Q_EMIT captureTimeChanged();
    Q_EMIT audioLevelChanged();
    Q_EMIT audioStatsChanged();
}

void AubioMicrophoneInputController::resetDetectionState()
{
    m_frequencyHz = 0.0;
    m_midiNote = -1;
    m_cents = 0.0;
    m_pitchConfidence = 0.0;
    m_voiced = false;
    Q_EMIT pitchChanged();

    m_onsetCount = 0;
    m_lastOnsetSeconds = -1.0;
    Q_EMIT rhythmChanged();
}

bool AubioMicrophoneInputController::ensureMicrophonePermission()
{
#if QT_CONFIG(permissions)
    QCoreApplication *application = QCoreApplication::instance();
    if (!application) {
        return true;
    }

    const QMicrophonePermission permission;
    switch (application->checkPermission(permission)) {
    case Qt::PermissionStatus::Granted:
        return true;
    case Qt::PermissionStatus::Denied:
        setStatus(QStringLiteral("Microphone permission denied. Enable microphone access for Minuet in system privacy settings."));
        qWarning() << "Microphone permission denied";
        return false;
    case Qt::PermissionStatus::Undetermined:
        if (m_microphonePermissionRequestPending) {
            setStatus(QStringLiteral("Waiting for microphone permission..."));
            return false;
        }

        m_microphonePermissionRequestPending = true;
        setStatus(QStringLiteral("Waiting for microphone permission..."));
        application->requestPermission(permission, this, [this](QPermission permission) {
            m_microphonePermissionRequestPending = false;
            if (permission.status() == Qt::PermissionStatus::Granted) {
                qInfo() << "Microphone permission granted";
                start();
                return;
            }

            setStatus(QStringLiteral("Microphone permission denied. Enable microphone access for Minuet in system privacy settings."));
            qWarning() << "Microphone permission denied";
        });
        return false;
    }

    return false;
#else
    return true;
#endif
}

bool AubioMicrophoneInputController::configureAudioInput()
{
    updateInputDevices();

    QAudioDevice inputDevice;
    const QList<QAudioDevice> devices = QMediaDevices::audioInputs();
    const QByteArray selectedDeviceId = m_inputDeviceId.toUtf8();
    if (!selectedDeviceId.isEmpty()) {
        for (const QAudioDevice &device : devices) {
            if (device.id() == selectedDeviceId) {
                inputDevice = device;
                break;
            }
        }
    }
    if (inputDevice.isNull()) {
        inputDevice = QMediaDevices::defaultAudioInput();
    }
    if (inputDevice.isNull() && !devices.isEmpty()) {
        inputDevice = devices.constFirst();
    }
    if (inputDevice.isNull()) {
        setStatus(QStringLiteral("No audio input device found."));
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

void AubioMicrophoneInputController::updateInputDevices()
{
    const bool wasAvailable = inputDeviceAvailable();
    QVariantList inputDevices;
    const QList<QAudioDevice> devices = QMediaDevices::audioInputs();
    const QByteArray defaultDeviceId = QMediaDevices::defaultAudioInput().id();

    for (const QAudioDevice &device : devices) {
        QVariantMap deviceData;
        deviceData.insert(QStringLiteral("id"), QString::fromUtf8(device.id()));
        deviceData.insert(QStringLiteral("description"), device.description());
        deviceData.insert(QStringLiteral("displayName"), device.description());
        deviceData.insert(QStringLiteral("isDefault"), device.id() == defaultDeviceId);
        inputDevices.push_back(deviceData);
    }

    if (m_inputDevices != inputDevices) {
        m_inputDevices = inputDevices;
        Q_EMIT inputDevicesChanged();
    }

    const bool available = inputDeviceAvailable();
    if (wasAvailable != available) {
        Q_EMIT inputDeviceAvailableChanged();
    }

    if (m_running) {
        resetIfRunning();
    }
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
    const int bytesPerFrame = m_audioFormat.bytesPerSample() * m_audioFormat.channelCount();
    if (bytesPerFrame <= 0) {
        return;
    }
    m_capturedSamples += static_cast<quint64>(bytes.size() / bytesPerFrame);
    Q_EMIT captureTimeChanged();

    const qsizetype maximumQueuedBytes = static_cast<qsizetype>(m_sampleRate) * bytesPerFrame * 2;
    if (m_queuedAnalysisBytes + bytes.size() > maximumQueuedBytes) {
        const QString message = QStringLiteral("Audio analysis could not keep up with microphone input.");
        stop();
        setStatus(message);
        Q_EMIT inputAnalysisFailed(message);
        return;
    }

    m_queuedAnalysisBytes += bytes.size();
    const quint64 generation = m_generation;
    QMetaObject::invokeMethod(m_analysisWorker, [worker = m_analysisWorker, generation, bytes] {
        worker->processAudio(generation, bytes);
    });
}

void AubioMicrophoneInputController::applyCalibratedDetectorThresholds(double noiseFloor)
{
    // FMP 6.1/6.4: calibrate the detector floor before peak picking so room noise is not treated as novelty.
    const double silenceMarginDb = m_preset == Clapping ? 12.0 : 15.0;
    m_pitchSilenceDb = std::clamp(amplitudeToDbFs(noiseFloor) + silenceMarginDb, -90.0, -25.0);
    m_calibratedOnsetStrengthFloor = std::clamp(noiseFloor * (m_preset == Clapping ? 4.0 : 2.0), 0.0, 0.20);
    m_onsetThreshold = std::clamp(m_onsetThreshold + noiseFloor * (m_preset == Clapping ? 1.5 : 0.75), 0.01, 1.0);

    Q_EMIT pitchSilenceDbChanged();
    Q_EMIT minimumOnsetStrengthChanged();
    Q_EMIT onsetThresholdChanged();
}

void AubioMicrophoneInputController::applyUnvoicedResult(const QString &reason)
{
    Q_UNUSED(reason)
    const bool changed = m_voiced || m_frequencyHz != 0.0 || m_pitchConfidence != 0.0 || m_midiNote != -1;

    m_frequencyHz = 0.0;
    m_midiNote = -1;
    m_cents = 0.0;
    m_pitchConfidence = 0.0;
    m_voiced = false;

    if (changed) {
        Q_EMIT pitchChanged();
    }
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
    m_calibratedOnsetStrengthFloor = 0.0;

    switch (preset) {
    case Singing:
        // Singing favors softer vocal attacks and stable low-confidence F0 frames.
        // These values are intentionally permissive enough for laptop, webcam,
        // phone, and tablet microphones across SATB ranges; the app-level input
        // gate and stable-frame filter do most of the false-positive rejection.
        m_pitchMethod = Yin;
        // FMP 6.1.4: complex-domain novelty is useful for softer vocal note transitions.
        m_onsetMethod = Complex;
        m_minimumPitchConfidence = 0.05;
        m_pitchSilenceDb = -65.0;
        m_onsetThreshold = 0.14;
        m_inputGateLevel = 0.006;
        m_minimumOnsetStrength = 0.006;
        m_requiredStablePitchFrames = 2;
        break;
    case Clapping:
        // FMP 6.1.2 and 6.4.1: claps are broadband high-frequency transients, so HFC onset is the task-specific default.
        m_onsetMethod = Hfc;
        m_minimumPitchConfidence = 0.70;
        m_pitchSilenceDb = -45.0;
        m_onsetThreshold = 0.30;
        m_inputGateLevel = 0.0;
        m_minimumOnsetStrength = 0.015;
        m_requiredStablePitchFrames = 2;
        break;
    }

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

    setStatus(QStringLiteral("%1 preset applied for %2. Start listening, then calibrate silence for this microphone/environment.")
                  .arg(presetName(m_preset), analysisModeName(m_analysisMode)));

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
    }
}

AubioAnalysisWorker::Config AubioMicrophoneInputController::workerConfig() const
{
    AubioAnalysisWorker::Config config;
    config.preset = static_cast<int>(m_preset);
    config.analysisMode = static_cast<int>(m_analysisMode);
    config.pitchMethod = static_cast<int>(m_pitchMethod);
    config.onsetMethod = static_cast<int>(m_onsetMethod);
    config.voiceMinHz = minFrequencyForCurrentVoiceClass();
    config.voiceMaxHz = maxFrequencyForCurrentVoiceClass();
    config.minimumPitchConfidence = m_minimumPitchConfidence;
    config.pitchSilenceDb = m_pitchSilenceDb;
    config.onsetThreshold = m_onsetThreshold;
    config.inputGateLevel = m_inputGateLevel;
    config.minimumOnsetStrength = m_minimumOnsetStrength;
    config.calibratedOnsetStrengthFloor = m_calibratedOnsetStrengthFloor;
    config.requiredStablePitchFrames = m_requiredStablePitchFrames;
    return config;
}

void AubioMicrophoneInputController::updateWorkerConfig()
{
    if (!m_running && !m_analysisPending) {
        return;
    }
    const quint64 generation = m_generation;
    const AubioAnalysisWorker::Config config = workerConfig();
    QMetaObject::invokeMethod(m_analysisWorker, [worker = m_analysisWorker, generation, config] {
        worker->updateConfig(generation, config);
    });
}

void AubioMicrophoneInputController::handleWorkerPitch(double seconds,
                                                       bool voiced,
                                                       double frequencyHz,
                                                       double confidence,
                                                       const QString &reason)
{
    if (!voiced) {
        applyUnvoicedResult(reason);
        return;
    }

    const double clampedConfidence = clamp01(confidence);
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
    if (changed) {
        Q_EMIT pitchChanged();
    }
    Q_EMIT pitchDetected(seconds, nearestMidi, cents, clampedConfidence);
}

void AubioMicrophoneInputController::handleWorkerOnset(double onsetSeconds, double strength)
{
    m_lastOnsetSeconds = onsetSeconds;
    ++m_onsetCount;

    qInfo().noquote() << QStringLiteral("aubio onset #%1 t=%2s strength=%3")
        .arg(m_onsetCount)
        .arg(onsetSeconds, 0, 'f', 3)
        .arg(strength, 0, 'f', 3);

    Q_EMIT rhythmChanged();
    Q_EMIT onsetDetected(onsetSeconds, strength);
}

void AubioMicrophoneInputController::stopAudioCapture()
{
    m_pollTimer.stop();
    if (m_audioDevice) {
        disconnect(m_audioDevice, &QIODevice::readyRead, this, &AubioMicrophoneInputController::readAudioData);
    }
    if (m_audioSource) {
        m_audioSource->stop();
    }
    m_audioDevice.clear();
    m_audioSource.reset();
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

bool AubioMicrophoneInputController::pitchDetectorEnabled() const
{
    return m_analysisMode == SingingPitchOnly;
}

bool AubioMicrophoneInputController::onsetDetectorEnabled() const
{
    return m_analysisMode == ClappingOnsetOnly;
}

QString AubioMicrophoneInputController::analysisModeName(AnalysisMode mode) const
{
    switch (mode) {
    case SingingPitchOnly: return QStringLiteral("singing pitch only");
    case ClappingOnsetOnly: return QStringLiteral("clapping onset only");
    }
    return QStringLiteral("unknown");
}
