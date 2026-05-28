// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_INTERFACEQMLTYPES_H
#define MINUET_INTERFACEQMLTYPES_H

#include <interfaces/isoundcontroller.h>

#include <qqmlregistration.h>

namespace Minuet
{
namespace InterfaceQmlTypes
{
struct ISoundController
{
    Q_GADGET
    QML_FOREIGN(Minuet::ISoundController)
    QML_ELEMENT
    QML_UNCREATABLE("ISoundController is provided by Core")
};
}
}

#endif
