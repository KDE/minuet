// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "../aubioanalysisworker.h"

#include <QAudioFormat>
#include <QSignalSpy>
#include <QTest>

#include <cmath>
#include <cstring>
#include <optional>

class AubioAnalysisWorkerTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void resetUsesCaptureFrame();
    void processingAdvancesAnalysisClock();
    void staleGenerationIsCancelled();
    void resetClearsPitchHistory();
    void pitchTimestampsCompensateAnalysisLatency();
};

void AubioAnalysisWorkerTest::resetUsesCaptureFrame()
{
    auto generation = std::make_shared<std::atomic<quint64>>(1);
    AubioAnalysisWorker worker(generation);
    AubioAnalysisWorker::Config config;
    config.analysisMode = 2;
    QSignalSpy failureSpy(&worker, &AubioAnalysisWorker::initializationFailed);
    QSignalSpy statsSpy(&worker, &AubioAnalysisWorker::statsUpdated);
    QSignalSpy drainedSpy(&worker, &AubioAnalysisWorker::drained);

    worker.initialize(1, config, 48000, 1, QAudioFormat::Int16, 2);
    QCOMPARE(failureSpy.count(), 0);
    worker.resetAnalysis(1, 24000);
    worker.drain(1);

    QCOMPARE(drainedSpy.count(), 1);
    QCOMPARE(statsSpy.count(), 1);
    QCOMPARE(statsSpy.constFirst().at(1).toULongLong(), 24000ULL);
}

void AubioAnalysisWorkerTest::processingAdvancesAnalysisClock()
{
    auto generation = std::make_shared<std::atomic<quint64>>(1);
    AubioAnalysisWorker worker(generation);
    AubioAnalysisWorker::Config config;
    config.analysisMode = 2;
    QSignalSpy statsSpy(&worker, &AubioAnalysisWorker::statsUpdated);

    worker.initialize(1, config, 48000, 1, QAudioFormat::Int16, 2);
    worker.processAudio(1, QByteArray(512 * 2, 0));
    worker.drain(1);

    QVERIFY(!statsSpy.isEmpty());
    QCOMPARE(statsSpy.constLast().at(1).toULongLong(), 512ULL);
}

void AubioAnalysisWorkerTest::staleGenerationIsCancelled()
{
    auto generation = std::make_shared<std::atomic<quint64>>(1);
    AubioAnalysisWorker worker(generation);
    AubioAnalysisWorker::Config config;
    config.analysisMode = 2;
    QSignalSpy chunkSpy(&worker, &AubioAnalysisWorker::chunkProcessed);
    QSignalSpy drainedSpy(&worker, &AubioAnalysisWorker::drained);

    worker.initialize(1, config, 48000, 1, QAudioFormat::Int16, 2);
    generation->store(2, std::memory_order_relaxed);
    worker.processAudio(1, QByteArray(512 * 2, 0));
    worker.drain(1);

    QCOMPARE(chunkSpy.count(), 1);
    QCOMPARE(drainedSpy.count(), 0);
}

