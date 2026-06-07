// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "instrumentcatalogcontroller.h"

#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QVariantMap>

using namespace Qt::StringLiterals;

namespace Minuet
{
InstrumentCatalogController::InstrumentCatalogController(QObject *parent)
    : QObject(parent)
{
}

QVariantList InstrumentCatalogController::instrumentGroups(const QString &json) const
{
    QVariantList groups;
    for (const QVariant &entry : parseArray(json)) {
        const QVariantMap group = entry.toMap();
        QVariantMap item;
        item[u"id"_s] = group.value(u"id"_s);
        item[u"name"_s] = group.value(u"name"_s);
        groups.push_back(item);
    }
    return groups;
}

QVariantList InstrumentCatalogController::melodicInstruments(const QString &json) const
{
    QVariantList instruments;
    for (const QVariant &entry : parseArray(json)) {
        const QVariantMap instrument = entry.toMap();
        QVariantMap item;
        item[u"group"_s] = instrument.value(u"group"_s);
        item[u"bank"_s] = instrument.value(u"bank"_s);
        item[u"program"_s] = instrument.value(u"program"_s);
        item[u"number"_s] = instrument.value(u"number"_s);
        item[u"name"_s] = instrument.value(u"name"_s);
        item[u"displayName"_s] = instrument.value(u"displayName"_s);
        instruments.push_back(item);
    }
    return instruments;
}

QVariantList InstrumentCatalogController::rhythmInstruments(const QString &json) const
{
    QVariantList instruments;
    for (const QVariant &entry : parseArray(json)) {
        const QVariantMap instrument = entry.toMap();
        QVariantMap item;
        item[u"key"_s] = instrument.value(u"key"_s);
        item[u"number"_s] = instrument.value(u"number"_s);
        item[u"name"_s] = instrument.value(u"name"_s);
        item[u"displayName"_s] = instrument.value(u"displayName"_s);
        instruments.push_back(item);
    }
    return instruments;
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

QVariantList InstrumentCatalogController::parseArray(const QString &json) const
{
    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(json.toUtf8(), &error);
    if (error.error != QJsonParseError::NoError || !document.isArray()) {
        if (!json.isEmpty() && json != u"[]"_s) {
            qWarning() << "Unable to parse instrument catalog:" << error.errorString();
        }
        return {};
    }
    return document.array().toVariantList();
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
