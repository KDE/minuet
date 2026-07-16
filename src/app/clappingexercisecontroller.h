// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_CLAPPINGEXERCISECONTROLLER_H
#define MINUET_CLAPPINGEXERCISECONTROLLER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace Minuet
{
class ClappingExerciseController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("ClappingExerciseController is provided by Core")

public:
    explicit ClappingExerciseController(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap createQuestion(const QVariantList &selectedOptions, double beatMs) const;
    Q_INVOKABLE QVariantMap evaluate(const QVariantList &expectedOnsets,
                                     const QVariantList &figureStates,
                                     const QVariantList &performedOnsets,
                                     double elapsedMs,
                                     double toleranceMs) const;
    Q_INVOKABLE QVariantList addPerformedOnset(const QVariantList &performedOnsets, double elapsedMs) const;
    Q_INVOKABLE int figureIndexForElapsed(const QVariantList &figureStates, double elapsedMs, double toleranceMs) const;
    Q_INVOKABLE int timelineIndex(const QVariantList &figureStates, double elapsedMs, double toleranceMs) const;
    Q_INVOKABLE double totalDurationMs(const QVariantList &figureStates) const;
    Q_INVOKABLE int score(const QVariantList &expectedOnsets, const QVariantList &performedOnsets, double toleranceMs) const;

private:
    QVariantMap alignment(const QVariantList &expectedOnsets, const QVariantList &performedOnsets, double toleranceMs) const;
    QString timingText(double errorMs) const;
    double timingValue(double errorMs, double toleranceMs) const;
};
}

#endif
