/****************************************************************************
**
** Copyright (C) 2016 by Sandro S. Andrade <sandroandrade@kde.org>
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

#include "core.h"

#include <qqml.h>

#include "exercisecontroller.h"
#include "plugincontroller.h"
#include "uicontroller.h"

#include <interfaces/isoundcontroller.h>

namespace Minuet
{
bool Core::initialize()
{
    if (m_self) {
        return true;
    }

    qRegisterMetaType<Minuet::ISoundController::State>("State");
    qmlRegisterInterface<Minuet::ISoundController>("ISoundController");
    qmlRegisterUncreatableType<Minuet::ISoundController>(
        "org.kde.minuet.isoundcontroller", 1, 0, "ISoundController",
        QStringLiteral("ISoundController cannot be instantiated"));

    m_self = new Core;

    return true;
}

IPluginController *Core::pluginController()
{
    return m_pluginController;
}

ISoundController *Core::soundController()
{
    return m_soundController;
}

IExerciseController *Core::exerciseController()
{
    return m_exerciseController;
}

IUiController *Core::uiController()
{
    return m_uiController;
}

void Core::setSoundController(ISoundController *soundController)
{
    if (m_soundController != soundController) {
        m_soundController = soundController;
        emit soundControllerChanged(m_soundController);
    }
}

Core::Core(QObject *parent) : ICore(parent), m_soundController(nullptr)
{
    m_pluginController = new PluginController(this);
    if (!((PluginController *)m_pluginController)->initialize(this)) {
        qCritical() << m_pluginController->errorString();
        exit(-1);
    }

    m_exerciseController = new ExerciseController(this);
    if (!((ExerciseController *)m_exerciseController)->initialize(this)) {
        qCritical() << m_exerciseController->errorString();
        exit(-2);
    }

    m_uiController = new UiController(this);
    if (!((UiController *)m_uiController)->initialize(this)) {
        qCritical() << m_uiController->errorString();
        exit(-3);
    }
}

}
