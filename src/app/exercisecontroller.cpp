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

#include <QDateTime>
#include <QDir>
#include <QJsonDocument>
#include <QRandomGenerator>
#include <QStandardPaths>
#include <QSet>
#include <qqml.h>

#include <utils/xdgdatadirs.h>

#include <algorithm>
#include <utility>

using namespace Qt::StringLiterals;

namespace Minuet
{
ExerciseController::ExerciseController(QObject *parent)
    : IExerciseController(parent), m_chosenRootNote(0)
{
    m_exercises[u"exercises"_s] = QJsonArray();
    m_definitions[u"definitions"_s] = QJsonArray();
}

bool ExerciseController::initialize(Core *core)
{
    Q_UNUSED(core)

    m_errorString.clear();
    bool definitionsMerge = mergeJsonFiles(u"definitions"_s, m_definitions);
    bool exercisesMerge = mergeJsonFiles(u"exercises"_s, m_exercises, true,
                                         u"name"_s, u"children"_s);

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
    while (!m_selectedExerciseOptions.isEmpty()) {
        m_selectedExerciseOptions.removeFirst();
    }

    auto failSelection = [this](const QString &errorString) {
        m_errorString = errorString;
        qWarning() << m_errorString;
        emit selectedExerciseOptionsChanged(m_selectedExerciseOptions);
    };

    int minNote = INT_MAX;
    int maxNote = INT_MIN;
    auto *generator = QRandomGenerator::global();
    const QJsonObject currentExerciseObject = QJsonObject::fromVariantMap(m_currentExercise);
    const int numberOfSelectedOptions
        = currentExerciseObject[u"numberOfSelectedOptions"_s].toInt();
    if (numberOfSelectedOptions <= 0) {
        failSelection(u"Current exercise has no selected options count."_s);
        return;
    }

    const QJsonArray exerciseOptions = currentExerciseObject[u"options"_s].toArray();
    if (exerciseOptions.isEmpty()) {
        failSelection(u"Current exercise has no options."_s);
        return;
    }
    if (numberOfSelectedOptions > exerciseOptions.size()) {
        failSelection(u"Current exercise selects more options than it provides."_s);
        return;
    }

    const QString playMode = currentExerciseObject[u"playMode"_s].toString();
    for (int i = 0; i < numberOfSelectedOptions; ++i) {
        const int chosenExerciseOption = generator->bounded(exerciseOptions.size());
        if (!exerciseOptions[chosenExerciseOption].isObject()) {
            failSelection(u"Current exercise option is not an object."_s);
            return;
        }

        const QJsonObject optionObject = exerciseOptions[chosenExerciseOption].toObject();
        const QString sequence = optionObject[u"sequence"_s].toString();
        const QStringList additionalNotes = sequence.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (additionalNotes.isEmpty()) {
            failSelection(u"Current exercise option has an empty sequence."_s);
            return;
        }

        for (const QString &additionalNote : additionalNotes) {
            bool ok = false;
            const int note = additionalNote.toInt(&ok);
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
            const QStringList exerciseRoots
                = currentExerciseObject[u"root"_s].toString().split(u".."_s);
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
            m_chosenRootNote
                = minAllowedRoot + generator->bounded(maxAllowedRoot - minAllowedRoot + 1);
        }

        QJsonObject jsonObject = optionObject;
        jsonObject[u"rootNote"_s] = QString::number(m_chosenRootNote);
        m_selectedExerciseOptions.append(jsonObject);
    }
    m_errorString.clear();
    emit selectedExerciseOptionsChanged(m_selectedExerciseOptions);
}

unsigned int ExerciseController::chosenRootNote() const
{
    return m_chosenRootNote;
}

QJsonArray ExerciseController::exercises() const
{
    return m_exercises[u"exercises"_s].toArray();
}

bool ExerciseController::mergeJsonFiles(const QString directoryName, QJsonObject &targetObject,
                                        bool applyDefinitionsFlag, QString commonKey,
                                        QString mergeKey)
{
    QStringList jsonDirs;
#if defined(Q_OS_ANDROID)
    jsonDirs << u"assets:/share/minuet/"_s + directoryName;
    jsonDirs << u"assets:/data/"_s + directoryName;
#elif defined(Q_OS_WIN)
    jsonDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation,
                                         u"minuet/"_s + directoryName,
                                         QStandardPaths::LocateDirectory);
#else
    jsonDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, directoryName,
                                         QStandardPaths::LocateDirectory);
