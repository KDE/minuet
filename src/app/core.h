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
