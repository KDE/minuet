/****************************************************************************
**
** Copyright (C) 2015 by Sandro S. Andrade <sandroandrade@kde.org>
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

#ifndef MINUET_H
#define MINUET_H

#include <KXmlGuiWindow>

#include <QtCore/QJsonObject>
#include <QtCore/QLoggingCategory>

#include "ui_settingsbase.h"
#include "minuetsettings.h"

class QQuickView;

class MidiSequencer;
class ExerciseController;

Q_DECLARE_LOGGING_CATEGORY(MINUET)

/**
 * This class serves as the main window for Minuet.  It handles the
 * menus, toolbars and status bars.
 *
 * @short Main window class
 * @author Sandro S. Andrade <sandroandrade@kde.org>
 * @version 0.1
 */
class Minuet : public KXmlGuiWindow
{
    Q_OBJECT
public:
    /**
     * Default Constructor
     */
    Minuet();

    /**
     * Default Destructor
     */
    virtual ~Minuet();
    
private:
    void configureExercises();
    QJsonArray mergeExercises(QJsonArray exercises, QJsonArray newExercises);

private slots:
    /**
     * Create a new window
     */
    void fileOpen();

    /**
     * Open the settings dialog
     */
    void settingsConfigure();

private:
    // this is the name of the root widget inside our Ui file
    // you can rename it in designer and then change it here
    Ui::settingsBase settingsBase;
    MidiSequencer *m_midiSequencer;
    ExerciseController *m_exerciseController;
    QQuickView *m_quickView;
    QJsonObject m_exercises;
};

#endif // MINUET_H