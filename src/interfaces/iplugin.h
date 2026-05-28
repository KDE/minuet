// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_IPLUGIN_H
#define MINUET_IPLUGIN_H

#include <interfaces/minuetinterfacesexport.h>

#include <QObject>
#include <qqmlregistration.h>

namespace Minuet
{
class MINUETINTERFACES_EXPORT IPlugin : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("IPlugin is provided by Core")

public:
    ~IPlugin() override = default;

protected:
    explicit IPlugin(QObject *parent = nullptr);
};

}

Q_DECLARE_INTERFACE(Minuet::IPlugin, "org.kde.minuet.IPlugin")

#endif
