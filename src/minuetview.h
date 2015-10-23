/*
Copyright (C) %{CURRENT_YEAR} by %{AUTHOR} <%{EMAIL}>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License or (at your option) version 3 or any later version
accepted by the membership of KDE e.V. (or its successor approved
by the membership of KDE e.V.), which shall act as a proxy 
defined in Section 14 of version 3 of the license.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef MINUETVIEW_H
#define MINUETVIEW_H

#include <QLoggingCategory>
Q_DECLARE_LOGGING_CATEGORY(MINUET)

#include "ui_minuetViewBase.h"

/**
 * This class serves as the main window for minuet.  It handles the
 * menus, toolbars and status bars.
 *
 * @short Main window class
 * @author Your Name <mail@example.com>
 * @version 0.1
 */
class minuetView : public QWidget
{
    Q_OBJECT
public:
    /**
     * Default Constructor
     */
    minuetView(QWidget *parent);

    /**
     * Default Destructor
     */
    virtual ~minuetView();

private slots:
    void slotSettingsChanged();
    void slotSwitchColors();

signals:
    /**
     * Use this signal to change the content of the statusbar
     */
    void signalChangeStatusbar(const QString& text);

    /**
     * Use this signal to change the content of the caption
     */
    void signalChangeCaption(const QString& text);

private:
    // this is the name of the root widget inside our Ui file
    // you can rename it in designer and then change it here
    Ui::minuetViewBase m_ui;
};

#endif // _MINUET_H_
