// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "exercisesessioncontroller.h"

#include <utils/rhythmtoken.h>

#include <KLocalizedString>

#include <QDebug>
#include <QJsonObject>
#include <QRandomGenerator>

#include <algorithm>
#include <climits>
#include <cmath>

using namespace Qt::StringLiterals;

namespace Minuet
{
ExerciseSessionController::ExerciseSessionController(QObject *parent)
    : QObject(parent)
{
}

int ExerciseSessionController::currentAnswer() const
{
    return m_currentAnswer;
}

QVariantList ExerciseSessionController::userAnswers() const
{
    return m_userAnswers;
}

bool ExerciseSessionController::answersAreRight() const
{
    return m_answersAreRight;
}

bool ExerciseSessionController::isTest() const
{
    return m_isTest;
}

int ExerciseSessionController::currentExercise() const
{
    return m_currentExercise;
}

bool ExerciseSessionController::showingCorrectAnswers() const
{
    return m_showingCorrectAnswers;
}

int ExerciseSessionController::correctedAnswerPosition() const
{
    return m_correctedAnswerPosition;
}

bool ExerciseSessionController::highlightingSingleAnswer() const
{
    return m_highlightingSingleAnswer;
}

QString ExerciseSessionController::highlightedAnswerName() const
{
    return m_highlightedAnswerName;
}

QString ExerciseSessionController::statusText() const
{
    return m_statusText;
}

ExerciseSessionController::StatusRole ExerciseSessionController::statusRole() const
{
    return m_statusRole;
}

QVariantMap ExerciseSessionController::activeExercise() const
{
    return m_activeExercise;
}

QJsonArray ExerciseSessionController::selectedExerciseOptions() const
{
    return m_selectedExerciseOptions;
}

unsigned int ExerciseSessionController::chosenRootNote() const
{
    return m_chosenRootNote;
}

void ExerciseSessionController::resetForExercise()
{
    clearUserAnswers();
    setStatusText(i18n("Select New Question to start"));
}

void ExerciseSessionController::clearUserAnswers()
{
    m_showingCorrectAnswers = false;
    m_correctedAnswerPosition = -1;
    m_highlightingSingleAnswer = false;
    m_highlightedAnswerName.clear();
    m_currentAnswer = 0;
    m_userAnswers = {};
    emit sessionChanged();
}

QVariantList ExerciseSessionController::availableAnswersModel(const QVariantMap &exercise) const
{
    return exercise.value(u"options"_s).toList();
}

QVariantMap ExerciseSessionController::answerModel(const QVariant &answer) const
{
    const QVariantMap answerMap = answer.toMap();
    const QVariant model = answerMap.value(u"model"_s);
    return model.isValid() ? model.toMap() : answerMap;
}

QString ExerciseSessionController::colorForAnswerIndex(int index, const QVariantList &colors) const
{
    if (index < 0 || colors.isEmpty()) {
        return u"white"_s;
    }
    return colors.at(index % colors.size()).toString();
}

int ExerciseSessionController::answerIndexForName(const QVariantList &answers, const QString &answerName) const
{
    for (int i = 0; i < answers.size(); ++i) {
        if (answerModel(answers.at(i)).value(u"name"_s).toString() == answerName) {
            return i;
        }
    }
    return -1;
}

QString ExerciseSessionController::colorForAnswer(const QVariant &answer, const QVariantList &availableAnswers, const QVariantList &colors) const
{
    const QVariantMap answerMap = answer.toMap();
    const QVariant color = answerMap.value(u"color"_s);
    if (color.isValid()) {
        return color.toString();
    }

    const int index = answerIndexForName(availableAnswers, answerModel(answer).value(u"name"_s).toString());
    return index >= 0 ? colorForAnswerIndex(index, colors) : u"white"_s;
}

QVariantMap ExerciseSessionController::answerPresentation(const QVariantList &answers,
                                                          int rootPitch,
                                                          const QVariantMap &exercise,
                                                          const QVariantList &availableAnswers,
                                                          const QVariantList &colors) const
{
    QVariantMap presentation;
    const bool isRhythm = exercise.value(u"playMode"_s).toString() == u"rhythm"_s;
    presentation[u"isRhythm"_s] = isRhythm;
    if (isRhythm) {
        return presentation;
    }

    QVariantList pianoMarks;
    QVariantList sheetMusicModel;

    QVariantMap rootMark;
    rootMark[u"pitch"_s] = rootPitch;
    rootMark[u"color"_s] = u"white"_s;
    pianoMarks.push_back(rootMark);
    sheetMusicModel.push_back(rootPitch);

    for (const QVariant &answer : answers) {
        const QVariantMap model = answerModel(answer);
        const QString color = colorForAnswer(answer, availableAnswers, colors);
        const QStringList intervals = model.value(u"sequence"_s).toString().split(u' ', Qt::SkipEmptyParts);
        for (const QString &interval : intervals) {
            bool ok = false;
            const int pitch = rootPitch + interval.toInt(&ok);
            if (!ok) {
                continue;
            }

            QVariantMap mark;
            mark[u"pitch"_s] = pitch;
            mark[u"color"_s] = color;
            pianoMarks.push_back(mark);
            sheetMusicModel.push_back(pitch);
        }
    }

    presentation[u"rootPitch"_s] = rootPitch;
    presentation[u"pianoMarks"_s] = pianoMarks;
    presentation[u"sheetMusicModel"_s] = sheetMusicModel;
    return presentation;
}

QVariantMap ExerciseSessionController::submittedAnswerFor(const QVariantMap &option, const QVariantList &availableAnswers, const QVariantList &colors) const
{
    const int index = answerIndexForName(availableAnswers, option.value(u"name"_s).toString());
    QVariantMap answer;
    answer[u"name"_s] = option.value(u"name"_s);
    answer[u"model"_s] = option;
    answer[u"index"_s] = index;
    answer[u"color"_s] = index >= 0 ? colorForAnswerIndex(index, colors) : u"white"_s;
    return answer;
}

QVariantMap ExerciseSessionController::userAnswerFor(const QVariantMap &answer, int index, const QVariantList &colors) const
{
    QVariantMap userAnswer;
    userAnswer[u"name"_s] = answer.value(u"name"_s);
    userAnswer[u"model"_s] = answer;
    userAnswer[u"index"_s] = index;
    userAnswer[u"color"_s] = colorForAnswerIndex(index, colors);
    return userAnswer;
}

int ExerciseSessionController::selectedOptionCount(const QVariantMap &exercise, int rhythmPatternCount) const
{
    if (exercise.isEmpty()) {
        return 0;
    }
    if (exercise.value(u"playMode"_s).toString() == u"rhythm"_s) {
        return rhythmPatternCount;
    }
    return exercise.value(u"numberOfSelectedOptions"_s).toInt();
}

QString ExerciseSessionController::answerInstruction(int count) const
{
    return count == 1 ? i18n("Choose 1 answer") : i18n("Choose %1 answers", count);
}

bool ExerciseSessionController::isWrongSubmittedAnswer(const QVariantList &userAnswers, const QVariantList &correctAnswers, int position) const
{
    if (position < 0 || position >= userAnswers.size() || position >= correctAnswers.size()) {
        return false;
    }
    return userAnswers.at(position).toMap().value(u"name"_s).toString() != correctAnswers.at(position).toMap().value(u"name"_s).toString();
}

bool ExerciseSessionController::answersMatch(const QVariantList &userAnswers, const QVariantList &correctAnswers, int expectedAnswers) const
{
    if (expectedAnswers < 0 || userAnswers.size() < expectedAnswers || correctAnswers.size() < expectedAnswers) {
        return false;
    }

    for (int i = 0; i < expectedAnswers; ++i) {
        if (userAnswers.at(i).toMap().value(u"name"_s).toString() != correctAnswers.at(i).toMap().value(u"name"_s).toString()) {
            return false;
        }
    }
    return true;
}

bool ExerciseSessionController::canShowSubmittedAnswerCorrection(int position,
                                                                 const QVariantMap &exercise,
                                                                 int selectedOptionCount,
                                                                 const QVariantList &correctAnswers) const
{
    return !exercise.isEmpty() && m_currentAnswer >= selectedOptionCount && isWrongSubmittedAnswer(m_userAnswers, correctAnswers, position);
}

void ExerciseSessionController::showSubmittedAnswerCorrection(int position)
{
    m_correctedAnswerPosition = position;
    m_showingCorrectAnswers = true;
    emit sessionChanged();
}

void ExerciseSessionController::restoreSubmittedAnswerCorrection()
{
    m_correctedAnswerPosition = -1;
    m_showingCorrectAnswers = false;
    emit sessionChanged();
}

void ExerciseSessionController::toggleSubmittedAnswerCorrection(int position,
                                                                const QVariantMap &exercise,
                                                                int selectedOptionCount,
                                                                const QVariantList &correctAnswers)
{
    if (!canShowSubmittedAnswerCorrection(position, exercise, selectedOptionCount, correctAnswers)) {
        return;
    }
    if (m_correctedAnswerPosition == position) {
        restoreSubmittedAnswerCorrection();
    } else {
        showSubmittedAnswerCorrection(position);
    }
}

bool ExerciseSessionController::chooseAnswer(const QVariantMap &answer, int index, int selectedOptionCount, const QVariantList &colors)
{
    if (m_currentAnswer >= selectedOptionCount) {
        return false;
    }

    m_userAnswers.push_back(userAnswerFor(answer, index, colors));
    ++m_currentAnswer;
    emit sessionChanged();
    return m_currentAnswer == selectedOptionCount;
}

bool ExerciseSessionController::canEditUserAnswers(const QString &viewState, int selectedOptionCount, bool animationRunning) const
{
    return viewState == u"waitingForAnswer"_s && m_currentAnswer > 0 && m_currentAnswer < selectedOptionCount && !animationRunning;
}

bool ExerciseSessionController::removeUserAnswerAt(int position)
{
    if (position < 0 || position >= m_userAnswers.size()) {
        return false;
    }

    m_userAnswers.removeAt(position);
    --m_currentAnswer;
    emit sessionChanged();
    return true;
}

bool ExerciseSessionController::removeLastUserAnswer()
{
    return removeUserAnswerAt(static_cast<int>(m_userAnswers.size() - 1));
}

void ExerciseSessionController::checkAnswers(const QVariantList &correctAnswers, int expectedAnswers, int maximumExercises)
{
    m_answersAreRight = answersMatch(m_userAnswers, correctAnswers, expectedAnswers);
    for (int i = 0; i < expectedAnswers && i < m_userAnswers.size() && i < correctAnswers.size(); ++i) {
        if (m_userAnswers.at(i).toMap().value(u"name"_s).toString() == correctAnswers.at(i).toMap().value(u"name"_s).toString() && m_isTest) {
            ++m_correctAnswers;
        }
    }

    if (m_giveUp) {
        setStatusText(i18n("Answer shown"));
    } else if (m_answersAreRight) {
        setStatusText(i18n("That's right"), PositiveStatus);
    } else {
        setStatusText(i18n("Not quite"), NegativeStatus);
    }

    if (m_currentExercise == maximumExercises) {
        setStatusText(i18n("Score: %1%", m_correctAnswers * 100 / maximumExercises / expectedAnswers));
        resetTest();
    }

    m_giveUp = false;
    emit sessionChanged();
}

void ExerciseSessionController::resetTest()
{
    m_isTest = false;
    m_correctAnswers = 0;
    m_accumulatedTestScore = 0;
    m_currentExercise = 0;
    emit sessionChanged();
}

int ExerciseSessionController::recordTestScore(int score, int maximumExercises)
{
    if (!m_isTest || maximumExercises <= 0) {
        return -1;
    }
    m_accumulatedTestScore += std::max(0, score);
    if (m_currentExercise < maximumExercises) {
        return -1;
    }
    const int finalScore = qRound(m_accumulatedTestScore / static_cast<double>(maximumExercises));
    resetTest();
    return finalScore;
}

void ExerciseSessionController::startTest()
{
    resetTest();
    m_isTest = true;
    emit sessionChanged();
}

void ExerciseSessionController::stopTest()
{
    resetTest();
    setStatusText(i18n("Select New Question to start"));
}

void ExerciseSessionController::setActiveExercise(const QVariantMap &activeExercise)
{
    if (m_activeExercise == activeExercise) {
        return;
    }

    m_activeExercise = activeExercise;
    m_selectedExerciseOptions = {};
    m_chosenRootNote = 0;
    emit activeExerciseChanged(m_activeExercise);
    emit selectedExerciseOptionsChanged(m_selectedExerciseOptions);
}

void ExerciseSessionController::randomlySelectExerciseOptions(int selectedOptionCount)
{
    while (!m_selectedExerciseOptions.isEmpty()) {
        m_selectedExerciseOptions.removeFirst();
    }
    m_chosenRootNote = 0;

    auto failSelection = [this](const QString &errorString) {
        m_selectedExerciseOptions = QJsonArray();
        m_errorString = errorString;
        qWarning() << m_errorString;
        emit selectedExerciseOptionsChanged(m_selectedExerciseOptions);
    };

    auto *generator = QRandomGenerator::global();
    const QJsonObject activeExerciseObject = QJsonObject::fromVariantMap(m_activeExercise);
    const QString playMode = activeExerciseObject[u"playMode"_s].toString();
    const bool isRhythm = playMode == u"rhythm"_s;
    const int targetPitchMin = activeExerciseObject[u"targetPitchMin"_s].isDouble() ? activeExerciseObject[u"targetPitchMin"_s].toInt() : 21;
    const int targetPitchMax = activeExerciseObject[u"targetPitchMax"_s].isDouble() ? activeExerciseObject[u"targetPitchMax"_s].toInt() : 108;
    const int numberOfSelectedOptions = selectedOptionCount > 0 ? selectedOptionCount : activeExerciseObject[u"numberOfSelectedOptions"_s].toInt();
    if (numberOfSelectedOptions <= 0) {
        failSelection(u"Current exercise has no selected options count."_s);
        return;
    }

    const QJsonArray exerciseOptions = activeExerciseObject[u"options"_s].toArray();
    if (exerciseOptions.isEmpty()) {
        failSelection(u"Current exercise has no options."_s);
        return;
    }
    if (!isRhythm && numberOfSelectedOptions > exerciseOptions.size()) {
        failSelection(u"Current exercise selects more options than it provides."_s);
        return;
    }

    int exerciseMinRoot = 0;
    int exerciseMaxRoot = 0;
    if (!isRhythm) {
        const QStringList exerciseRoots = activeExerciseObject[u"root"_s].toString().split(u".."_s);
        if (exerciseRoots.size() != 2) {
            failSelection(u"Current exercise has an invalid root range."_s);
            return;
        }

        bool minRootOk = false;
        bool maxRootOk = false;
        exerciseMinRoot = exerciseRoots.first().toInt(&minRootOk);
        exerciseMaxRoot = exerciseRoots.last().toInt(&maxRootOk);
        if (!minRootOk || !maxRootOk || exerciseMaxRoot <= exerciseMinRoot) {
            failSelection(u"Current exercise has an invalid root range."_s);
            return;
        }
    }

    auto optionNoteRange = [isRhythm, &failSelection](const QJsonObject &optionObject, int &minNote, int &maxNote) {
        minNote = INT_MAX;
        maxNote = INT_MIN;

        const QString sequence = optionObject[u"sequence"_s].toString();
        const QStringList additionalNotes = sequence.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (additionalNotes.isEmpty()) {
            failSelection(u"Current exercise option has an empty sequence."_s);
            return false;
        }

        for (const QString &additionalNote : additionalNotes) {
            if (isRhythm) {
                const RhythmToken rhythmToken = parseRhythmToken(additionalNote);
                if (!rhythmToken.valid) {
                    failSelection(u"Current exercise option has an invalid sequence."_s);
                    return false;
                }
                if (rhythmToken.denominator > maxNote) {
                    maxNote = rhythmToken.denominator;
                }
                if (rhythmToken.denominator < minNote) {
                    minNote = rhythmToken.denominator;
                }
                continue;
            }

            bool ok = false;
            const int note = additionalNote.toInt(&ok);
            if (!ok) {
                failSelection(u"Current exercise option has an invalid sequence."_s);
                return false;
            }
            if (note > maxNote) {
                maxNote = note;
            }
            if (note < minNote) {
                minNote = note;
            }
        }
        return true;
    };

    auto rootRangeForOption = [&](const QJsonObject &optionObject, int &minAllowedRoot, int &maxAllowedRoot) {
        int minNote = 0;
        int maxNote = 0;
        if (!optionNoteRange(optionObject, minNote, maxNote)) {
            return false;
        }
        if (isRhythm) {
            minAllowedRoot = 0;
            maxAllowedRoot = 0;
            return true;
        }

        minAllowedRoot = (std::max)((std::max)(exerciseMinRoot, targetPitchMin), targetPitchMin - minNote);
        maxAllowedRoot = (std::min)((std::min)(exerciseMaxRoot - 1, targetPitchMax), targetPitchMax - maxNote);
        return maxAllowedRoot >= minAllowedRoot;
    };

    QJsonArray remainingExerciseOptions = exerciseOptions;
    for (int i = 0; i < numberOfSelectedOptions; ++i) {
        const QJsonArray &candidateExerciseOptions = isRhythm ? exerciseOptions : remainingExerciseOptions;
        QJsonArray selectableExerciseOptions;
        for (const QJsonValue &candidateExerciseOption : candidateExerciseOptions) {
            if (!candidateExerciseOption.isObject()) {
                failSelection(u"Current exercise option is not an object."_s);
                return;
            }
            int minAllowedRoot = 0;
            int maxAllowedRoot = 0;
            if (rootRangeForOption(candidateExerciseOption.toObject(), minAllowedRoot, maxAllowedRoot)) {
                selectableExerciseOptions.append(candidateExerciseOption);
            }
        }
        if (selectableExerciseOptions.isEmpty()) {
            failSelection(u"Current exercise has no options that fit the selected pitch range."_s);
            return;
        }

        const int chosenExerciseOption = static_cast<int>(generator->bounded(selectableExerciseOptions.size()));
        if (!selectableExerciseOptions[chosenExerciseOption].isObject()) {
            failSelection(u"Current exercise option is not an object."_s);
            return;
        }

        const QJsonObject optionObject = selectableExerciseOptions[chosenExerciseOption].toObject();
        int minAllowedRoot = 0;
        int maxAllowedRoot = 0;
        if (!rootRangeForOption(optionObject, minAllowedRoot, maxAllowedRoot)) {
            failSelection(u"Current exercise root range cannot fit the sequence."_s);
            return;
        }
        if (!isRhythm) {
            for (qsizetype optionIndex = 0; optionIndex < remainingExerciseOptions.size(); ++optionIndex) {
                if (remainingExerciseOptions[optionIndex].toObject() == optionObject) {
                    remainingExerciseOptions.removeAt(optionIndex);
                    break;
                }
            }
            m_chosenRootNote = minAllowedRoot + generator->bounded(maxAllowedRoot - minAllowedRoot + 1);
        }

        QJsonObject jsonObject = optionObject;
        jsonObject[u"rootNote"_s] = QString::number(m_chosenRootNote);
        m_selectedExerciseOptions.append(jsonObject);
    }
    m_errorString.clear();
    emit selectedExerciseOptionsChanged(m_selectedExerciseOptions);
}

void ExerciseSessionController::giveUpWithCorrectAnswers(const QVariantList &correctAnswers,
                                                         const QVariantList &availableAnswers,
                                                         const QVariantList &colors,
                                                         int expectedAnswers)
{
    if (m_isTest) {
        --m_correctAnswers;
    }
    m_giveUp = true;
    QVariantList userAnswers;
    userAnswers.reserve(expectedAnswers);
    for (int i = 0; i < expectedAnswers && i < correctAnswers.size(); ++i) {
        userAnswers.push_back(submittedAnswerFor(correctAnswers.at(i).toMap(), availableAnswers, colors));
    }
    m_userAnswers = userAnswers;
    m_currentAnswer = expectedAnswers;
    emit sessionChanged();
}

void ExerciseSessionController::beginQuestion(int maximumExercises)
{
    clearUserAnswers();
    setStatusText(m_isTest ? i18n("Question %1 out of %2", m_currentExercise + 1, maximumExercises) : QString());
}

void ExerciseSessionController::finishQuestionGeneration()
{
    if (m_isTest) {
        ++m_currentExercise;
        emit sessionChanged();
    }
}

void ExerciseSessionController::setSingleAnswerHighlight(const QString &answerName)
{
    m_highlightingSingleAnswer = true;
    m_highlightedAnswerName = answerName;
    emit sessionChanged();
}

void ExerciseSessionController::clearSingleAnswerHighlight()
{
    m_highlightingSingleAnswer = false;
    m_highlightedAnswerName.clear();
    emit sessionChanged();
}

void ExerciseSessionController::setStatusText(const QString &statusText, StatusRole statusRole)
{
    m_statusText = statusText;
    m_statusRole = statusRole;
    emit sessionChanged();
}
}
