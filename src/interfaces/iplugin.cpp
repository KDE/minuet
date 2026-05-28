// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "iplugin.h"

namespace Minuet
{
IPlugin::IPlugin(QObject *parent) : QObject(parent) {}

}

#include "moc_iplugin.cpp"
