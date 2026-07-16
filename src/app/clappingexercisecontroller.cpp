// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "clappingexercisecontroller.h"

#include <utils/rhythmtoken.h>

#include <KLocalizedString>

#include <algorithm>
#include <cmath>
#include <limits>

using namespace Qt::StringLiterals;

namespace Minuet
{
ClappingExerciseController::ClappingExerciseController(QObject *parent)
    : QObject(parent)
{
}

QVariantMap ClappingExerciseController::createQuestion(const QVariantList &selectedOptions, double beatMs) const
{
    QVariantList expectedOnsets;
    QVariantList figureStates;
    double cursor = 0.0;

    for (int figureIndex = 0; figureIndex < selectedOptions.size(); ++figureIndex) {
        const QVariantMap option = selectedOptions.at(figureIndex).toMap();
        const QStringList parts = option.value(u"sequence"_s).toString().split(u' ', Qt::SkipEmptyParts);
        QVariantList figureOnsets;
        const double figureStart = cursor;

        for (const QString &part : parts) {
            const RhythmToken token = parseRhythmToken(part);
            if (!token.valid) {
                continue;
            }
            if (!token.rest) {
                figureOnsets.append(expectedOnsets.size());
                expectedOnsets.append(QVariantMap{{u"figure"_s, figureIndex}, {u"timeMs"_s, cursor}});
            }
            cursor += token.quarterNoteBeats() * beatMs;
        }

        figureStates.append(QVariantMap{{u"state"_s, u"pending"_s},
                                        {u"onsets"_s, figureOnsets},
                                        {u"startMs"_s, figureStart},
                                        {u"endMs"_s, cursor},
                                        {u"extraInputCount"_s, 0},
                                        {u"name"_s, option.value(u"name"_s)},
                                        {u"meterValue"_s, 0.0},
                                        {u"meterAccuracy"_s, 0.0},
                                        {u"meterText"_s, i18n("Ready")}});
    }

    return {{u"expectedOnsets"_s, expectedOnsets}, {u"figureStates"_s, figureStates}, {u"totalDurationMs"_s, cursor}};
}

QVariantMap ClappingExerciseController::alignment(const QVariantList &expectedOnsets,
                                                  const QVariantList &performedOnsets,
                                                  double toleranceMs) const
{
    struct Cell {
        double cost = std::numeric_limits<double>::max();
        enum Operation { None, Match, Missing, Extra } operation = None;
    };

    constexpr double missingCost = 2.0;
    constexpr double extraCost = 2.0;
    const int expectedCount = expectedOnsets.size();
    const int performedCount = performedOnsets.size();
    const double safeTolerance = std::max(1.0, toleranceMs);
    QVector<QVector<Cell>> dp(expectedCount + 1, QVector<Cell>(performedCount + 1));
    dp[0][0].cost = 0.0;
    for (int i = 1; i <= expectedCount; ++i) {
        dp[i][0] = {i * missingCost, Cell::Missing};
    }
    for (int j = 1; j <= performedCount; ++j) {
        dp[0][j] = {j * extraCost, Cell::Extra};
    }

    for (int i = 1; i <= expectedCount; ++i) {
        for (int j = 1; j <= performedCount; ++j) {
            Cell best{dp[i - 1][j].cost + missingCost, Cell::Missing};
            const double extra = dp[i][j - 1].cost + extraCost;
            if (extra < best.cost) {
                best = {extra, Cell::Extra};
            }
            const double error = std::abs(expectedOnsets.at(i - 1).toMap().value(u"timeMs"_s).toDouble() - performedOnsets.at(j - 1).toDouble());
            if (error <= safeTolerance) {
                const double match = dp[i - 1][j - 1].cost + error / safeTolerance;
                if (match <= best.cost) {
                    best = {match, Cell::Match};
                }
            }
            dp[i][j] = best;
        }
    }

    QVariantList expectedMatches(expectedCount, -1);
    QVariantList performedMatches(performedCount, -1);
    int i = expectedCount;
    int j = performedCount;
    while (i > 0 || j > 0) {
        switch (dp[i][j].operation) {
        case Cell::Match:
            expectedMatches[i - 1] = j - 1;
            performedMatches[j - 1] = i - 1;
            --i;
            --j;
            break;
        case Cell::Missing:
            --i;
            break;
        case Cell::Extra:
            --j;
            break;
        case Cell::None:
            i = 0;
            j = 0;
            break;
        }
    }
    return {{u"expectedMatches"_s, expectedMatches}, {u"performedMatches"_s, performedMatches}};
}

QVariantMap ClappingExerciseController::evaluate(const QVariantList &expectedOnsets,
                                                 const QVariantList &figureStates,
                                                 const QVariantList &performedOnsets,
                                                 double elapsedMs,
                                                 double toleranceMs) const
{
    const QVariantMap matches = alignment(expectedOnsets, performedOnsets, toleranceMs);
    const QVariantList expectedMatches = matches.value(u"expectedMatches"_s).toList();
    const QVariantList performedMatches = matches.value(u"performedMatches"_s).toList();
    QVariantList states;
    QVariantList worstErrors;
    for (const QVariant &stateValue : figureStates) {
        const QVariantMap state = stateValue.toMap();
        states.append(QVariantMap{{u"state"_s, u"pending"_s},
                                  {u"onsets"_s, state.value(u"onsets"_s)},
                                  {u"startMs"_s, state.value(u"startMs"_s)},
                                  {u"endMs"_s, state.value(u"endMs"_s)},
                                  {u"extraInputCount"_s, 0},
                                  {u"name"_s, state.value(u"name"_s)},
                                  {u"meterValue"_s, 0.0},
                                  {u"meterAccuracy"_s, 0.0},
                                  {u"meterText"_s, i18n("Ready")}});
        worstErrors.append(QVariant());
    }

    for (int expectedIndex = 0; expectedIndex < expectedMatches.size(); ++expectedIndex) {
        const int performedIndex = expectedMatches.at(expectedIndex).toInt();
        if (performedIndex < 0) {
            continue;
        }
        const int figureIndex = expectedOnsets.at(expectedIndex).toMap().value(u"figure"_s).toInt();
        const double error = performedOnsets.at(performedIndex).toDouble() - expectedOnsets.at(expectedIndex).toMap().value(u"timeMs"_s).toDouble();
        if (!worstErrors.at(figureIndex).isValid() || std::abs(error) > std::abs(worstErrors.at(figureIndex).toDouble())) {
            worstErrors[figureIndex] = error;
        }
    }

    for (int performedIndex = 0; performedIndex < performedMatches.size(); ++performedIndex) {
        if (performedMatches.at(performedIndex).toInt() >= 0) {
            continue;
        }
        const double onset = performedOnsets.at(performedIndex).toDouble();
        const int figureIndex = figureIndexForElapsed(figureStates, onset, toleranceMs);
        if (figureIndex < 0) {
            continue;
        }
        QVariantMap state = states.at(figureIndex).toMap();
        state[u"extraInputCount"_s] = state.value(u"extraInputCount"_s).toInt() + 1;
        state[u"state"_s] = u"wrong"_s;
        const QVariantList onsetIndexes = state.value(u"onsets"_s).toList();
        double error = onset - state.value(u"startMs"_s).toDouble();
        for (const QVariant &onsetIndexValue : onsetIndexes) {
            const double candidate = onset - expectedOnsets.at(onsetIndexValue.toInt()).toMap().value(u"timeMs"_s).toDouble();
            if (std::abs(candidate) < std::abs(error)) {
                error = candidate;
            }
        }
        state[u"meterValue"_s] = timingValue(error, toleranceMs);
        state[u"meterAccuracy"_s] = std::max(0.0, 1.0 - std::abs(error) / std::max(1.0, toleranceMs));
        state[u"meterText"_s] = timingText(error);
        states[figureIndex] = state;
    }

    for (int stateIndex = 0; stateIndex < states.size(); ++stateIndex) {
        QVariantMap state = states.at(stateIndex).toMap();
        if (state.value(u"state"_s).toString() == u"wrong"_s) {
            continue;
        }
        bool allMatched = true;
        bool missed = false;
        const QVariantList onsetIndexes = state.value(u"onsets"_s).toList();
        for (const QVariant &onsetIndexValue : onsetIndexes) {
            const int onsetIndex = onsetIndexValue.toInt();
            if (expectedMatches.at(onsetIndex).toInt() >= 0) {
                continue;
            }
            allMatched = false;
            if (elapsedMs > expectedOnsets.at(onsetIndex).toMap().value(u"timeMs"_s).toDouble() + toleranceMs) {
                missed = true;
            }
        }
        if (worstErrors.at(stateIndex).isValid()) {
            const double error = worstErrors.at(stateIndex).toDouble();
            state[u"meterValue"_s] = timingValue(error, toleranceMs);
            state[u"meterAccuracy"_s] = std::max(0.0, 1.0 - std::abs(error) / std::max(1.0, toleranceMs));
            state[u"meterText"_s] = timingText(error);
        }
        if (missed || (elapsedMs > state.value(u"endMs"_s).toDouble() + toleranceMs && !allMatched)) {
            state[u"state"_s] = u"wrong"_s;
            if (!worstErrors.at(stateIndex).isValid()) {
                state[u"meterText"_s] = i18n("Missed");
                state[u"meterAccuracy"_s] = 0.0;
                state[u"meterValue"_s] = 0.0;
            }
        } else if (allMatched && elapsedMs > state.value(u"endMs"_s).toDouble() + toleranceMs) {
            state[u"state"_s] = u"correct"_s;
        }
        states[stateIndex] = state;
    }

    return {{u"figureStates"_s, states}, {u"score"_s, score(expectedOnsets, performedOnsets, toleranceMs)}};
}

QVariantList ClappingExerciseController::addPerformedOnset(const QVariantList &performedOnsets, double elapsedMs) const
{
    QVariantList result = performedOnsets;
    result.append(elapsedMs);
    std::sort(result.begin(), result.end(), [](const QVariant &left, const QVariant &right) {
        return left.toDouble() < right.toDouble();
    });
    return result;
}

int ClappingExerciseController::figureIndexForElapsed(const QVariantList &figureStates, double elapsedMs, double toleranceMs) const
{
    if (elapsedMs < -toleranceMs || elapsedMs > totalDurationMs(figureStates) + toleranceMs) {
        return -1;
    }
    int closestIndex = -1;
    double closestDistance = std::numeric_limits<double>::max();
    for (int index = 0; index < figureStates.size(); ++index) {
        const QVariantMap state = figureStates.at(index).toMap();
        const double start = state.value(u"startMs"_s).toDouble();
        const double end = state.value(u"endMs"_s).toDouble();
        if (elapsedMs >= start && elapsedMs < end) {
            return index;
        }
        const double distance = std::min(std::abs(elapsedMs - start), std::abs(elapsedMs - end));
        if (distance <= toleranceMs && distance < closestDistance) {
            closestDistance = distance;
            closestIndex = index;
        }
    }
    return closestIndex;
}

int ClappingExerciseController::timelineIndex(const QVariantList &figureStates, double elapsedMs, double toleranceMs) const
{
    if (figureStates.isEmpty()) {
        return -1;
    }
    const int index = figureIndexForElapsed(figureStates, std::max(0.0, elapsedMs), toleranceMs);
    return index >= 0 ? index : figureStates.size() - 1;
}

double ClappingExerciseController::totalDurationMs(const QVariantList &figureStates) const
{
    return figureStates.isEmpty() ? 0.0 : figureStates.constLast().toMap().value(u"endMs"_s).toDouble();
}

int ClappingExerciseController::score(const QVariantList &expectedOnsets, const QVariantList &performedOnsets, double toleranceMs) const
{
    const QVariantMap matches = alignment(expectedOnsets, performedOnsets, toleranceMs);
    const QVariantList expectedMatches = matches.value(u"expectedMatches"_s).toList();
    const QVariantList performedMatches = matches.value(u"performedMatches"_s).toList();
    const int matched = std::count_if(expectedMatches.cbegin(), expectedMatches.cend(), [](const QVariant &value) {
        return value.toInt() >= 0;
    });
    const int extras = std::count_if(performedMatches.cbegin(), performedMatches.cend(), [](const QVariant &value) {
        return value.toInt() < 0;
    });
    const int scoredOnsets = expectedOnsets.size() + extras;
    return scoredOnsets > 0 ? qRound(matched * 100.0 / scoredOnsets) : 0;
}

QString ClappingExerciseController::timingText(double errorMs) const
{
    return std::abs(errorMs) < 1.0 ? i18n("On time") : i18n("%1 ms", qRound(errorMs));
}

double ClappingExerciseController::timingValue(double errorMs, double toleranceMs) const
{
    return -std::clamp(errorMs / std::max(1.0, toleranceMs), -1.0, 1.0);
}
}
