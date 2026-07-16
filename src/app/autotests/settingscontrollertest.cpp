// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "../settingscontroller.h"

#include <QCoreApplication>
#include <QSettings>
#include <QStandardPaths>
#include <QTest>

using namespace Qt::StringLiterals;

namespace Minuet
{
class SettingsControllerTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase();
    void init();
    void usesRhythmDefault();
    void routesTempoAndSubdivisionsByPlayMode();
    void clampsRhythmTempo();
};

void SettingsControllerTest::initTestCase()
{
    QStandardPaths::setTestModeEnabled(true);
    QCoreApplication::setOrganizationName(u"KDE-Minuet-Autotests"_s);
    QCoreApplication::setApplicationName(u"settingscontrollertest"_s);
}

void SettingsControllerTest::init()
{
    QSettings().clear();
}

void SettingsControllerTest::usesRhythmDefault()
{
    SettingsController controller;
    QCOMPARE(controller.exerciseSpeed(), 60);
    QCOMPARE(controller.rhythmTempo(), 45);
}

void SettingsControllerTest::routesTempoAndSubdivisionsByPlayMode()
{
    SettingsController controller;
    controller.setExerciseSpeed(72);
    controller.setRhythmTempo(54);

    const QVariantMap melodic{{u"playMode"_s, u"note"_s}};
    const QVariantMap manualScale{{u"playMode"_s, u"scale"_s}};
    const QVariantMap rhythm{{u"playMode"_s, u"rhythm"_s}};
    const QVariantMap singingInterval{{u"inputMode"_s, u"singing"_s}, {u"playMode"_s, u"scale"_s}, {u"singingExerciseKind"_s, u"interval"_s}};
    const QVariantMap singingScale{{u"inputMode"_s, u"singing"_s}, {u"playMode"_s, u"scale"_s}, {u"singingExerciseKind"_s, u"scale"_s}};

    QCOMPARE(controller.tempoForExercise(melodic), 72);
    QCOMPARE(controller.subdivisionsForExercise(melodic), 1);
    QCOMPARE(controller.subdivisionsForExercise(manualScale), 1);
    QCOMPARE(controller.tempoForExercise(rhythm), 54);
    QCOMPARE(controller.subdivisionsForExercise(rhythm), 4);
    QCOMPARE(controller.subdivisionsForExercise(singingInterval), 2);
    QCOMPARE(controller.subdivisionsForExercise(singingScale), 2);
}

void SettingsControllerTest::clampsRhythmTempo()
{
    SettingsController controller;
    controller.setRhythmTempo(1);
    QCOMPARE(controller.rhythmTempo(), 30);

    controller.setRhythmTempo(999);
    QCOMPARE(controller.rhythmTempo(), 240);
}
}

QTEST_MAIN(Minuet::SettingsControllerTest)

#include "settingscontrollertest.moc"
