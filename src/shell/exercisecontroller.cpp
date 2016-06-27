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

#include <KLocalizedString>

#include <QDir>
#include <QDateTime>
#include <QJsonDocument>
#include <QStandardPaths>

#include <QtQml> // krazy:exclude=includes

#include <drumstick/alsaevent.h>

namespace Minuet
{
    
ExerciseController::ExerciseController(MidiSequencer *midiSequencer) :
    m_midiSequencer(midiSequencer),
    m_minRootNote(0),
    m_maxRootNote(0),
    m_playMode(ScalePlayMode),
    m_answerLength(1),
    m_chosenRootNote(0),
    m_chosenExercise(0)
{
    qmlRegisterType<ExerciseController>("org.kde.minuet", 1, 0, "ExerciseController");
}

ExerciseController::~ExerciseController()
{
}

bool ExerciseController::initialize()
{
    bool definitions = mergeDefinitions();
    bool exercises = mergeExercises();

    QFile file("merged-exercises.json");
    file.open(QIODevice::WriteOnly);
    file.write(QJsonDocument(m_exercises).toJson());
    file.close();
    return definitions & exercises;
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

void ExerciseController::setAnswerLength(unsigned int answerLength)
{
    m_answerLength = answerLength;
}

QStringList ExerciseController::randomlyChooseExercises()
{
    qsrand(QDateTime::currentDateTimeUtc().toTime_t());
    QStringList chosenExercises;

    Song *song = new Song;
    song->setHeader(0, 1, 60);
    song->setInitialTempo(600000);
    m_midiSequencer->setSong(song);
    m_midiSequencer->appendEvent(m_midiSequencer->SMFTempo(600000), 0);

    unsigned int barStart = 0;
    if (m_playMode == RhythmPlayMode) {
        m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 80, 120), 0);
        m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 80, 120), 60);
        m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 80, 120), 120);
        m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 80, 120), 180);
        barStart = 240;
    }

    for (unsigned int i = 0; i < m_answerLength; ++i) {
        m_chosenExercise = qrand() % m_exerciseOptions.size();
        QString sequence = m_exerciseOptions[m_chosenExercise].toObject()[QStringLiteral("sequence")].toString();

        if (m_playMode != RhythmPlayMode) {
            int minNote = INT_MAX;
            int maxNote = INT_MIN;
            foreach(const QString &additionalNote, sequence.split(' ')) {
                int note = additionalNote.toInt();
                if (note > maxNote) maxNote = note;
                if (note < minNote) minNote = note;
            }
            do
                m_chosenRootNote = m_minRootNote + qrand() % (m_maxRootNote - m_minRootNote);
            while (m_chosenRootNote + maxNote > 108 || m_chosenRootNote + minNote < 21);

            m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(1, m_chosenRootNote, 120), barStart);
            m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOff(1, m_chosenRootNote, 120), barStart + 60);
 
            unsigned int j = 1;
            drumstick::SequencerEvent *ev;
            foreach(const QString &additionalNote, sequence.split(' ')) {
                m_midiSequencer->appendEvent(ev = m_midiSequencer->SMFNoteOn(1,
                                                                   m_chosenRootNote + additionalNote.toInt(),
                                                                   120),
                                                                   (m_playMode == ScalePlayMode) ? barStart+60*j:barStart);
                ev->setTag(0);
                m_midiSequencer->appendEvent(ev = m_midiSequencer->SMFNoteOff(1,
                                                                   m_chosenRootNote + additionalNote.toInt(),
                                                                   120),
                                                                   (m_playMode == ScalePlayMode) ? barStart+60*(j+1):barStart+60);
                ev->setTag(0);
                ++j;
            }
            barStart += 60;
        }
        else {
            m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 80, 120), barStart);
            foreach(QString additionalNote, sequence.split(' ')) { // krazy:exclude=foreach
                m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 37, 120), barStart);
                float dotted = 1;
                if (additionalNote.endsWith('.')) {
                    dotted = 1.5;
                    additionalNote.chop(1);
                }
                barStart += dotted*60*(4.0/additionalNote.toInt());
            }
        }

        chosenExercises << m_exerciseOptions[m_chosenExercise].toObject()[QStringLiteral("name")].toString();
    }
    if (m_playMode == RhythmPlayMode) {
        m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 80, 120), barStart);
    }

    return chosenExercises;
}

