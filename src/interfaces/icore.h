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

#ifndef MINUET_ICORE_H
#define MINUET_ICORE_H

#include <interfaces/minuetinterfacesexport.h>

#include <QObject>

namespace Minuet
{
class IPluginController;
class ISoundController;
class IExerciseController;
class IUiController;

class MINUETINTERFACES_EXPORT ICore : public QObject
{
    Q_OBJECT

    Q_PROPERTY(IPluginController *pluginController READ pluginController CONSTANT);
    Q_PROPERTY(
        ISoundController *soundController READ soundController NOTIFY soundControllerChanged);
    Q_PROPERTY(IExerciseController *exerciseController READ exerciseController CONSTANT);
    Q_PROPERTY(IUiController *uiController READ uiController CONSTANT);

public:
    virtual ~ICore() override;

    static ICore *self();

    virtual Minuet::IPluginController *pluginController() = 0;
    virtual Minuet::ISoundController *soundController() = 0;
    virtual Minuet::IExerciseController *exerciseController() = 0;
    virtual Minuet::IUiController *uiController() = 0;

Q_SIGNALS:
    void soundControllerChanged(Minuet::ISoundController *newSoundController);

protected:
    explicit ICore(QObject *parent = 0);
    static ICore *m_self;
};

}

#endif
