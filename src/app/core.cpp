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

#include "exercisecatalogcontroller.h"
#include "exercisesessioncontroller.h"
#include "instrumentcatalogcontroller.h"
#include "pianokeyboardcontroller.h"
#include "plugincontroller.h"
#include "settingscontroller.h"
#include "sheetmusiccontroller.h"
#include "uicontroller.h"

namespace Minuet
{
Core *Core::m_self = nullptr;

Core::~Core()
{
    m_self = nullptr;
}

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

Core *Core::self()
{
    return m_self;
}

ISoundController *Core::soundController()
{
    return m_soundController;
}

SettingsController *Core::settingsController()
{
    return m_settingsController;
}

SheetMusicController *Core::sheetMusicController()
{
    return m_sheetMusicController;
}

ExerciseCatalogController *Core::exerciseCatalogController()
{
    return m_exerciseCatalogController;
}

InstrumentCatalogController *Core::instrumentCatalogController()
{
    return m_instrumentCatalogController;
}

PianoKeyboardController *Core::pianoKeyboardController()
{
    return m_pianoKeyboardController;
}

ExerciseSessionController *Core::exerciseSessionController()
{
    return m_exerciseSessionController;
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

Core::Core(QObject *parent) : QObject(parent), m_soundController(nullptr)
{
    Q_ASSERT(m_self == nullptr);
    m_self = this;

    m_settingsController = new SettingsController(this);
    connect(m_settingsController, &SettingsController::volumeChanged, this, [this](int volume) {
        if (m_soundController) {
            m_soundController->setVolume(volume);
        }
    });
    connect(m_settingsController, &SettingsController::pitchChanged, this, [this](int pitch) {
        if (m_soundController) {
            m_soundController->setPitch(pitch);
        }
    });
    connect(m_settingsController, &SettingsController::tempoChanged, this, [this](int tempo) {
        if (m_soundController) {
            m_soundController->setTempo(tempo);
        }
    });
    connect(m_settingsController, &SettingsController::instrumentChanged, this, [this](int instrument) {
        if (m_soundController) {
            m_soundController->setInstrument(instrument);
        }
    });
    connect(m_settingsController, &SettingsController::rhythmInstrumentChanged, this, [this](int rhythmInstrument) {
        if (m_soundController) {
            m_soundController->setRhythmInstrument(rhythmInstrument);
        }
    });

    m_sheetMusicController = new SheetMusicController(this);
    m_exerciseCatalogController = new ExerciseCatalogController(this);
    if (!m_exerciseCatalogController->initialize()) {
        qCritical() << m_exerciseCatalogController->errorString();
        exit(-2);
    }
    m_instrumentCatalogController = new InstrumentCatalogController(this);
    m_pianoKeyboardController = new PianoKeyboardController(this);
    m_exerciseSessionController = new ExerciseSessionController(this);

    m_pluginController = new PluginController(this);
    if (!m_pluginController->initialize(this)) {
        qCritical() << m_pluginController->errorString();
        exit(-1);
    }

    m_uiController = new UiController(this);
    if (!m_uiController->initialize(this)) {
        qCritical() << m_uiController->errorString();
        exit(-3);
    }
}

}

#include "moc_core.cpp"
