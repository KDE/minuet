// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_PLUGINCONTROLLER_H
#define MINUET_PLUGINCONTROLLER_H

#include <QObject>
#include <QString>

#ifndef Q_OS_ANDROID
#include <QHash>
#include <KPluginMetaData>
#include <QVector>
#endif

namespace Minuet
{
class Core;
class IPlugin;

class PluginController : public QObject
{
    Q_OBJECT

public:
    ~PluginController() override;

    bool initialize(Core *core);
    QString errorString() const;

private:
    friend class Core;

    explicit PluginController(QObject *parent = nullptr);

#ifndef Q_OS_ANDROID
    QVector<KPluginMetaData> m_plugins;

    typedef QHash<KPluginMetaData, IPlugin *> InfoToPluginMap;
    InfoToPluginMap m_loadedPlugins;
#endif
    QString m_errorString;
};

}

#endif
