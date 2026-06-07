// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "exercisecatalogcontroller.h"

#include <KLocalizedString>

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QSet>
#include <QStandardPaths>

#include <utils/xdgdatadirs.h>

using namespace Qt::StringLiterals;

namespace Minuet
{
namespace
{
constexpr const char *technicalTermContext = "technical term, do you have a musician friend?";

QString translatedCatalogText(const QString &text)
{
    return text.isEmpty() ? QString() : i18nc(technicalTermContext, text.toUtf8().constData());
}

QString translatedDescriptionForSearch(const QVariantMap &exercise)
{
    const QString exerciseDescription = exercise.value(u"description"_s).toString();
    if (!exerciseDescription.isEmpty()) {
        return translatedCatalogText(exerciseDescription);
    }

    const QString userMessage = exercise.value(u"userMessage"_s).toString();
    if (!userMessage.isEmpty()) {
        return translatedCatalogText(userMessage);
    }

    QString description = i18n("Practice identifying this exercise by ear.");
    const QString playMode = exercise.value(u"playMode"_s).toString();
    if (playMode == u"rhythm"_s) {
        description = i18n("Practice rhythm recognition.");
    } else if (playMode == u"scale"_s) {
        description = i18n("Identify the scale by ear.");
    } else if (playMode == u"chord"_s) {
        description = i18n("Identify the chord or interval by ear.");
    }

    const QVariantList options = exercise.value(u"options"_s).toList();
    if (!options.isEmpty()) {
        return i18n("%1 Includes %2 possible answers.", description, options.size());
    }
    return description;
}
}

ExerciseCatalogController::ExerciseCatalogController(QObject *parent)
    : QObject(parent)
{
    m_exercises[u"exercises"_s] = QJsonArray();
    m_definitions[u"definitions"_s] = QJsonArray();
}

bool ExerciseCatalogController::initialize()
{
    m_errorString.clear();
    const bool definitionsMerge = mergeJsonFiles(u"definitions"_s, m_definitions);
    const bool exercisesMerge = mergeJsonFiles(u"exercises"_s, m_exercises, true, u"name"_s, u"children"_s);
    return definitionsMerge && exercisesMerge;
}

QString ExerciseCatalogController::errorString() const
{
    return m_errorString;
}

QJsonArray ExerciseCatalogController::exercises() const
{
    return m_exercises[u"exercises"_s].toArray();
}

QString ExerciseCatalogController::iconNameForExercise(const QVariantMap &exercise, const QString &inheritedIconName) const
{
    return resolvedIconName(exercise, inheritedIconName, u"view-list-details"_s);
}

QString ExerciseCatalogController::actionIconNameForExercise(const QVariantMap &exercise, const QString &inheritedIconName) const
{
    return resolvedIconName(exercise, inheritedIconName, QString());
}

QVariantList ExerciseCatalogController::collectExercises(const QVariantList &exercises, const QString &inheritedIconName) const
{
    QVariantList collectedExercises;
    for (const QVariant &exerciseValue : exercises) {
        collectExercise(exerciseValue.toMap(), inheritedIconName, collectedExercises);
    }
    return collectedExercises;
}

QString ExerciseCatalogController::exerciseDescription(const QVariantMap &exercise) const
{
    const QString exerciseDescription = exercise.value(u"description"_s).toString();
    if (!exerciseDescription.isEmpty()) {
        return exerciseDescription;
    }

    const QString userMessage = exercise.value(u"userMessage"_s).toString();
    if (!userMessage.isEmpty()) {
        return userMessage;
    }

    QString description = i18n("Practice identifying this exercise by ear.");
    const QString playMode = exercise.value(u"playMode"_s).toString();
    if (playMode == u"rhythm"_s) {
        description = i18n("Practice rhythm recognition.");
    } else if (playMode == u"scale"_s) {
        description = i18n("Identify the scale by ear.");
    } else if (playMode == u"chord"_s) {
        description = i18n("Identify the chord or interval by ear.");
    }

    const QVariantList options = exercise.value(u"options"_s).toList();
    if (!options.isEmpty()) {
        return i18n("%1 Includes %2 possible answers.", description, options.size());
    }
    return description;
}

QString ExerciseCatalogController::normalizedText(const QString &text) const
{
    return text.trimmed().toLower();
}

bool ExerciseCatalogController::actionMatches(const QString &actionText, const QString &searchText) const
{
    return normalizedText(actionText).contains(searchText);
}

bool ExerciseCatalogController::exerciseMatchesSearch(const QVariantMap &exercise, const QString &searchText, const QString &inheritedIconName) const
{
    if (actionMatches(translatedCatalogText(exercise.value(u"name"_s).toString()), searchText)
        || actionMatches(translatedDescriptionForSearch(exercise), searchText)) {
        return true;
    }

    const QVariantList children = exercise.value(u"children"_s).toList();
    if (children.isEmpty()) {
        return false;
    }

    const QString childIconName = actionIconNameForExercise(exercise, inheritedIconName);
    for (const QVariant &childExercise : children) {
        if (exerciseMatchesSearch(childExercise.toMap(), searchText, childIconName)) {
            return true;
        }
    }
    return false;
}

void ExerciseCatalogController::collectExercise(const QVariantMap &exercise, const QString &inheritedIconName, QVariantList &collectedExercises) const
{
    const QString iconName = iconNameForExercise(exercise, inheritedIconName);
    const QVariantList children = exercise.value(u"children"_s).toList();
    if (!children.isEmpty()) {
        for (const QVariant &childExercise : children) {
            collectExercise(childExercise.toMap(), iconName, collectedExercises);
        }
        return;
    }

    QVariantMap collectedExercise;
    collectedExercise[u"exercise"_s] = exercise;
    collectedExercise[u"iconName"_s] = iconName;
    collectedExercises.push_back(collectedExercise);
}

QString ExerciseCatalogController::resolvedIconName(const QVariantMap &exercise, const QString &inheritedIconName, const QString &fallbackIconName) const
{
    QString iconName = exercise.value(u"_icon"_s).toString();
    if (iconName.isEmpty()) {
        iconName = inheritedIconName;
    }
    if (iconName.isEmpty()) {
        return fallbackIconName;
    }
    return iconName.startsWith(u"qrc:/"_s) ? iconName : u"qrc:/icons/22-actions-"_s + iconName;
}

bool ExerciseCatalogController::mergeJsonFiles(const QString directoryName,
                                               QJsonObject &targetObject,
                                               bool applyDefinitionsFlag,
                                               QString commonKey,
                                               QString mergeKey)
{
    QStringList jsonDirs;
#if defined(Q_OS_ANDROID)
    jsonDirs << u"assets:/share/minuet/"_s + directoryName;
    jsonDirs << u"assets:/data/"_s + directoryName;
#elif defined(Q_OS_IOS)
    jsonDirs << u":/data/"_s + directoryName;
#elif defined(Q_OS_WIN)
    jsonDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, u"minuet/"_s + directoryName, QStandardPaths::LocateDirectory);
#else
    jsonDirs = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, directoryName, QStandardPaths::LocateDirectory);
