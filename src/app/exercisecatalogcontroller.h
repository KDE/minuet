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

#ifndef MINUET_EXERCISECATALOGCONTROLLER_H
#define MINUET_EXERCISECATALOGCONTROLLER_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
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

    bool mergeJsonFiles(const QString directoryName, QJsonObject &targetObject,
                        bool applyDefinitionsFlag = false, QString commonKey = nullptr,
                        QString mergeKey = nullptr);
    QJsonArray applyDefinitions(QJsonArray exercises, QJsonArray definitions,
                                QJsonObject collectedProperties = QJsonObject());
    enum class DefinitionFilteringMode { AndFiltering, OrFiltering };
    static void filterDefinitions(QJsonArray &definitions, QJsonObject &exerciseObject,
                                  const QString &filterTagsKey,
                                  DefinitionFilteringMode definitionFilteringMode);
    QJsonArray mergeJsonArrays(QJsonArray oldFile, QJsonArray newFile, QString commonKey = nullptr,
                               QString mergeKey = nullptr);
    void collectExercise(const QVariantMap &exercise, const QString &inheritedIconName, QVariantList &collectedExercises) const;
    QString resolvedIconName(const QVariantMap &exercise, const QString &inheritedIconName, const QString &fallbackIconName) const;

    QJsonObject m_exercises;
    QJsonObject m_definitions;
    QString m_errorString;
};
}

#endif
