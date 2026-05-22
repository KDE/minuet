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

#ifndef MINUET_INTERFACEQMLTYPES_H
#define MINUET_INTERFACEQMLTYPES_H

#include <interfaces/icore.h>
#include <interfaces/iexercisecontroller.h>
#include <interfaces/iplugin.h>
#include <interfaces/iplugincontroller.h>
#include <interfaces/isettingscontroller.h>
#include <interfaces/isoundcontroller.h>
#include <interfaces/iuicontroller.h>

#include <qqmlregistration.h>

namespace Minuet
{
namespace InterfaceQmlTypes
{
struct ICore
{
    Q_GADGET
    QML_FOREIGN(Minuet::ICore)
    QML_NAMED_ELEMENT(ICore)
    QML_UNCREATABLE("ICore is provided by Core")
};

struct IExerciseController
{
    Q_GADGET
    QML_FOREIGN(Minuet::IExerciseController)
    QML_NAMED_ELEMENT(IExerciseController)
    QML_UNCREATABLE("IExerciseController is provided by Core")
};

struct IPlugin
{
    Q_GADGET
    QML_FOREIGN(Minuet::IPlugin)
    QML_NAMED_ELEMENT(IPlugin)
    QML_UNCREATABLE("IPlugin is provided by Core")
};

struct IPluginController
{
    Q_GADGET
    QML_FOREIGN(Minuet::IPluginController)
    QML_NAMED_ELEMENT(IPluginController)
    QML_UNCREATABLE("IPluginController is provided by Core")
};

struct ISettingsController
{
    Q_GADGET
    QML_FOREIGN(Minuet::ISettingsController)
    QML_NAMED_ELEMENT(ISettingsController)
    QML_UNCREATABLE("ISettingsController is provided by Core")
};

struct ISoundController
{
    Q_GADGET
    QML_FOREIGN(Minuet::ISoundController)
    QML_NAMED_ELEMENT(ISoundController)
    QML_UNCREATABLE("ISoundController is provided by Core")
};

struct IUiController
{
    Q_GADGET
    QML_FOREIGN(Minuet::IUiController)
    QML_NAMED_ELEMENT(IUiController)
    QML_UNCREATABLE("IUiController is provided by Core")
};
}
}

#endif
