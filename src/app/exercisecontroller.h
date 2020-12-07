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

#ifndef MINUET_EXERCISECONTROLLER_H
#define MINUET_EXERCISECONTROLLER_H

#include <interfaces/iexercisecontroller.h>

#include <QJsonObject>
#include <QStringList>

namespace Minuet
{
class Core;

class ExerciseController : public IExerciseController
{
    Q_OBJECT

public:
    explicit ExerciseController(QObject *parent = 0);
    virtual ~ExerciseController() = default;

    bool initialize(Core *core);
    virtual QString errorString() const override;

    Q_INVOKABLE unsigned int chosenRootNote() const;

    virtual QJsonArray exercises() const override;

public Q_SLOTS:
    virtual void randomlySelectExerciseOptions() override;

private:
    bool mergeJsonFiles(const QString directoryName, QJsonObject &targetObject,
                        bool applyDefinitionsFlag = false, QString commonKey = nullptr,
                        QString mergeKey = nullptr);
    QJsonArray applyDefinitions(QJsonArray exercises, QJsonArray definitions,
                                QJsonObject collectedProperties = QJsonObject());
    enum DefinitionFilteringMode { AndFiltering = 0, OrFiltering };
    static void filterDefinitions(QJsonArray &definitions, QJsonObject &exerciseObject,
                                  const QString &filterTagsKey,
                                  DefinitionFilteringMode definitionFilteringMode);
    QJsonArray mergeJsonArrays(QJsonArray oldFile, QJsonArray newFile, QString commonKey = nullptr,
                               QString mergeKey = nullptr);

    QJsonObject m_exercises;
    QJsonObject m_definitions;
    unsigned int m_chosenRootNote;
    QString m_errorString;
};

}

#endif  // MINUET_EXERCISECONTROLLER_H
