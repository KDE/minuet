/****************************************************************************
**
** Copyright (C) 2016 by Sandro S. Andrade <sandroandrade@kde.org>
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

#ifndef EXERCISECONTROLLER_H
#define EXERCISECONTROLLER_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QStringList>

class MidiSequencer;

class ExerciseController : public QObject
{
    Q_OBJECT
    Q_ENUMS(PlayMode)

public:
    explicit ExerciseController(MidiSequencer *midiSequencer = 0);
    virtual ~ExerciseController();
    
    enum PlayMode {
        ScalePlayMode = 0,
        ChordPlayMode,
        RhythmPlayMode
    };

    Q_INVOKABLE void setExerciseOptions(QJsonArray exerciseOptions);
    Q_INVOKABLE void setMinRootNote(unsigned int minRootNote);
    Q_INVOKABLE void setMaxRootNote(unsigned int maxRootNote);
    Q_INVOKABLE void setPlayMode(PlayMode playMode);
    Q_INVOKABLE void setAnswerLength(unsigned int answerLength);
    Q_INVOKABLE QStringList randomlyChooseExercises();
    Q_INVOKABLE unsigned int chosenRootNote();
    Q_INVOKABLE void playChoosenExercise();

    bool configureExercises();
    QString errorString() const;
    QJsonObject exercises() const;
    
private:
    QJsonArray mergeExercises(QJsonArray exercises, QJsonArray newExercises);

private:
    MidiSequencer *m_midiSequencer;
    QJsonObject m_exercises;
    QJsonArray m_exerciseOptions;
    unsigned int m_minRootNote;
    unsigned int m_maxRootNote;
    PlayMode m_playMode;
    unsigned int m_answerLength;
    unsigned int m_chosenRootNote;
    unsigned int m_chosenExercise;
    QString m_errorString;
};

#endif // EXERCISECONTROLLER_H