unsigned int ExerciseController::chosenRootNote()
{
    return m_chosenRootNote;
}

void ExerciseController::playChoosenExercise()
{
    m_midiSequencer->play();
}

QString ExerciseController::errorString() const
{
    return m_errorString;
}

QJsonObject ExerciseController::exercises() const
{
    return m_exercises;
}

bool ExerciseController::mergeDefinitions()
{
    m_errorString.clear();
    QStringList definitionsDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, QStringLiteral("definitions"), QStandardPaths::LocateDirectory);
    foreach (const QString &definitionsDirString, definitionsDirs) {
        QDir definitionsDir(definitionsDirString);
        foreach (const QString &definition, definitionsDir.entryList(QDir::Files)) {
            QFile definitionsFile(definitionsDir.absoluteFilePath(definition));
            if (!definitionsFile.open(QIODevice::ReadOnly)) {
                m_errorString = i18n("Couldn't open definition file \"%1\".", definitionsDir.absoluteFilePath(definition));
                return false;
            }
            QJsonParseError error;
            QJsonDocument jsonDocument = QJsonDocument::fromJson(definitionsFile.readAll(), &error);

            if (error.error != QJsonParseError::NoError) {
                m_errorString = error.errorString();
                definitionsFile.close();
                return false;
            }
            else {
                if (m_definitions.length() == 0)
                    m_definitions = jsonDocument.object();
                else
                    m_definitions[QStringLiteral("definitions")] = mergeJsonFiles(m_definitions[QStringLiteral("definitions")].toArray(),
                                                            jsonDocument.object()[QStringLiteral("definitions")].toArray());
            }
            definitionsFile.close();
        }
    }
    return true;
}

bool ExerciseController::mergeExercises()
{
    m_errorString.clear();
    QStringList exercisesDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, QStringLiteral("exercises"), QStandardPaths::LocateDirectory);
    foreach (const QString &exercisesDirString, exercisesDirs) {
        QDir exercisesDir(exercisesDirString);
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
                QJsonObject jsonObject = jsonDocument.object();
                jsonObject[QStringLiteral("exercises")] = applyDefinitions(jsonObject[QStringLiteral("exercises")].toArray(),
                                                                           m_definitions[QStringLiteral("definitions")].toArray());

                if (m_exercises.length() == 0)
                    m_exercises = jsonObject;
                else
                    m_exercises[QStringLiteral("exercises")] = mergeJsonFiles(m_exercises[QStringLiteral("exercises")].toArray(),
                                                            jsonObject[QStringLiteral("exercises")].toArray(), "name", "children");
            }
            exerciseFile.close();
        }
    }
    return true;
}

