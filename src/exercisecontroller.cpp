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

#include "exercisecontroller.h"

#include "midisequencer.h"

#include <KI18n/KLocalizedString>

#include <QDir>
#include <QDateTime>
#include <QJsonDocument>
#include <QStandardPaths>

#include <QtQml> // krazy:exclude=includes

#include <drumstick/alsaevent.h>

ExerciseController::ExerciseController(MidiSequencer *midiSequencer) :
    m_midiSequencer(midiSequencer),
    m_chosenExercise(0),
    m_chosenRootNote(0),
    m_minRootNote(0),
    m_maxRootNote(0),
    m_playMode(ScalePlayMode)
{
    qmlRegisterType<ExerciseController>("org.kde.minuet", 1, 0, "ExerciseController");
}

ExerciseController::~ExerciseController()
{
}

void ExerciseController::setExerciseOptions(QJsonArray exerciseOptions)
{
    m_exerciseOptions = exerciseOptions;
}

void ExerciseController::setMinRootNote(unsigned int minRootNote)
{
    m_minRootNote = minRootNote;
}

void ExerciseController::setMaxRootNote(unsigned int maxRootNote)
{
    m_maxRootNote = maxRootNote;
}

void ExerciseController::setPlayMode(PlayMode playMode)
{
    m_playMode = playMode;
}

QString ExerciseController::randomlyChooseExercise()
{
    qsrand(QDateTime::currentDateTimeUtc().toTime_t());
    m_chosenExercise = qrand() % m_exerciseOptions.size();
    QString sequenceFromRoot = m_exerciseOptions[m_chosenExercise].toObject()[QStringLiteral("sequenceFromRoot")].toString();
    int minNote = INT_MAX;
    int maxNote = INT_MIN;
    foreach(const QString &additionalNote, sequenceFromRoot.split(' ')) {
        int note = additionalNote.toInt();
        if (note > maxNote) maxNote = note;
        if (note < minNote) minNote = note;
    }
    do
        m_chosenRootNote = m_minRootNote + qrand() % (m_maxRootNote - m_minRootNote);
    while (m_chosenRootNote + maxNote > 108 || m_chosenRootNote + minNote < 21);

    Song *song = new Song;
    song->setHeader(0, 1, 60);
    song->setInitialTempo(600000);
    m_midiSequencer->setSong(song);
    m_midiSequencer->appendEvent(m_midiSequencer->SMFTempo(600000), 0);
    drumstick::SequencerEvent *ev;
    m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(1, m_chosenRootNote, 120), 0);
    m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOff(1, m_chosenRootNote, 120), 60);
    
    unsigned int i = 1;
    foreach(const QString &additionalNote, sequenceFromRoot.split(' ')) {
        m_midiSequencer->appendEvent(ev = m_midiSequencer->SMFNoteOn(1, m_chosenRootNote + additionalNote.toInt(), 120), (m_playMode == ScalePlayMode) ? 60*i:0);
        ev->setTag(0);
        m_midiSequencer->appendEvent(ev = m_midiSequencer->SMFNoteOff(1, m_chosenRootNote + additionalNote.toInt(), 120), (m_playMode == ScalePlayMode) ? 60*(i+1):60);
        ev->setTag(0);
        ++i;
    }

    return m_exerciseOptions[m_chosenExercise].toObject()[QStringLiteral("name")].toString();
}

unsigned int ExerciseController::chosenRootNote()
{
    return m_chosenRootNote;
}

void ExerciseController::playChoosenExercise()
{
    m_midiSequencer->play();
}

bool ExerciseController::configureExercises()
{
    m_errorString.clear();
    QDir exercisesDir = QStandardPaths::locate(QStandardPaths::AppDataLocation, QStringLiteral("exercises"), QStandardPaths::LocateDirectory);
    foreach (const QString &exercise, exercisesDir.entryList(QDir::Files)) {
        QFile exerciseFile(exercisesDir.absoluteFilePath(exercise));
        if (!exerciseFile.open(QIODevice::ReadOnly)) {
            m_errorString = i18n("Couldn't open exercise file \"%1\".", exercisesDir.absoluteFilePath(exercise));
            return false;
        }
        QJsonParseError error;
        QJsonDocument jsonDocument = QJsonDocument::fromJson(exerciseFile.readAll(), &error);

        if (error.error != QJsonParseError::NoError) {
            m_errorString = error.errorString();
            exerciseFile.close();
            return false;
        }
        else {
            if (m_exercises.length() == 0)
                m_exercises = jsonDocument.object();
            else
                m_exercises[QStringLiteral("exercises")] = mergeExercises(m_exercises[QStringLiteral("exercises")].toArray(),
                                                        jsonDocument.object()[QStringLiteral("exercises")].toArray());
        }
        exerciseFile.close();
    }
    return true;
}

QString ExerciseController::errorString() const
{
    return m_errorString;
}

QJsonObject ExerciseController::exercises() const
{
    return m_exercises;
}

QJsonArray ExerciseController::mergeExercises(QJsonArray exercises, QJsonArray newExercises)
{
    for (QJsonArray::ConstIterator i1 = newExercises.constBegin(); i1 < newExercises.constEnd(); ++i1) {
        if (i1->isObject()) {
            QJsonArray::ConstIterator i2;
            for (i2 = exercises.constBegin(); i2 < exercises.constEnd(); ++i2) {
                if (i2->isObject() && i1->isObject() && i2->toObject()[QStringLiteral("name")] == i1->toObject()[QStringLiteral("name")]) {
                    QJsonObject jsonObject = exercises[i2-exercises.constBegin()].toObject();
                    jsonObject[QStringLiteral("children")] = mergeExercises(i2->toObject()[QStringLiteral("children")].toArray(), i1->toObject()[QStringLiteral("children")].toArray());
                    exercises[i2-exercises.constBegin()] = jsonObject;
                    break;
                }
            }
            if (i2 == exercises.constEnd())
                exercises.append(*i1);
        }
    }
    return exercises;
}

