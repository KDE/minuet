// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "core.h"

#include "clappingexercisecontroller.h"

#include <QCoreApplication>
#include <QQmlEngine>

#include "exercisecatalogcontroller.h"
#include "exercisesessioncontroller.h"
#include "instrumentcatalogcontroller.h"
#include "pianokeyboardcontroller.h"
#include "plugincontroller.h"
#include "settingscontroller.h"
#include "sheetmusiccontroller.h"
#include "singingexercisecontroller.h"
#include "uicontroller.h"

namespace Minuet
{
Core *Core::m_self = nullptr;

Core::~Core()
{
    shutdownControllers();

    // Destroy the QML object tree while all of the controllers it references
    // are still alive. This also guarantees that Qt Quick's worker threads are
    // stopped before QGuiApplication starts tearing down its infrastructure.
    delete m_uiController;
    m_uiController = nullptr;

    m_self = nullptr;
}

bool Core::initialize()
{
    if (m_self) {
        return true;
    }

    m_self = new Core(QCoreApplication::instance());

    return true;
}

void Core::shutdown()
{
    delete m_self;
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

ISoundController *Core::soundController() const
{
    return m_soundController;
}

IMicrophoneInputController *Core::microphoneInputController() const
{
    return m_microphoneInputController;
}

SettingsController *Core::settingsController() const
{
    return m_settingsController;
}

SheetMusicController *Core::sheetMusicController() const
{
    return m_sheetMusicController;
}

ExerciseCatalogController *Core::exerciseCatalogController() const
{
    return m_exerciseCatalogController;
}

ClappingExerciseController *Core::clappingExerciseController() const
{
    return m_clappingExerciseController;
}

InstrumentCatalogController *Core::instrumentCatalogController() const
{
    return m_instrumentCatalogController;
}

PianoKeyboardController *Core::pianoKeyboardController() const
{
    return m_pianoKeyboardController;
}

ExerciseSessionController *Core::exerciseSessionController() const
{
    return m_exerciseSessionController;
}

SingingExerciseController *Core::singingExerciseController() const
{
    return m_singingExerciseController;
}

void Core::setSoundController(ISoundController *soundController)
{
    if (m_soundController != soundController) {
        m_soundController = soundController;
        emit soundControllerChanged(m_soundController);
        if (m_soundController) {
            m_soundController->setVolume(m_settingsController->volume());
            m_soundController->setPitch(m_settingsController->pitch());
            m_soundController->setRhythmCountInBeats(ISoundController::RhythmExerciseCountInBeats);
            m_soundController->setInstrument(m_settingsController->instrument());
            m_soundController->setRhythmInstrument(m_settingsController->rhythmInstrument());
            applyActiveExerciseAudioConfiguration();
        }
    }
}

void Core::setMicrophoneInputController(IMicrophoneInputController *microphoneInputController)
{
    if (m_microphoneInputController == microphoneInputController) {
        return;
    }
    m_microphoneInputController = microphoneInputController;
    emit microphoneInputControllerChanged(m_microphoneInputController);
    if (m_microphoneInputController) {
        m_microphoneInputController->setInputDeviceId(m_settingsController->microphoneInputDeviceId());
    }
}

void Core::stopExerciseActivity()
{
    if (m_soundController) {
        m_soundController->stop();
    }
    if (m_microphoneInputController) {
        m_microphoneInputController->stop();
    }
    if (m_exerciseSessionController->isTest()) {
        m_exerciseSessionController->stopTest();
    }
}

void Core::shutdownControllers()
{
    IMicrophoneInputController *microphoneInputController = m_microphoneInputController;
    ISoundController *soundController = m_soundController;

    setMicrophoneInputController(nullptr);
    setSoundController(nullptr);

    if (microphoneInputController) {
        microphoneInputController->stop();
    }
    if (soundController) {
        soundController->stop();
    }
}

void Core::applyActiveExerciseAudioConfiguration()
{
    if (!m_soundController || !m_settingsController || !m_exerciseSessionController) {
        return;
    }

    const QVariantMap activeExercise = m_exerciseSessionController->activeExercise();
    m_soundController->setTempo(m_settingsController->tempoForExercise(activeExercise));
    m_soundController->setRhythmCountInSubdivisions(m_settingsController->subdivisionsForExercise(activeExercise));
}

Core::Core(QObject *parent)
    : QObject(parent)
    , m_soundController(nullptr)
    , m_microphoneInputController(nullptr)
{
    Q_ASSERT(m_self == nullptr);
    m_self = this;

    if (QCoreApplication *application = QCoreApplication::instance()) {
        connect(application, &QCoreApplication::aboutToQuit, this, &Core::shutdownControllers);
    }

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
    connect(m_settingsController, &SettingsController::microphoneInputDeviceIdChanged, this, [this](const QString &deviceId) {
        if (m_microphoneInputController) {
            m_microphoneInputController->setInputDeviceId(deviceId);
        }
    });

    m_sheetMusicController = new SheetMusicController(this);
    m_clappingExerciseController = new ClappingExerciseController(this);
    m_singingExerciseController = new SingingExerciseController(this);
    m_exerciseCatalogController = new ExerciseCatalogController(this);
    if (!m_exerciseCatalogController->initialize()) {
        qCritical() << m_exerciseCatalogController->errorString();
        exit(-2);
    }
    m_instrumentCatalogController = new InstrumentCatalogController(this);
    m_pianoKeyboardController = new PianoKeyboardController(this);
    m_exerciseSessionController = new ExerciseSessionController(this);
    connect(m_exerciseSessionController, &ExerciseSessionController::activeExerciseChanged, this, &Core::applyActiveExerciseAudioConfiguration);
    connect(m_settingsController, &SettingsController::exerciseSpeedChanged, this, &Core::applyActiveExerciseAudioConfiguration);
    connect(m_settingsController, &SettingsController::rhythmTempoChanged, this, &Core::applyActiveExerciseAudioConfiguration);

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
