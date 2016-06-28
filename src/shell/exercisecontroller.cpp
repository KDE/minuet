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
    m_playMode(ScalePlayMode),
    m_chosenRootNote(0)
{
    m_exercises["exercises"] = QJsonArray();
    m_exercises["definitions"] = QJsonArray();
    qmlRegisterType<ExerciseController>("org.kde.minuet", 1, 0, "ExerciseController");
}

ExerciseController::~ExerciseController()
{
}

bool ExerciseController::initialize()
{
    bool definitionsMerge = mergeJsonFiles("definitions", m_definitions);
    bool exercisesMerge = mergeJsonFiles("exercises", m_exercises, true, "name", "children");

//     QFile file("merged-exercises.json");
//     file.open(QIODevice::WriteOnly);
//     file.write(QJsonDocument(m_exercises).toJson());
//     file.close();

    return definitionsMerge & exercisesMerge;
}

void ExerciseController::setPlayMode(PlayMode playMode)
{
    m_playMode = playMode;
}

void ExerciseController::randomlySelectOptions()
{
    while (!m_selectedOptions.isEmpty())
        m_selectedOptions.removeFirst();

    qsrand(QDateTime::currentDateTimeUtc().toTime_t());

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
        unsigned int chosenExercise = qrand() % m_currentExercise.size();
        QString sequence = m_currentExercise[chosenExercise].toObject()[QStringLiteral("sequence")].toString();

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

        m_selectedOptions.append(m_currentExercise[chosenExercise]);
    }
    if (m_playMode == RhythmPlayMode) {
        m_midiSequencer->appendEvent(m_midiSequencer->SMFNoteOn(9, 80, 120), barStart);
    }
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

bool ExerciseController::mergeJsonFiles(const QString directoryName, QJsonObject &targetObject, bool applyDefinitionsFlag, QString commonKey, QString mergeKey)
{
    m_errorString.clear();
    QStringList jsonDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, directoryName, QStandardPaths::LocateDirectory);
    foreach (const QString &jsonDirString, jsonDirs) {
        QDir jsonDir(jsonDirString);
        foreach (const QString &json, jsonDir.entryList(QDir::Files)) {
            QFile jsonFile(jsonDir.absoluteFilePath(json));
            if (!jsonFile.open(QIODevice::ReadOnly)) {
                m_errorString = i18n("Couldn't open json file \"%1\".", jsonDir.absoluteFilePath(json));
                return false;
            }
            QJsonParseError error;
            QJsonDocument jsonDocument = QJsonDocument::fromJson(jsonFile.readAll(), &error);

            if (error.error != QJsonParseError::NoError) {
                m_errorString = error.errorString();
                jsonFile.close();
                return false;
            }
            else {
                QJsonObject jsonObject = jsonDocument.object();
                if (applyDefinitionsFlag)
                    jsonObject[directoryName] = applyDefinitions(jsonObject[directoryName].toArray(),
                                                                 m_definitions[QStringLiteral("definitions")].toArray());

                targetObject[directoryName] = mergeJsonArrays(targetObject[directoryName].toArray(),
                                                              jsonObject[directoryName].toArray(),
                                                              commonKey,
                                                              mergeKey);
            }
            jsonFile.close();
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
            if (exerciseObjectKeys.contains(QStringLiteral("and-tags")) && exerciseObject[QStringLiteral("and-tags")].isArray())
                filterDefinitions(filteredDefinitions, exerciseObject, "and-tags", AndFiltering);
            if (exerciseObjectKeys.contains(QStringLiteral("or-tags")) && exerciseObject[QStringLiteral("or-tags")].isArray())
                filterDefinitions(filteredDefinitions, exerciseObject, "or-tags", OrFiltering);
            if (exerciseObjectKeys.contains(QStringLiteral("children")))
                exerciseObject[QStringLiteral("children")] = applyDefinitions(exerciseObject[QStringLiteral("children")].toArray(),
                                                                              filteredDefinitions);
            else
                exerciseObject.insert("options", filteredDefinitions);
            exercises[i1-exercisesBegin] = exerciseObject;
        }
    }
    return exercises;
}

void ExerciseController::filterDefinitions(QJsonArray &definitions, QJsonObject &exerciseObject, const QString &filterTagsKey, DefinitionFilteringMode definitionFilteringMode)
{
    QJsonArray filterTags = exerciseObject[filterTagsKey].toArray();
    exerciseObject.remove(filterTagsKey);
    for (QJsonArray::Iterator i2 = definitions.begin(); i2 < definitions.end(); ++i2) {
        bool remove = (definitionFilteringMode == AndFiltering) ? false:true;
        QJsonArray::const_iterator filterTagsEnd = filterTags.constEnd();
        for (QJsonArray::ConstIterator i3 = filterTags.constBegin(); i3 < filterTagsEnd; ++i3) {
            QJsonArray tagArray = i2->toObject()["tags"].toArray();
            if (definitionFilteringMode == AndFiltering && !tagArray.contains(*i3)) {
                remove = true;
                break;
            }
            if (definitionFilteringMode == OrFiltering && tagArray.contains(*i3))
                remove = false;
        }
        if (remove) {
            i2 = definitions.erase(i2);
            i2--;
        }
    }
}

QJsonArray ExerciseController::mergeJsonArrays(QJsonArray oldFile, QJsonArray newFile, QString commonKey, QString mergeKey)
{
    QJsonArray::const_iterator newFileEnd = newFile.constEnd();;
    for (QJsonArray::ConstIterator i1 = newFile.constBegin(); i1 < newFileEnd; ++i1) {
        if (i1->isObject()) {
            QJsonArray::ConstIterator i2;
            QJsonArray::const_iterator oldFileEnd = oldFile.constEnd();
            for (i2 = oldFile.constBegin(); i2 < oldFileEnd; ++i2) {
                QJsonObject newFileObject = i1->toObject();
                QJsonObject oldFileObject = i2->toObject();
                if (i2->isObject() &&
                    i1->isObject() &&
                    !commonKey.isEmpty() &&
                    oldFileObject[commonKey] == newFileObject[commonKey]) {
                        QJsonObject jsonObject = oldFile[i2-oldFile.constBegin()].toObject();
                        jsonObject[mergeKey] = mergeJsonArrays(oldFileObject[mergeKey].toArray(),
                                                            newFileObject[mergeKey].toArray(),
                                                            commonKey,
                                                            mergeKey);
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
