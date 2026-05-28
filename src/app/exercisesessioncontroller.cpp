// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "exercisesessioncontroller.h"

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

bool ExerciseSessionController::giveUp() const
{
    return m_giveUp;
}

bool ExerciseSessionController::isTest() const
{
    return m_isTest;
}

int ExerciseSessionController::correctAnswers() const
{
    return m_correctAnswers;
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

QString ExerciseSessionController::errorString() const
{
    return m_errorString;
}

void ExerciseSessionController::resetForExercise()
{
    clearUserAnswers();
    setStatusText(i18n("Click 'New Question' to start!"));
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
    return !exercise.isEmpty()
        && m_currentAnswer >= selectedOptionCount
        && isWrongSubmittedAnswer(m_userAnswers, correctAnswers, position);
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
    return viewState == u"waitingForAnswer"_s
        && m_currentAnswer > 0
        && m_currentAnswer < selectedOptionCount
        && !animationRunning;
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
    return removeUserAnswerAt(m_userAnswers.size() - 1);
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
        setStatusText(i18n("Here is the answer"));
    } else if (m_answersAreRight) {
        setStatusText(i18n("Congratulations, you answered correctly!"));
    } else {
        setStatusText(i18n("Oops, not this time! Try again!"));
    }

    if (m_currentExercise == maximumExercises) {
        setStatusText(i18n("You answered correctly %1%", m_correctAnswers * 100 / maximumExercises / expectedAnswers));
        resetTest();
    }

    m_giveUp = false;
    emit sessionChanged();
}

void ExerciseSessionController::resetTest()
{
    m_isTest = false;
    m_correctAnswers = 0;
    m_currentExercise = 0;
    emit sessionChanged();
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
    setStatusText(i18n("Click 'New Question' to start"));
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

    int minNote = INT_MAX;
    int maxNote = INT_MIN;
    auto *generator = QRandomGenerator::global();
    const QJsonObject activeExerciseObject = QJsonObject::fromVariantMap(m_activeExercise);
    const QString playMode = activeExerciseObject[u"playMode"_s].toString();
    const int numberOfSelectedOptions = selectedOptionCount > 0
        ? selectedOptionCount
        : activeExerciseObject[u"numberOfSelectedOptions"_s].toInt();
    if (numberOfSelectedOptions <= 0) {
        failSelection(u"Current exercise has no selected options count."_s);
        return;
    }

    const QJsonArray exerciseOptions = activeExerciseObject[u"options"_s].toArray();
    if (exerciseOptions.isEmpty()) {
        failSelection(u"Current exercise has no options."_s);
        return;
    }
    if (playMode != u"rhythm"_s && numberOfSelectedOptions > exerciseOptions.size()) {
        failSelection(u"Current exercise selects more options than it provides."_s);
        return;
    }

    QJsonArray remainingExerciseOptions = exerciseOptions;
    for (int i = 0; i < numberOfSelectedOptions; ++i) {
        const QJsonArray &selectableExerciseOptions = playMode == u"rhythm"_s ? exerciseOptions : remainingExerciseOptions;
        const int chosenExerciseOption = generator->bounded(selectableExerciseOptions.size());
        if (!selectableExerciseOptions[chosenExerciseOption].isObject()) {
            failSelection(u"Current exercise option is not an object."_s);
            return;
        }

        const QJsonObject optionObject = selectableExerciseOptions[chosenExerciseOption].toObject();
        if (playMode != u"rhythm"_s) {
            remainingExerciseOptions.removeAt(chosenExerciseOption);
        }
        const QString sequence = optionObject[u"sequence"_s].toString();
        const QStringList additionalNotes = sequence.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (additionalNotes.isEmpty()) {
            failSelection(u"Current exercise option has an empty sequence."_s);
            return;
        }

        for (const QString &additionalNote : additionalNotes) {
            QString noteText = additionalNote;
            if (playMode == u"rhythm"_s && noteText.endsWith(QLatin1Char('.'))) {
                noteText.chop(1);
            }

            bool ok = false;
            const int note = noteText.toInt(&ok);
            if (!ok || (playMode == u"rhythm"_s && note <= 0)) {
                failSelection(u"Current exercise option has an invalid sequence."_s);
                return;
            }
            if (note > maxNote) {
                maxNote = note;
            }
            if (note < minNote) {
                minNote = note;
            }
        }
        if (playMode != u"rhythm"_s) {
            const QStringList exerciseRoots = activeExerciseObject[u"root"_s].toString().split(u".."_s);
            if (exerciseRoots.size() != 2) {
                failSelection(u"Current exercise has an invalid root range."_s);
                return;
            }

            bool minRootOk = false;
            bool maxRootOk = false;
            const int exerciseMinRoot = exerciseRoots.first().toInt(&minRootOk);
            const int exerciseMaxRoot = exerciseRoots.last().toInt(&maxRootOk);
            if (!minRootOk || !maxRootOk || exerciseMaxRoot <= exerciseMinRoot) {
                failSelection(u"Current exercise has an invalid root range."_s);
                return;
            }

            const int minAllowedRoot = (std::max)(exerciseMinRoot, 21 - minNote);
            const int maxAllowedRoot = (std::min)(exerciseMaxRoot - 1, 108 - maxNote);
            if (maxAllowedRoot < minAllowedRoot) {
                failSelection(u"Current exercise root range cannot fit the sequence."_s);
                return;
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

void ExerciseSessionController::setStatusText(const QString &statusText)
{
    m_statusText = statusText;
    emit sessionChanged();
}
}