#ifdef Q_OS_MACOS
    const QString bundleJsonDir = QDir(QCoreApplication::applicationDirPath()).absoluteFilePath(u"../Resources/minuet/"_s + directoryName);
    if (QDir(bundleJsonDir).exists()) {
        jsonDirs << QDir::cleanPath(bundleJsonDir);
    }
    if (jsonDirs.isEmpty()) {
        const QStringList xdgDataDirs = Utils::xdgDataDirs();
        for (const auto &dirPath : xdgDataDirs) {
            const QDir testDir(QDir(dirPath).absoluteFilePath(u"minuet/"_s + directoryName));
            if (testDir.exists()) {
                jsonDirs << testDir.absolutePath();
            }
        }
    }
#endif
#endif

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
                m_errorString = i18n("Could not open JSON file \"%1\".", jsonDir.absoluteFilePath(json));
#else
                m_errorString = u"Couldn't open json file \"%1\"."_s.arg(jsonDir.absoluteFilePath(json));
#endif
                return false;
            }
            QJsonParseError error;
            const QJsonDocument jsonDocument = QJsonDocument::fromJson(jsonFile.readAll(), &error);

            if (error.error != QJsonParseError::NoError) {
                m_errorString += u"Error when parsing JSON file '%1'. "_s.arg(jsonDir.absoluteFilePath(json));
                return false;
            }
            if (!jsonDocument.isObject()) {
                m_errorString = u"JSON file '%1' does not contain an object."_s.arg(jsonDir.absoluteFilePath(json));
                return false;
            }

            QJsonObject jsonObject = jsonDocument.object();
            if (!jsonObject.value(directoryName).isArray()) {
                m_errorString = u"JSON file '%1' does not contain a '%2' array."_s.arg(jsonDir.absoluteFilePath(json), directoryName);
                return false;
            }
            if (applyDefinitionsFlag) {
                jsonObject[directoryName] = applyDefinitions(jsonObject[directoryName].toArray(), m_definitions[u"definitions"_s].toArray());
            }

            targetObject[directoryName] = mergeJsonArrays(targetObject[directoryName].toArray(), jsonObject[directoryName].toArray(), commonKey, mergeKey);
        }
    }
    return true;
}

