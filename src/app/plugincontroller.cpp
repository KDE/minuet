// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "plugincontroller.h"

#include "core.h"

#if defined(Q_OS_ANDROID)
#include "../plugins/fluidsynthsoundcontroller/fluidsynthsoundcontroller.h"
#endif

#include <interfaces/iplugin.h>
#include <interfaces/isoundcontroller.h>

#if !defined(Q_OS_ANDROID)
#include <QPluginLoader>
#include <KPluginMetaData>
#endif

#include <QDebug>

#include <utility>

using namespace Qt::StringLiterals;

namespace Minuet
{
PluginController::PluginController(QObject *parent) : QObject(parent)
{
#if !defined(Q_OS_ANDROID)
    m_plugins = KPluginMetaData::findPlugins(u"minuet"_s);
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
    for (const KPluginMetaData &pluginMetaData : std::as_const(m_plugins)) {
        if (m_loadedPlugins.value(pluginMetaData)) {
            continue;
        }

        QPluginLoader loader(pluginMetaData.fileName());
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
        m_errorString = u"Could not find a suitable SoundController plugin!"_s;
        return false;
    }
#else
    ISoundController *soundController = 0;
    if (!core->soundController() && (soundController = new FluidSynthSoundController(core))) {
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

#include "moc_plugincontroller.cpp"
