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

#include <interfaces/iplugin.h>
#include <interfaces/isoundbackend.h>

#include <KPluginLoader>

#include <QDebug>

namespace Minuet
{

PluginController::PluginController(QObject *parent)
    : IPluginController(parent)
{
    m_plugins = KPluginLoader::findPlugins(QStringLiteral("minuet"), [&](const KPluginMetaData &meta) {
        if (!meta.serviceTypes().contains(QStringLiteral("Minuet/Plugin"))) {
            qDebug() << "Plugin" << meta.fileName() << "is installed into the minuet plugin directory, but does not have"
                " \"Minuet/Plugin\" set as the service type. This plugin will not be loaded.";
            return false;
        }
        return true;
    });
}

PluginController::~PluginController()
{
    qDeleteAll(m_loadedPlugins.values().begin(), m_loadedPlugins.values().end());
    m_loadedPlugins.clear();
}

bool PluginController::initialize(Core *core)
{
    foreach (const KPluginMetaData &pluginMetaData, m_plugins)
    {
        if (m_loadedPlugins.value(pluginMetaData))
            continue;

        KPluginLoader loader(pluginMetaData.fileName());
        IPlugin *plugin = qobject_cast<IPlugin *>(loader.instance());
        if (plugin) {
            m_loadedPlugins.insert(pluginMetaData, plugin);
            ISoundBackend *soundBackend = 0;
            if (!core->soundBackend() && (soundBackend = qobject_cast<ISoundBackend *>(plugin))) {
                qDebug() << "Setting soundbackend to" << soundBackend->metaObject()->className();
                core->setSoundBackend(soundBackend);
            }
        }
    }

    return true;
}

}