#ifdef Q_OS_MACOS
    if (jsonDirs.isEmpty()) {
        const QStringList xdgDataDirs = Utils::xdgDataDirs();
        for (const auto &dirPath : xdgDataDirs) {
            const QDir testDir(
                QDir(dirPath).absoluteFilePath(u"minuet/"_s + directoryName));
            if (testDir.exists()) {
                jsonDirs << testDir.absolutePath();
            }
        }
    }
#endif
#endif

    // When running development version of Minuet, the program will attempt to
    // read JSON files from both system wide directories and CMake install prefix.
    // So if you have a system installation at the same time, duplicated JSON files will
    // be read and cause weird bugs, so store file names that is already read to avoid this.
    QSet<QString> readJsons;
    for (const QString &jsonDirString : std::as_const(jsonDirs)) {
        QDir jsonDir(jsonDirString);
        const QStringList jsonFiles = jsonDir.entryList(QDir::Files);
        for (const QString &json : jsonFiles) {
            if (!json.endsWith(u".json"_s)) {
                continue;
            }
            if (readJsons.contains(json)) {
                qWarning() << "Ignoring duplicated file:" << jsonDir.absoluteFilePath(json);
                continue;
            }
            readJsons << json;

            QFile jsonFile(jsonDir.absoluteFilePath(json));
            if (!jsonFile.open(QIODevice::ReadOnly)) {
#if !defined(Q_OS_ANDROID)
                m_errorString
                    = i18n("Could not open JSON file \"%1\".", jsonDir.absoluteFilePath(json));
#else
                m_errorString = u"Couldn't open json file \"%1\"."_s
                                    .arg(jsonDir.absoluteFilePath(json));
#endif
                return false;
            }
            QJsonParseError error;
            QJsonDocument jsonDocument = QJsonDocument::fromJson(jsonFile.readAll(), &error);

            if (error.error != QJsonParseError::NoError) {
                m_errorString += u"Error when parsing JSON file '%1'. "_s
                                     .arg(jsonDir.absoluteFilePath(json));
                jsonFile.close();
                return false;
            }
            if (!jsonDocument.isObject()) {
                m_errorString = u"JSON file '%1' does not contain an object."_s
                                    .arg(jsonDir.absoluteFilePath(json));
                jsonFile.close();
                return false;
            }

            QJsonObject jsonObject = jsonDocument.object();
            if (!jsonObject.value(directoryName).isArray()) {
                m_errorString = u"JSON file '%1' does not contain a '%2' array."_s
                                    .arg(jsonDir.absoluteFilePath(json), directoryName);
                jsonFile.close();
                return false;
            }
            if (applyDefinitionsFlag) {
                jsonObject[directoryName]
                    = applyDefinitions(jsonObject[directoryName].toArray(),
                                       m_definitions[u"definitions"_s].toArray());
            }

            targetObject[directoryName]
                = mergeJsonArrays(targetObject[directoryName].toArray(),
                                  jsonObject[directoryName].toArray(), commonKey, mergeKey);
            jsonFile.close();
        }
    }
    return true;
}

