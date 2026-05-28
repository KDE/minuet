/****************************************************************************
**
** Copyright (C) 2026 by Sandro S. Andrade <sandroandrade@kde.org>
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation; either version 2 of
** the License or (at your option) version 3 or any later version
** accepted by the membership of KDE e.V. (or its successor approved
** by the membership of KDE e.V.), which shall act as a proxy
** defined in Section 14 of version 3 of the license.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

#ifndef MINUET_EXERCISESESSIONCONTROLLER_H
#define MINUET_EXERCISESESSIONCONTROLLER_H

#include <QObject>
#include <QJsonArray>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace Minuet
{
class ExerciseSessionController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("ExerciseSessionController is provided by Core")
    Q_PROPERTY(int currentAnswer READ currentAnswer NOTIFY sessionChanged)
    Q_PROPERTY(QVariantList userAnswers READ userAnswers NOTIFY sessionChanged)
    Q_PROPERTY(bool answersAreRight READ answersAreRight NOTIFY sessionChanged)
    Q_PROPERTY(bool giveUp READ giveUp NOTIFY sessionChanged)
    Q_PROPERTY(bool isTest READ isTest NOTIFY sessionChanged)
    Q_PROPERTY(int correctAnswers READ correctAnswers NOTIFY sessionChanged)
    Q_PROPERTY(int currentExercise READ currentExercise NOTIFY sessionChanged)
    Q_PROPERTY(bool showingCorrectAnswers READ showingCorrectAnswers NOTIFY sessionChanged)
    Q_PROPERTY(int correctedAnswerPosition READ correctedAnswerPosition NOTIFY sessionChanged)
    Q_PROPERTY(bool highlightingSingleAnswer READ highlightingSingleAnswer NOTIFY sessionChanged)
    Q_PROPERTY(QString highlightedAnswerName READ highlightedAnswerName NOTIFY sessionChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY sessionChanged)
    Q_PROPERTY(QVariantMap activeExercise READ activeExercise WRITE setActiveExercise NOTIFY activeExerciseChanged)
    Q_PROPERTY(QJsonArray selectedExerciseOptions READ selectedExerciseOptions NOTIFY selectedExerciseOptionsChanged)
    Q_PROPERTY(unsigned int chosenRootNote READ chosenRootNote NOTIFY selectedExerciseOptionsChanged)

public:
    int currentAnswer() const;
    QVariantList userAnswers() const;
    bool answersAreRight() const;
    bool giveUp() const;
    bool isTest() const;
    int correctAnswers() const;
    int currentExercise() const;
    bool showingCorrectAnswers() const;
    int correctedAnswerPosition() const;
    bool highlightingSingleAnswer() const;
    QString highlightedAnswerName() const;
    QString statusText() const;
    QVariantMap activeExercise() const;
    QJsonArray selectedExerciseOptions() const;
    unsigned int chosenRootNote() const;

    Q_INVOKABLE QString errorString() const;
    Q_INVOKABLE void resetForExercise();
    Q_INVOKABLE void clearUserAnswers();
    Q_INVOKABLE QVariantList availableAnswersModel(const QVariantMap &exercise) const;
    Q_INVOKABLE QVariantMap answerModel(const QVariant &answer) const;
    Q_INVOKABLE QString colorForAnswerIndex(int index, const QVariantList &colors) const;
    Q_INVOKABLE int answerIndexForName(const QVariantList &answers, const QString &answerName) const;
    Q_INVOKABLE QString colorForAnswer(const QVariant &answer, const QVariantList &availableAnswers, const QVariantList &colors) const;
    Q_INVOKABLE QVariantMap answerPresentation(const QVariantList &answers,
                                               int rootPitch,
                                               const QVariantMap &exercise,
                                               const QVariantList &availableAnswers,
                                               const QVariantList &colors) const;
    Q_INVOKABLE QVariantMap submittedAnswerFor(const QVariantMap &option, const QVariantList &availableAnswers, const QVariantList &colors) const;
    Q_INVOKABLE QVariantMap userAnswerFor(const QVariantMap &answer, int index, const QVariantList &colors) const;
    Q_INVOKABLE int selectedOptionCount(const QVariantMap &exercise, int rhythmPatternCount) const;
    Q_INVOKABLE QString answerInstruction(int count) const;
    Q_INVOKABLE bool isWrongSubmittedAnswer(const QVariantList &userAnswers, const QVariantList &correctAnswers, int position) const;
    Q_INVOKABLE bool answersMatch(const QVariantList &userAnswers, const QVariantList &correctAnswers, int expectedAnswers) const;
    Q_INVOKABLE bool canShowSubmittedAnswerCorrection(int position, const QVariantMap &exercise, int selectedOptionCount, const QVariantList &correctAnswers) const;
    Q_INVOKABLE void showSubmittedAnswerCorrection(int position);
    Q_INVOKABLE void restoreSubmittedAnswerCorrection();
    Q_INVOKABLE void toggleSubmittedAnswerCorrection(int position, const QVariantMap &exercise, int selectedOptionCount, const QVariantList &correctAnswers);
    Q_INVOKABLE bool chooseAnswer(const QVariantMap &answer, int index, int selectedOptionCount, const QVariantList &colors);
    Q_INVOKABLE bool canEditUserAnswers(const QString &viewState, int selectedOptionCount, bool animationRunning) const;
    Q_INVOKABLE bool removeUserAnswerAt(int position);
    Q_INVOKABLE bool removeLastUserAnswer();
    Q_INVOKABLE void checkAnswers(const QVariantList &correctAnswers, int expectedAnswers, int maximumExercises);
    Q_INVOKABLE void resetTest();
    Q_INVOKABLE void startTest();
    Q_INVOKABLE void stopTest();
    Q_INVOKABLE void setActiveExercise(const QVariantMap &activeExercise);
    Q_INVOKABLE void randomlySelectExerciseOptions(int selectedOptionCount = -1);
    Q_INVOKABLE void giveUpWithCorrectAnswers(const QVariantList &correctAnswers, const QVariantList &availableAnswers, const QVariantList &colors, int expectedAnswers);
    Q_INVOKABLE void beginQuestion(int maximumExercises);
    Q_INVOKABLE void finishQuestionGeneration();
    Q_INVOKABLE void setSingleAnswerHighlight(const QString &answerName);
    Q_INVOKABLE void clearSingleAnswerHighlight();

Q_SIGNALS:
    void sessionChanged();
    void activeExerciseChanged(QVariantMap activeExercise);
    void selectedExerciseOptionsChanged(QJsonArray selectedExerciseOptions);

private:
    friend class Core;

    explicit ExerciseSessionController(QObject *parent = nullptr);

    void setStatusText(const QString &statusText);

    int m_currentAnswer = 0;
    QVariantList m_userAnswers;
    bool m_answersAreRight = false;
    bool m_giveUp = false;
    bool m_isTest = false;
    int m_correctAnswers = 0;
    int m_currentExercise = 0;
    QVariantMap m_activeExercise;
    QJsonArray m_selectedExerciseOptions;
    unsigned int m_chosenRootNote = 0;
    QString m_errorString;
    bool m_showingCorrectAnswers = false;
    int m_correctedAnswerPosition = -1;
    bool m_highlightingSingleAnswer = false;
    QString m_highlightedAnswerName;
    QString m_statusText;
};
}

#endif
