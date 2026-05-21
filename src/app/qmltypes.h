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

#ifndef MINUET_QMLTYPES_H
#define MINUET_QMLTYPES_H

#include <interfaces/iexercisecontroller.h>
#include <interfaces/iplugincontroller.h>
#include <interfaces/isoundcontroller.h>
#include <interfaces/iuicontroller.h>

#include <qqmlregistration.h>

struct IExerciseControllerForeign
{
    Q_GADGET
    QML_FOREIGN(Minuet::IExerciseController)
    QML_NAMED_ELEMENT(IExerciseController)
    QML_UNCREATABLE("IExerciseController is provided by Core")
};

struct IPluginControllerForeign
{
    Q_GADGET
    QML_FOREIGN(Minuet::IPluginController)
    QML_NAMED_ELEMENT(IPluginController)
    QML_UNCREATABLE("IPluginController is provided by Core")
};

struct ISoundControllerForeign
{
    Q_GADGET
    QML_FOREIGN(Minuet::ISoundController)
    QML_NAMED_ELEMENT(ISoundController)
    QML_UNCREATABLE("ISoundController is provided by Core")
};

struct IUiControllerForeign
{
    Q_GADGET
    QML_FOREIGN(Minuet::IUiController)
    QML_NAMED_ELEMENT(IUiController)
    QML_UNCREATABLE("IUiController is provided by Core")
};

#endif