QJsonArray ExerciseController::applyDefinitions(QJsonArray exercises, QJsonArray definitions,
                                                QJsonObject collectedProperties)
{
    QJsonArray::const_iterator exercisesBegin = exercises.constBegin();
    QJsonArray::const_iterator exercisesEnd = exercises.constEnd();
    for (QJsonArray::ConstIterator i1 = exercisesBegin; i1 < exercisesEnd; ++i1) {
        if (i1->isObject()) {
            QJsonObject exerciseObject = i1->toObject();
            QJsonArray filteredDefinitions = definitions;
            QStringList exerciseObjectKeys = exerciseObject.keys();
            if (exerciseObjectKeys.contains(u"and-tags"_s)
                && exerciseObject[u"and-tags"_s].isArray()) {
                filterDefinitions(filteredDefinitions, exerciseObject, u"and-tags"_s,
                                  DefinitionFilteringMode::AndFiltering);
            }
            if (exerciseObjectKeys.contains(u"or-tags"_s)
                && exerciseObject[u"or-tags"_s].isArray()) {
                filterDefinitions(filteredDefinitions, exerciseObject, u"or-tags"_s,
                                  DefinitionFilteringMode::OrFiltering);
            }
            if (exerciseObjectKeys.contains(u"children"_s)) {
                for (const QString &key : std::as_const(exerciseObjectKeys)) {
                    if (key != u"name"_s && key != u"children"_s
                        && key != u"and-tags"_s && key != u"or-tags"_s
                        && !key.startsWith('_')) {
                        collectedProperties.insert(key, exerciseObject[key]);
                        exerciseObject.remove(key);
                    }
                }
                exerciseObject[u"children"_s]
                    = applyDefinitions(exerciseObject[u"children"_s].toArray(),
                                       filteredDefinitions, collectedProperties);
            } else {
                const QStringList collectedPropertyKeys = collectedProperties.keys();
                for (const QString &key : collectedPropertyKeys) {
                    if (!exerciseObject.contains(key)) {
                        exerciseObject.insert(key, collectedProperties[key]);
                    }
                }
                exerciseObject.insert(u"options"_s, filteredDefinitions);
            }
            exercises[i1 - exercisesBegin] = exerciseObject;
        }
    }
    return exercises;
}

void ExerciseController::filterDefinitions(QJsonArray &definitions, QJsonObject &exerciseObject,
                                           const QString &filterTagsKey,
                                           DefinitionFilteringMode definitionFilteringMode)
{
    QJsonArray filterTags = exerciseObject[filterTagsKey].toArray();
    exerciseObject.remove(filterTagsKey);
    for (QJsonArray::Iterator i2 = definitions.begin(); i2 < definitions.end();) {
        bool remove = definitionFilteringMode != DefinitionFilteringMode::AndFiltering;
        QJsonArray::const_iterator filterTagsEnd = filterTags.constEnd();
        for (QJsonArray::ConstIterator i3 = filterTags.constBegin(); i3 < filterTagsEnd; ++i3) {
            QJsonArray tagArray = i2->toObject()[u"tags"_s].toArray();
            if (definitionFilteringMode == DefinitionFilteringMode::AndFiltering && !tagArray.contains(*i3)) {
                remove = true;
                break;
            }
            if (definitionFilteringMode == DefinitionFilteringMode::OrFiltering && tagArray.contains(*i3)) {
                remove = false;
            }
        }
        if (remove) {
            i2 = definitions.erase(i2);
        } else {
            ++i2;
        }
    }
}

QJsonArray ExerciseController::mergeJsonArrays(QJsonArray oldFile, QJsonArray newFile,
                                               QString commonKey, QString mergeKey)
{
    QJsonArray::const_iterator newFileEnd = newFile.constEnd();
    ;
    for (QJsonArray::ConstIterator i1 = newFile.constBegin(); i1 < newFileEnd; ++i1) {
        if (i1->isObject()) {
            QJsonArray::ConstIterator i2;
            QJsonArray::const_iterator oldFileEnd = oldFile.constEnd();
            for (i2 = oldFile.constBegin(); i2 < oldFileEnd; ++i2) {
                QJsonObject newFileObject = i1->toObject();
                QJsonObject oldFileObject = i2->toObject();
                if (i2->isObject() && i1->isObject() && !commonKey.isEmpty()
                    && oldFileObject[commonKey] == newFileObject[commonKey]) {
                    QJsonObject jsonObject = oldFile[i2 - oldFile.constBegin()].toObject();
                    jsonObject[mergeKey]
                        = mergeJsonArrays(oldFileObject[mergeKey].toArray(),
                                          newFileObject[mergeKey].toArray(), commonKey, mergeKey);
                    oldFile[i2 - oldFile.constBegin()] = jsonObject;
                    break;
                }
            }
            if (i2 == oldFile.constEnd()) {
                oldFile.append(*i1);
            }
        }
    }
    return oldFile;
}

}

#include "moc_exercisecontroller.cpp"
