// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_EXERCISECATALOGCONTROLLER_H
#define MINUET_EXERCISECATALOGCONTROLLER_H

#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace Minuet
{
class ExerciseCatalogController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("ExerciseCatalogController is provided by Core")
    Q_PROPERTY(QJsonArray exercises READ exercises CONSTANT)

public:
    bool initialize();
    QString errorString() const;
    QJsonArray exercises() const;

    Q_INVOKABLE QString iconNameForExercise(const QVariantMap &exercise, const QString &inheritedIconName) const;
    Q_INVOKABLE QString actionIconNameForExercise(const QVariantMap &exercise, const QString &inheritedIconName) const;
    Q_INVOKABLE QVariantList collectExercises(const QVariantList &exercises, const QString &inheritedIconName) const;
    Q_INVOKABLE QString exerciseDescription(const QVariantMap &exercise) const;
    Q_INVOKABLE QString normalizedText(const QString &text) const;
    Q_INVOKABLE bool actionMatches(const QString &actionText, const QString &searchText) const;
    Q_INVOKABLE bool exerciseMatchesSearch(const QVariantMap &exercise, const QString &searchText, const QString &inheritedIconName) const;

private:
    friend class Core;

    explicit ExerciseCatalogController(QObject *parent = nullptr);

    bool mergeJsonFiles(const QString directoryName,
                        QJsonObject &targetObject,
                        bool applyDefinitionsFlag = false,
                        QString commonKey = nullptr,
                        QString mergeKey = nullptr);
    QJsonArray applyDefinitions(QJsonArray exercises, QJsonArray definitions, QJsonObject collectedProperties = QJsonObject());
    enum class DefinitionFilteringMode {
        AndFiltering,
        OrFiltering
    };
    static void
    filterDefinitions(QJsonArray &definitions, QJsonObject &exerciseObject, const QString &filterTagsKey, DefinitionFilteringMode definitionFilteringMode);
    QJsonArray mergeJsonArrays(QJsonArray oldFile, QJsonArray newFile, QString commonKey = nullptr, QString mergeKey = nullptr);
    void collectExercise(const QVariantMap &exercise, const QString &inheritedIconName, QVariantList &collectedExercises) const;
    QString resolvedIconName(const QVariantMap &exercise, const QString &inheritedIconName, const QString &fallbackIconName) const;

    QJsonObject m_exercises;
    QJsonObject m_definitions;
    QString m_errorString;
};
}

#endif
