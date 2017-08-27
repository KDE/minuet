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

#if !defined(Q_OS_ANDROID)
#include <KLocalizedString>
#endif

#include <QDir>
#include <qqml.h>
#include <QDateTime>
#include <QJsonDocument>
#include <QStandardPaths>

namespace Minuet
{
    
ExerciseController::ExerciseController(QObject *parent) :
    IExerciseController(parent),
    m_chosenRootNote(0)
{
    m_exercises["exercises"] = QJsonArray();
    m_definitions["definitions"] = QJsonArray();
}

ExerciseController::~ExerciseController()
{
}

bool ExerciseController::initialize(Core *core)
{
    Q_UNUSED(core)

    m_errorString.clear();
    bool definitionsMerge = mergeJsonFiles("definitions", m_definitions);
    bool exercisesMerge = mergeJsonFiles("exercises", m_exercises, true, "name", "children");

//    QFile file("merged-exercises.json");
//    file.open(QIODevice::WriteOnly);
//    file.write(QJsonDocument(m_exercises).toJson());
//    file.close();

    return definitionsMerge & exercisesMerge;
}

QString ExerciseController::errorString() const
{
    return m_errorString;
}

void ExerciseController::randomlySelectExerciseOptions()
{
    while (!m_selectedExerciseOptions.isEmpty())
        m_selectedExerciseOptions.removeFirst();

    qsrand(QDateTime::currentDateTimeUtc().toTime_t());

    int minNote = INT_MAX;
    int maxNote = INT_MIN;
    quint8 numberOfSelectedOptions = m_currentExercise[QStringLiteral("numberOfSelectedOptions")].toInt();
    for (quint8 i = 0; i < numberOfSelectedOptions; ++i) {
        QJsonArray exerciseOptions = QJsonObject::fromVariantMap(m_currentExercise)[QStringLiteral("options")].toArray();
        quint8 chosenExerciseOption = qrand() % exerciseOptions.size();

        QString sequence = exerciseOptions[chosenExerciseOption].toObject()[QStringLiteral("sequence")].toArray()[0].toString();
        foreach(const QString &additionalNote, sequence.split(' ')) {
            int note = additionalNote.toInt();
            if (note > maxNote) maxNote = note;
            if (note < minNote) minNote = note;
        }
        if (m_currentExercise["playMode"].toString() != "rhythm") {
            QStringList exerciseRoots = m_currentExercise["root"].toString().split('.');
            quint8 exerciseMinRoot = exerciseRoots.first().toInt();
            quint8 exerciseMaxRoot = exerciseRoots.last().toInt();
            do
                m_chosenRootNote = exerciseMinRoot + qrand() % (exerciseMaxRoot - exerciseMinRoot);
            while (m_chosenRootNote + maxNote > 108 || m_chosenRootNote + minNote < 21);
        }

        QJsonObject jsonObject = exerciseOptions[chosenExerciseOption].toObject();
        jsonObject["rootNote"] = QString::number(m_chosenRootNote);
        exerciseOptions[chosenExerciseOption] = jsonObject;
        m_selectedExerciseOptions.append(exerciseOptions[chosenExerciseOption]);
    }
    emit selectedExerciseOptionsChanged(m_selectedExerciseOptions);
}

unsigned int ExerciseController::chosenRootNote()
{
    return m_chosenRootNote;
}

QJsonArray ExerciseController::exercises() const
{
    return m_exercises[QStringLiteral("exercises")].toArray();
}

bool ExerciseController::mergeJsonFiles(const QString directoryName, QJsonObject &targetObject, bool applyDefinitionsFlag, QString commonKey, QString mergeKey)
{
#if defined(Q_OS_ANDROID)
    QStringList jsonDirs;
    jsonDirs += "/data/data/org.kde.minuet/qt-reserved-files/share/minuet/" + directoryName;
#elif defined(Q_OS_WIN)
    QStringList jsonDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, QStringLiteral("minuet/") + directoryName, QStandardPaths::LocateDirectory);
#else
    QStringList jsonDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, directoryName, QStandardPaths::LocateDirectory);
#endif
    foreach (const QString &jsonDirString, jsonDirs) {
        QDir jsonDir(jsonDirString);
        foreach (const QString &json, jsonDir.entryList(QDir::Files)) {
            QFile jsonFile(jsonDir.absoluteFilePath(json));
            if (!jsonFile.open(QIODevice::ReadOnly)) {
#if !defined(Q_OS_ANDROID)
                m_errorString = i18n("Could not open JSON file \"%1\".", jsonDir.absoluteFilePath(json));
#else
                m_errorString = QStringLiteral("Couldn't open json file \"%1\".").arg(jsonDir.absoluteFilePath(json));
#endif
                return false;
            }
            QJsonParseError error;
            QJsonDocument jsonDocument = QJsonDocument::fromJson(jsonFile.readAll(), &error);

            if (error.error != QJsonParseError::NoError) {
                m_errorString += QStringLiteral("Error when parsing JSON file '%1'. ").arg(jsonDir.absoluteFilePath(json));
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

QJsonArray ExerciseController::applyDefinitions(QJsonArray exercises, QJsonArray definitions, QJsonObject collectedProperties)
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
            if (exerciseObjectKeys.contains(QStringLiteral("children"))) {
                foreach(const QString &key, exerciseObjectKeys)
                    if (key != "name" && key != "children" && key != "and-tags" && key != "or-tags" && !key.startsWith('_')) {
                        collectedProperties.insert(key, exerciseObject[key]);
                        exerciseObject.remove(key);
                    }
                exerciseObject[QStringLiteral("children")] = applyDefinitions(exerciseObject[QStringLiteral("children")].toArray(),
                                                                              filteredDefinitions, collectedProperties);
            }
            else {
                foreach(const QString &key, collectedProperties.keys())
                    if (!exerciseObject.contains(key))
                        exerciseObject.insert(key, collectedProperties[key]);
                exerciseObject.insert("options", filteredDefinitions);
            }
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
