// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_INTERFACEQMLTYPES_H
#define MINUET_INTERFACEQMLTYPES_H

#include <interfaces/imicrophoneinputcontroller.h>
#include <interfaces/isoundcontroller.h>

#include <qqmlregistration.h>

namespace Minuet
{
namespace InterfaceQmlTypes
{
struct ISoundControllerForeign {
    Q_GADGET
    QML_FOREIGN(Minuet::ISoundController)
    QML_NAMED_ELEMENT(ISoundController)
    QML_UNCREATABLE("ISoundController is provided by Core")
};

struct IMicrophoneInputControllerForeign {
    Q_GADGET
    QML_FOREIGN(Minuet::IMicrophoneInputController)
    QML_NAMED_ELEMENT(IMicrophoneInputController)
    QML_UNCREATABLE("IMicrophoneInputController is provided by Core")
};
}
}

#endif
