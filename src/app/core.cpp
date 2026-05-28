// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

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