void AubioAnalysisWorkerTest::resetClearsPitchHistory()
{
    constexpr int sampleRate = 48000;
    constexpr int hopSize = 512;
    constexpr double pi = 3.14159265358979323846;
    auto generation = std::make_shared<std::atomic<quint64>>(1);
    AubioAnalysisWorker worker(generation);
    AubioAnalysisWorker::Config config;
    config.analysisMode = 0;
    config.pitchMethod = 1;
    config.minimumPitchConfidence = 0.0;
    config.inputGateLevel = 0.0;
    config.requiredStablePitchFrames = 2;
    QSignalSpy pitchSpy(&worker, &AubioAnalysisWorker::pitchResult);

    worker.initialize(1, config, sampleRate, 1, QAudioFormat::Int16, 2);
    auto processTone = [&](quint64 activeGeneration, int firstSample, double frequency) {
        QByteArray bytes(hopSize * 2, Qt::Uninitialized);
        for (int i = 0; i < hopSize; ++i) {
            const double seconds = static_cast<double>(firstSample + i) / sampleRate;
            const qint16 sample = static_cast<qint16>(std::sin(2.0 * pi * frequency * seconds) * 16000.0);
            std::memcpy(bytes.data() + i * 2, &sample, sizeof(sample));
        }
        worker.processAudio(activeGeneration, bytes);
    };
    for (int firstSample = 0; firstSample < sampleRate / 2; firstSample += hopSize) {
        processTone(1, firstSample, 392.0);
    }

    generation->store(2, std::memory_order_relaxed);
    worker.resetAnalysis(2, sampleRate / 2);
    pitchSpy.clear();
    for (int firstSample = sampleRate / 2; firstSample < sampleRate; firstSample += hopSize) {
        processTone(2, firstSample, 261.625565);
    }
    worker.drain(2);

    bool detectedC4 = false;
    for (const QList<QVariant> &arguments : pitchSpy) {
        if (!arguments.at(2).toBool()) {
            continue;
        }
        const double frequency = arguments.at(3).toDouble();
        const int midi = static_cast<int>(std::llround(69.0 + 12.0 * std::log2(frequency / 440.0)));
        QCOMPARE(midi, 60);
        detectedC4 = true;
    }
    QVERIFY(detectedC4);
}

void AubioAnalysisWorkerTest::pitchTimestampsCompensateAnalysisLatency()
{
    constexpr int sampleRate = 48000;
    constexpr int hopSize = 512;
    constexpr double pi = 3.14159265358979323846;
    auto generation = std::make_shared<std::atomic<quint64>>(1);
    AubioAnalysisWorker worker(generation);
    AubioAnalysisWorker::Config config;
    config.analysisMode = 0;
    config.pitchMethod = 1;
    config.minimumPitchConfidence = 0.0;
    config.inputGateLevel = 0.0;
    config.requiredStablePitchFrames = 2;
    QSignalSpy pitchSpy(&worker, &AubioAnalysisWorker::pitchResult);

    worker.initialize(1, config, sampleRate, 1, QAudioFormat::Int16, 2);
    for (int firstSample = 0; firstSample < sampleRate * 2; firstSample += hopSize) {
        QByteArray bytes(hopSize * 2, Qt::Uninitialized);
        for (int i = 0; i < hopSize; ++i) {
            const double seconds = static_cast<double>(firstSample + i) / sampleRate;
            double frequency = 0.0;
            if (seconds >= 0.5 && seconds < 1.25) {
                frequency = 261.625565;
            } else if (seconds >= 1.25) {
                frequency = 293.664768;
            }
            const qint16 sample = frequency > 0.0 ? static_cast<qint16>(std::sin(2.0 * pi * frequency * seconds) * 16000.0) : 0;
            std::memcpy(bytes.data() + i * 2, &sample, sizeof(sample));
        }
        worker.processAudio(1, bytes);
    }
    worker.drain(1);

    std::optional<double> c4Seconds;
    std::optional<double> d4Seconds;
    for (const QList<QVariant> &arguments : pitchSpy) {
        if (!arguments.at(2).toBool()) {
            continue;
        }
        const double frequency = arguments.at(3).toDouble();
        const int midi = static_cast<int>(std::llround(69.0 + 12.0 * std::log2(frequency / 440.0)));
        if (midi == 60 && !c4Seconds) {
            c4Seconds = arguments.at(1).toDouble();
        } else if (midi == 62 && !d4Seconds) {
            d4Seconds = arguments.at(1).toDouble();
        }
    }

    QVERIFY(c4Seconds.has_value());
    QVERIFY(d4Seconds.has_value());
    QVERIFY(std::abs(*c4Seconds - 0.5) < 0.15);
    QVERIFY(std::abs(*d4Seconds - 1.25) < 0.15);
}

QTEST_GUILESS_MAIN(AubioAnalysisWorkerTest)

#include "aubioanalysisworkertest.moc"
