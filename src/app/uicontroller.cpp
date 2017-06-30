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

#include "uicontroller.h"

#include "core.h"

#include <QStandardPaths>

#include <QQmlContext>
#include <QQmlApplicationEngine>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QQmlContext>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>

#ifndef Q_OS_ANDROID
#include <KLocalizedContext>
#endif

namespace Minuet
{

UiController::UiController(QObject *parent)
    : IUiController(parent)
{
}

UiController::~UiController()
{
}

bool UiController::initializePlugins()
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QString directoryName = "plugins";
    QString minuet_dir = QStandardPaths::locate(QStandardPaths::AppDataLocation, directoryName, QStandardPaths::LocateDirectory);
    QDir dir(minuet_dir);
    qDebug()<<qApp->applicationDirPath();
    QString contents;
    QJsonArray mergedArray;
    foreach(const QString &fileName, dir.entryList(QStringList() << "*.json")) {
        QFile dfile(dir.absoluteFilePath(fileName));
        dfile.open(QIODevice::ReadOnly);
        QJsonObject jsonObject = QJsonDocument::fromJson(dfile.readAll()).object();
        QDir pluginDir(dir);
        pluginDir.cd(fileName.split('.').first());
        jsonObject["pluginName"] = pluginDir.absolutePath();
        mergedArray.append(jsonObject);
        dfile.close();
    }
    engine->rootContext()->setContextProperty("contents", mergedArray);
}

bool UiController::initialize(Core *core)
{
    m_errorString.clear();
    engine = new QQmlApplicationEngine(this);
    QQmlContext *rootContext = engine->rootContext();
    rootContext->setContextProperty(QStringLiteral("core"), core);
#ifndef Q_OS_ANDROID
    rootContext->setContextObject(new KLocalizedContext(engine));
#else
    rootContext->setContextObject(new DummyAndroidLocalizer(engine));
#endif

    initializePlugins();
    engine->load(QUrl("qrc:/Main.qml"));

    return true;
}

QString UiController::errorString() const
{
    return m_errorString;
}

}

