// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

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
    QML_UNCREATABLE("SmuflMetadata is provided by SheetMusicController")
    Q_PROPERTY(bool ready READ ready CONSTANT)

public:
    bool ready() const;

    Q_INVOKABLE QVariantList anchor(const QString &glyphName, const QString &anchorName) const;
    Q_INVOKABLE double engravingDefault(const QString &name) const;
    Q_INVOKABLE double glyphBBoxValue(const QString &glyphName, const QString &cornerName, int axis) const;

private:
    friend class SheetMusicController;

    explicit SmuflMetadata(QObject *parent = nullptr);

    bool hasRequiredData() const;

    QJsonObject m_data;
    bool m_ready = false;
};
}

#endif
