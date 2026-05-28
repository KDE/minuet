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

#ifndef MINUET_INSTRUMENTCATALOGCONTROLLER_H
#define MINUET_INSTRUMENTCATALOGCONTROLLER_H

#include <QObject>
#include <QVariantList>
#include <qqmlregistration.h>

namespace Minuet
{
class InstrumentCatalogController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("InstrumentCatalogController is provided by Core")

public:
    Q_INVOKABLE QVariantList instrumentGroups(const QString &json) const;
    Q_INVOKABLE QVariantList melodicInstruments(const QString &json) const;
    Q_INVOKABLE QVariantList rhythmInstruments(const QString &json) const;
    Q_INVOKABLE QVariantList melodicInstrumentsForGroup(const QVariantList &instruments, int group) const;
    Q_INVOKABLE int melodicGroupForInstrument(const QVariantList &groups, const QVariantList &instruments, int instrument) const;
    Q_INVOKABLE int melodicGroupIndex(const QVariantList &groups, int group) const;
    Q_INVOKABLE int melodicInstrumentIndex(const QVariantList &instruments, int instrument) const;
    Q_INVOKABLE int rhythmInstrumentIndex(const QVariantList &instruments, int instrument) const;

private:
    friend class Core;

    explicit InstrumentCatalogController(QObject *parent = nullptr);

    QVariantList parseArray(const QString &json) const;
    int indexByRole(const QVariantList &items, const QString &role, int value) const;
};
}

#endif
