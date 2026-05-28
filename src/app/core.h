// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_CORE_H
#define MINUET_CORE_H

#include <interfaces/isoundcontroller.h>

#include <QObject>
#include <qqmlregistration.h>

Q_MOC_INCLUDE("exercisecatalogcontroller.h")
Q_MOC_INCLUDE("exercisesessioncontroller.h")
Q_MOC_INCLUDE("instrumentcatalogcontroller.h")
Q_MOC_INCLUDE("pianokeyboardcontroller.h")
Q_MOC_INCLUDE("settingscontroller.h")
Q_MOC_INCLUDE("sheetmusiccontroller.h")

class QJSEngine;
class QQmlEngine;

namespace Minuet
{
class ExerciseCatalogController;
class ExerciseSessionController;
class InstrumentCatalogController;
class PianoKeyboardController;
class PluginController;
class SettingsController;
class SheetMusicController;
class UiController;

class Core : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(Minuet::ISoundController *soundController READ soundController NOTIFY soundControllerChanged)
    Q_PROPERTY(Minuet::SettingsController *settingsController READ settingsController CONSTANT)
    Q_PROPERTY(Minuet::SheetMusicController *sheetMusicController READ sheetMusicController CONSTANT)
    Q_PROPERTY(Minuet::ExerciseCatalogController *exerciseCatalogController READ exerciseCatalogController CONSTANT)
    Q_PROPERTY(Minuet::InstrumentCatalogController *instrumentCatalogController READ instrumentCatalogController CONSTANT)
    Q_PROPERTY(Minuet::PianoKeyboardController *pianoKeyboardController READ pianoKeyboardController CONSTANT)
    Q_PROPERTY(Minuet::ExerciseSessionController *exerciseSessionController READ exerciseSessionController CONSTANT)

public:
    ~Core() override;

    static bool initialize();
    static Core *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static Core *self();

    ISoundController *soundController();
    SettingsController *settingsController();
    SheetMusicController *sheetMusicController();
    ExerciseCatalogController *exerciseCatalogController();
    InstrumentCatalogController *instrumentCatalogController();
    PianoKeyboardController *pianoKeyboardController();
    ExerciseSessionController *exerciseSessionController();

    void setSoundController(ISoundController *soundController);

Q_SIGNALS:
    void soundControllerChanged(Minuet::ISoundController *newSoundController);

private:
    explicit Core(QObject *parent = nullptr);

    static Core *m_self;

    ISoundController *m_soundController;
    SettingsController *m_settingsController;
    SheetMusicController *m_sheetMusicController;
    ExerciseCatalogController *m_exerciseCatalogController;
    InstrumentCatalogController *m_instrumentCatalogController;
    PianoKeyboardController *m_pianoKeyboardController;
    ExerciseSessionController *m_exerciseSessionController;
    PluginController *m_pluginController;
    UiController *m_uiController;
};

}

#endif
