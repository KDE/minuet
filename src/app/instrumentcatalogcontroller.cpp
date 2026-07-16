// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "instrumentcatalogcontroller.h"

#include <QVariantMap>

using namespace Qt::StringLiterals;

namespace Minuet
{
InstrumentCatalogController::InstrumentCatalogController(QObject *parent)
    : QObject(parent)
{
}

QVariantList InstrumentCatalogController::melodicInstrumentsForGroup(const QVariantList &instruments, int group) const
{
    QVariantList filteredInstruments;
    for (const QVariant &entry : instruments) {
        const QVariantMap instrument = entry.toMap();
        if (instrument.value(u"group"_s).toInt() == group) {
            filteredInstruments.push_back(instrument);
        }
    }
    return filteredInstruments;
}

int InstrumentCatalogController::melodicGroupForInstrument(const QVariantList &groups, const QVariantList &instruments, int instrument) const
{
    for (const QVariant &entry : instruments) {
        const QVariantMap item = entry.toMap();
        if (item.value(u"program"_s).toInt() == instrument) {
            return item.value(u"group"_s).toInt();
        }
    }
    return groups.isEmpty() ? -1 : groups.constFirst().toMap().value(u"id"_s).toInt();
}

int InstrumentCatalogController::melodicGroupIndex(const QVariantList &groups, int group) const
{
    return indexByRole(groups, u"id"_s, group);
}

int InstrumentCatalogController::melodicInstrumentIndex(const QVariantList &instruments, int instrument) const
{
    return indexByRole(instruments, u"program"_s, instrument);
}

int InstrumentCatalogController::rhythmInstrumentIndex(const QVariantList &instruments, int instrument) const
{
    return indexByRole(instruments, u"key"_s, instrument);
}

int InstrumentCatalogController::indexByRole(const QVariantList &items, const QString &role, int value) const
{
    for (int i = 0; i < items.size(); ++i) {
        if (items.at(i).toMap().value(role).toInt() == value) {
            return i;
        }
    }
    return -1;
}
}