QJsonArray ExerciseCatalogController::applyDefinitions(QJsonArray exercises, QJsonArray definitions, QJsonObject collectedProperties)
{
    const QJsonArray::const_iterator exercisesBegin = exercises.constBegin();
    const QJsonArray::const_iterator exercisesEnd = exercises.constEnd();
    for (QJsonArray::ConstIterator i1 = exercisesBegin; i1 < exercisesEnd; ++i1) {
        if (i1->isObject()) {
            QJsonObject exerciseObject = i1->toObject();
            QJsonArray filteredDefinitions = definitions;
            const QStringList exerciseObjectKeys = exerciseObject.keys();
            if (exerciseObjectKeys.contains(u"and-tags"_s) && exerciseObject[u"and-tags"_s].isArray()) {
                filterDefinitions(filteredDefinitions, exerciseObject, u"and-tags"_s, DefinitionFilteringMode::AndFiltering);
            }
            if (exerciseObjectKeys.contains(u"or-tags"_s) && exerciseObject[u"or-tags"_s].isArray()) {
                filterDefinitions(filteredDefinitions, exerciseObject, u"or-tags"_s, DefinitionFilteringMode::OrFiltering);
            }
            if (exerciseObjectKeys.contains(u"children"_s)) {
                for (const QString &key : std::as_const(exerciseObjectKeys)) {
                    if (key != u"name"_s && key != u"children"_s && key != u"and-tags"_s && key != u"or-tags"_s && !key.startsWith('_')) {
                        collectedProperties.insert(key, exerciseObject[key]);
                        exerciseObject.remove(key);
                    }
                }
                exerciseObject[u"children"_s] = applyDefinitions(exerciseObject[u"children"_s].toArray(), filteredDefinitions, collectedProperties);
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

void ExerciseCatalogController::filterDefinitions(QJsonArray &definitions,
                                                  QJsonObject &exerciseObject,
                                                  const QString &filterTagsKey,
                                                  DefinitionFilteringMode definitionFilteringMode)
{
    const QJsonArray filterTags = exerciseObject[filterTagsKey].toArray();
    exerciseObject.remove(filterTagsKey);
    for (QJsonArray::Iterator i2 = definitions.begin(); i2 < definitions.end();) {
        bool remove = definitionFilteringMode != DefinitionFilteringMode::AndFiltering;
        const QJsonArray::const_iterator filterTagsEnd = filterTags.constEnd();
        for (QJsonArray::ConstIterator i3 = filterTags.constBegin(); i3 < filterTagsEnd; ++i3) {
            const QJsonArray tagArray = i2->toObject()[u"tags"_s].toArray();
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

QJsonArray ExerciseCatalogController::mergeJsonArrays(QJsonArray oldFile, QJsonArray newFile, QString commonKey, QString mergeKey)
{
    const QJsonArray::const_iterator newFileEnd = newFile.constEnd();
    for (QJsonArray::ConstIterator i1 = newFile.constBegin(); i1 < newFileEnd; ++i1) {
        if (i1->isObject()) {
            QJsonArray::ConstIterator i2;
            const QJsonArray::const_iterator oldFileEnd = oldFile.constEnd();
            for (i2 = oldFile.constBegin(); i2 < oldFileEnd; ++i2) {
                const QJsonObject newFileObject = i1->toObject();
                const QJsonObject oldFileObject = i2->toObject();
                if (i2->isObject() && i1->isObject() && !commonKey.isEmpty() && oldFileObject[commonKey] == newFileObject[commonKey]) {
                    QJsonObject jsonObject = oldFile[i2 - oldFile.constBegin()].toObject();
                    jsonObject[mergeKey] = mergeJsonArrays(oldFileObject[mergeKey].toArray(), newFileObject[mergeKey].toArray(), commonKey, mergeKey);
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