QJsonArray ExerciseController::applyDefinitions(QJsonArray exercises, QJsonArray definitions)
{
    QJsonArray::const_iterator exercisesBegin = exercises.constBegin();
    QJsonArray::const_iterator exercisesEnd = exercises.constEnd();
    for (QJsonArray::ConstIterator i1 = exercisesBegin; i1 < exercisesEnd; ++i1) {
        if (i1->isObject()) {
            QJsonObject exerciseObject = i1->toObject();
            QJsonArray filteredDefinitions = definitions;
            QStringList exerciseObjectKeys = exerciseObject.keys();
            if (exerciseObjectKeys.contains(QStringLiteral("and-tags")) && exerciseObject[QStringLiteral("and-tags")].isArray()) {
                QJsonArray filterTags = exerciseObject["and-tags"].toArray();
                exerciseObject.remove("and-tags");
                for (QJsonArray::Iterator i2 = filteredDefinitions.begin(); i2 < filteredDefinitions.end(); ++i2) {
                    QJsonArray tagArray = i2->toObject()["tags"].toArray();
                    QJsonArray::const_iterator filterTagsEnd = filterTags.constEnd();
                    for (QJsonArray::ConstIterator i3 = filterTags.constBegin(); i3 < filterTagsEnd; ++i3) {
                        if (!tagArray.contains(*i3)) {
                            i2 = filteredDefinitions.erase(i2);
                            i2--;
                            break;
                        }
                    }
                }
            }
            if (exerciseObjectKeys.contains(QStringLiteral("or-tags")) && exerciseObject[QStringLiteral("or-tags")].isArray()) {
                QJsonArray orTags = exerciseObject[QStringLiteral("or-tags")].toArray();
                exerciseObject.remove(QStringLiteral("or-tags"));
                for (QJsonArray::Iterator i2 = filteredDefinitions.begin(); i2 < filteredDefinitions.end(); ++i2) {
                    QJsonObject definitionObject = i2->toObject();
                    QJsonArray tagArray = definitionObject["tags"].toArray();
                    bool contains = false;
                    QJsonArray::const_iterator orTagsEnd = orTags.constEnd();
                    for (QJsonArray::ConstIterator i3 = orTags.constBegin(); i3 < orTagsEnd; ++i3)
                        if (tagArray.contains(*i3))
                            contains = true;
                    filteredDefinitions[i2-filteredDefinitions.begin()] = definitionObject;
                    if (!contains) {
                        i2 = filteredDefinitions.erase(i2);
                        i2--;
                    }
                }
            }
            if (exerciseObjectKeys.contains(QStringLiteral("children"))) {
                exerciseObject[QStringLiteral("children")] = applyDefinitions(exerciseObject[QStringLiteral("children")].toArray(), filteredDefinitions);
            }
            else {
                QJsonArray::const_iterator filteredDefinitionsBegin = filteredDefinitions.constBegin();
                QJsonArray::const_iterator filteredDefinitionsEnd = filteredDefinitions.constEnd();
                for (QJsonArray::ConstIterator i = filteredDefinitions.constBegin(); i < filteredDefinitionsEnd; ++i) {
                    QJsonObject definitionObject = i->toObject();
                    definitionObject.remove("tags");
                    filteredDefinitions[i-filteredDefinitionsBegin] = definitionObject;
                }
                exerciseObject.insert("options", filteredDefinitions);
            }
            exercises[i1-exercisesBegin] = exerciseObject;
        }
    }
    return exercises;
}

QJsonArray ExerciseController::mergeJsonFiles(QJsonArray oldFile, QJsonArray newFile, QString commonKey, QString mergeKey)
{
    QJsonArray::const_iterator newFileEnd = newFile.constEnd();;
    for (QJsonArray::ConstIterator i1 = newFile.constBegin(); i1 < newFileEnd; ++i1) {
        if (i1->isObject()) {
            QJsonObject newFileObject = i1->toObject();
            QJsonArray::ConstIterator i2;
            QJsonArray::const_iterator oldFileEnd = oldFile.constEnd();
            for (i2 = oldFile.constBegin(); i2 < oldFileEnd; ++i2) {
                QJsonObject oldFileObject = i2->toObject();
                if (i2->isObject() && i1->isObject() && !commonKey.isEmpty() && oldFileObject[commonKey] == newFileObject[commonKey]) {
                    QJsonObject jsonObject = oldFile[i2-oldFile.constBegin()].toObject();
                    jsonObject[mergeKey] = mergeJsonFiles(oldFileObject[mergeKey].toArray(), newFileObject[mergeKey].toArray(), commonKey, mergeKey);
                    oldFile[i2-oldFile.constBegin()] = jsonObject;
                    break;
                }
            }
            if (i2 == oldFile.constEnd())
                oldFile.append(*i1);
        }
    }
    return oldFile;
}

}
