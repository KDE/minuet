// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_CORE_H
#define MINUET_CORE_H

#include <interfaces/isoundcontroller.h>
#include <interfaces/imicrophoneinputcontroller.h>

#include <QObject>
#include <qqmlregistration.h>

Q_MOC_INCLUDE("exercisecatalogcontroller.h")
Q_MOC_INCLUDE("clappingexercisecontroller.h")
Q_MOC_INCLUDE("exercisesessioncontroller.h")
Q_MOC_INCLUDE("instrumentcatalogcontroller.h")
Q_MOC_INCLUDE("pianokeyboardcontroller.h")
Q_MOC_INCLUDE("settingscontroller.h")
Q_MOC_INCLUDE("sheetmusiccontroller.h")
Q_MOC_INCLUDE("singingexercisecontroller.h")

class QJSEngine;
class QQmlEngine;

namespace Minuet
{
class ExerciseCatalogController;
class ClappingExerciseController;
class ExerciseSessionController;
class InstrumentCatalogController;
class PianoKeyboardController;
class PluginController;
class SettingsController;
class SheetMusicController;
class SingingExerciseController;
class UiController;

class Core : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(Minuet::ISoundController *soundController READ soundController NOTIFY soundControllerChanged)
    Q_PROPERTY(Minuet::IMicrophoneInputController *microphoneInputController READ microphoneInputController NOTIFY microphoneInputControllerChanged)
    Q_PROPERTY(Minuet::SettingsController *settingsController READ settingsController CONSTANT)
    Q_PROPERTY(Minuet::SheetMusicController *sheetMusicController READ sheetMusicController CONSTANT)
    Q_PROPERTY(Minuet::ExerciseCatalogController *exerciseCatalogController READ exerciseCatalogController CONSTANT)
    Q_PROPERTY(Minuet::ClappingExerciseController *clappingExerciseController READ clappingExerciseController CONSTANT)
    Q_PROPERTY(Minuet::InstrumentCatalogController *instrumentCatalogController READ instrumentCatalogController CONSTANT)
    Q_PROPERTY(Minuet::PianoKeyboardController *pianoKeyboardController READ pianoKeyboardController CONSTANT)
    Q_PROPERTY(Minuet::ExerciseSessionController *exerciseSessionController READ exerciseSessionController CONSTANT)
    Q_PROPERTY(Minuet::SingingExerciseController *singingExerciseController READ singingExerciseController CONSTANT)

public:
    ~Core() override;

    static bool initialize();
    static void shutdown();
    static Core *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static Core *self();

    ISoundController *soundController() const;
    IMicrophoneInputController *microphoneInputController() const;
    SettingsController *settingsController() const;
    SheetMusicController *sheetMusicController() const;
    ExerciseCatalogController *exerciseCatalogController() const;
    ClappingExerciseController *clappingExerciseController() const;
    InstrumentCatalogController *instrumentCatalogController() const;
    PianoKeyboardController *pianoKeyboardController() const;
    ExerciseSessionController *exerciseSessionController() const;
    SingingExerciseController *singingExerciseController() const;

    void setSoundController(ISoundController *soundController);
    void setMicrophoneInputController(IMicrophoneInputController *microphoneInputController);
    Q_INVOKABLE void stopExerciseActivity();

Q_SIGNALS:
    void soundControllerChanged(Minuet::ISoundController *newSoundController);
    void microphoneInputControllerChanged(Minuet::IMicrophoneInputController *newMicrophoneInputController);

private:
    explicit Core(QObject *parent = nullptr);
    void applyActiveExerciseAudioConfiguration();
    void shutdownControllers();

    static Core *m_self;

    ISoundController *m_soundController;
    IMicrophoneInputController *m_microphoneInputController;
    SettingsController *m_settingsController;
    SheetMusicController *m_sheetMusicController;
    ExerciseCatalogController *m_exerciseCatalogController;
    ClappingExerciseController *m_clappingExerciseController;
    InstrumentCatalogController *m_instrumentCatalogController;
    PianoKeyboardController *m_pianoKeyboardController;
    ExerciseSessionController *m_exerciseSessionController;
    SingingExerciseController *m_singingExerciseController;
    PluginController *m_pluginController;
    UiController *m_uiController;
};

}

#endif
