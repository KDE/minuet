// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

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
    Q_INVOKABLE QVariantList melodicInstrumentsForGroup(const QVariantList &instruments, int group) const;
    Q_INVOKABLE int melodicGroupForInstrument(const QVariantList &groups, const QVariantList &instruments, int instrument) const;
    Q_INVOKABLE int melodicGroupIndex(const QVariantList &groups, int group) const;
    Q_INVOKABLE int melodicInstrumentIndex(const QVariantList &instruments, int instrument) const;
    Q_INVOKABLE int rhythmInstrumentIndex(const QVariantList &instruments, int instrument) const;

private:
    friend class Core;

    explicit InstrumentCatalogController(QObject *parent = nullptr);

    int indexByRole(const QVariantList &items, const QString &role, int value) const;
};
}

#endif
