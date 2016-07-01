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

#ifndef MINUET_IEXERCISECONTROLLER_H
#define MINUET_IEXERCISECONTROLLER_H

#include "minuetinterfacesexport.h"

#include <QObject>
#include <QJsonArray>

namespace Minuet
{

class MINUETINTERFACES_EXPORT IExerciseController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(quint8 minRootNote MEMBER m_minRootNote)
    Q_PROPERTY(quint8 maxRootNote MEMBER m_maxRootNote)
    Q_PROPERTY(QJsonArray exercises READ exercises)
    Q_PROPERTY(QJsonArray currentExercise MEMBER m_currentExercise)
    Q_PROPERTY(quint8 answerLength MEMBER m_answerLength)
    Q_PROPERTY(QJsonArray selectedOptions MEMBER m_selectedOptions)

public:
    virtual ~IExerciseController() override;

    virtual QJsonArray exercises() const = 0;

public Q_SLOTS:
    virtual void randomlySelectOptions() = 0;

protected:
    explicit IExerciseController(QObject *parent = 0);

    quint8 m_minRootNote;
    quint8 m_maxRootNote;
    QJsonArray m_currentExercise;
    quint8 m_answerLength;
    QJsonArray m_selectedOptions;
};

}

#endif
