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

#include "plugincontroller.h"

#include "core.h"

#if defined(Q_OS_ANDROID)
#include "../plugins/csoundsoundcontroller/csoundsoundcontroller.h"
#endif

#include <interfaces/iplugin.h>
#include <interfaces/isoundcontroller.h>

#if !defined(Q_OS_ANDROID)
#include <KPluginLoader>
#endif

#include <QDebug>

namespace Minuet
{
PluginController::PluginController(QObject *parent) : IPluginController(parent)
{
#if !defined(Q_OS_ANDROID)
    m_plugins = KPluginLoader::findPlugins(QStringLiteral("minuet"));
#endif
}

PluginController::~PluginController()
{
#if !defined(Q_OS_ANDROID)
    const auto &loadedPlugins = m_loadedPlugins.values();
    qDeleteAll(loadedPlugins.begin(), loadedPlugins.end());
    m_loadedPlugins.clear();
#endif
}

bool PluginController::initialize(Core *core)
{
    m_errorString.clear();
#if !defined(Q_OS_ANDROID)
    ISoundController *soundController = nullptr;
    foreach (const KPluginMetaData &pluginMetaData, m_plugins) {
        if (m_loadedPlugins.value(pluginMetaData)) {
            continue;
        }

        KPluginLoader loader(pluginMetaData.fileName());
        IPlugin *plugin = qobject_cast<IPlugin *>(loader.instance());
        if (plugin) {
            m_loadedPlugins.insert(pluginMetaData, plugin);
            if (!core->soundController()
                && (soundController = qobject_cast<ISoundController *>(plugin))) {
                qInfo() << "Setting soundcontroller to"
                        << soundController->metaObject()->className();
                core->setSoundController(soundController);
            }
        }
    }
    if (!soundController) {
        m_errorString = QStringLiteral("Could not find a suitable SoundController plugin!");
        return false;
    }
#else
    ISoundController *soundController = 0;
    if (!core->soundController() && (soundController = new CsoundSoundController)) {
        qInfo() << "Setting soundcontroller to" << soundController->metaObject()->className();
        core->setSoundController(soundController);
    }
#endif
    return true;
}

QString PluginController::errorString() const
{
    return m_errorString;
}

}
