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

#include <QQmlEngine>

#include "exercisecontroller.h"
#include "plugincontroller.h"
#include "settingscontroller.h"
#include "uicontroller.h"

#include <interfaces/isoundcontroller.h>

namespace Minuet
{
bool Core::initialize()
{
    if (m_self) {
        return true;
    }

    m_self = new Core;

    return true;
}

Core *Core::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

    initialize();
    auto *core = static_cast<Core *>(m_self);
    QQmlEngine::setObjectOwnership(core, QQmlEngine::CppOwnership);
    return core;
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

ISettingsController *Core::settingsController()
{
    return m_settingsController;
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
        if (m_soundController) {
            m_soundController->setVolume(m_settingsController->volume());
            m_soundController->setPitch(m_settingsController->pitch());
            m_soundController->setTempo(m_settingsController->tempo());
            m_soundController->setInstrument(m_settingsController->instrument());
            m_soundController->setRhythmInstrument(m_settingsController->rhythmInstrument());
        }
    }
}

Core::Core(QObject *parent) : ICore(parent), m_soundController(nullptr)
{
    m_settingsController = new SettingsController(this);
    connect(m_settingsController, &ISettingsController::volumeChanged, this, [this](int volume) {
        if (m_soundController) {
            m_soundController->setVolume(volume);
        }
    });
    connect(m_settingsController, &ISettingsController::pitchChanged, this, [this](int pitch) {
        if (m_soundController) {
            m_soundController->setPitch(pitch);
        }
    });
    connect(m_settingsController, &ISettingsController::tempoChanged, this, [this](int tempo) {
        if (m_soundController) {
            m_soundController->setTempo(tempo);
        }
    });
    connect(m_settingsController, &ISettingsController::instrumentChanged, this, [this](int instrument) {
        if (m_soundController) {
            m_soundController->setInstrument(instrument);
        }
    });
    connect(m_settingsController, &ISettingsController::rhythmInstrumentChanged, this, [this](int rhythmInstrument) {
        if (m_soundController) {
            m_soundController->setRhythmInstrument(rhythmInstrument);
        }
    });

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

#include "moc_core.cpp"
