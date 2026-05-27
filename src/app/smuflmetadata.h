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

#ifndef MINUET_SMUFLMETADATA_H
#define MINUET_SMUFLMETADATA_H

#include <QJsonObject>
#include <QObject>
#include <QVariantList>
#include <qqmlregistration.h>

namespace Minuet
{
class SmuflMetadata : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool ready READ ready CONSTANT)

public:
    explicit SmuflMetadata(QObject *parent = nullptr);

    bool ready() const;

    Q_INVOKABLE QVariantList anchor(const QString &glyphName, const QString &anchorName) const;
    Q_INVOKABLE double engravingDefault(const QString &name) const;
    Q_INVOKABLE double glyphBBoxValue(const QString &glyphName, const QString &cornerName, int axis) const;

private:
    bool hasRequiredData() const;

    QJsonObject m_data;
    bool m_ready = false;
};
}

#endif
