// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "clappingexercisecontroller.h"
#include "singingexercisecontroller.h"

#include <QTest>

using namespace Qt::StringLiterals;

class ExerciseEvaluationTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void createsAndScoresClappingQuestion();
    void createsAndScoresSingingQuestion();
    void normalizesSingingOctavesInApplicationLayer();
};

void ExerciseEvaluationTest::createsAndScoresClappingQuestion()
{
    Minuet::ClappingExerciseController controller;
    const QVariantList options{QVariantMap{{u"name"_s, u"Quarter notes"_s}, {u"sequence"_s, u"4 4"_s}}};
    const QVariantMap question = controller.createQuestion(options, 500.0);
    const QVariantList expected = question.value(u"expectedOnsets"_s).toList();
    const QVariantList figures = question.value(u"figureStates"_s).toList();

    QCOMPARE(expected.size(), 2);
    QCOMPARE(controller.totalDurationMs(figures), 1000.0);
    QCOMPARE(controller.score(expected, QVariantList{0.0, 500.0}, 100.0), 100);
    QCOMPARE(controller.score(expected, QVariantList{0.0, 500.0, 750.0}, 100.0), 67);
}

void ExerciseEvaluationTest::createsAndScoresSingingQuestion()
{
    Minuet::SingingExerciseController controller;
    const QVariantMap question = controller.createQuestion(QVariantMap{{u"name"_s, u"Major third"_s},
                                                                        {u"rootNote"_s, 60},
                                                                        {u"sequence"_s, u"4"_s}},
                                                          false);
    QCOMPARE(question.value(u"rootNote"_s).toInt(), 60);
    QCOMPARE(question.value(u"targetNotes"_s).toList(), QVariantList{64});

    QVariantList states = question.value(u"targetStates"_s).toList();
    QVariantMap state = states.first().toMap();
    state[u"pitchCorrect"_s] = true;
    states[0] = state;
    QCOMPARE(controller.score(states, 0), 100);
    QCOMPARE(controller.score(states, 1), 100);
}

void ExerciseEvaluationTest::normalizesSingingOctavesInApplicationLayer()
{
    Minuet::SingingExerciseController controller;
    const QVariantMap question = controller.createQuestion(QVariantMap{{u"rootNote"_s, 60}, {u"sequence"_s, u"4"_s}}, false);
    const QVariantMap evaluation = controller.evaluatePitch(question.value(u"targetStates"_s).toList(),
                                                            question.value(u"targetNotes"_s).toList(),
                                                            1.2,
                                                            76,
                                                            0.0,
                                                            1.0,
                                                            500.0,
                                                            49,
                                                            0.1,
                                                            true,
                                                            false,
                                                            100.0);
    QCOMPARE(evaluation.value(u"meterValue"_s).toDouble(), 1.0);
}

QTEST_MAIN(ExerciseEvaluationTest)

#include "exerciseevaluationtest.moc"
