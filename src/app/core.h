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

#include <interfaces/icore.h>

namespace Minuet
{
class Core : public ICore
{
    Q_OBJECT

public:
    virtual ~Core() override = default;

    static bool initialize();

    virtual IPluginController *pluginController() override;
    virtual ISoundController *soundController() override;
    virtual IExerciseController *exerciseController() override;
    virtual IUiController *uiController() override;

    void setSoundController(ISoundController *soundController);

private:
    explicit Core(QObject *parent = 0);

    IPluginController *m_pluginController;
    ISoundController *m_soundController;
    IExerciseController *m_exerciseController;
    IUiController *m_uiController;
};

}

#endif
