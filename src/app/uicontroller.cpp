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

#include <QQmlApplicationEngine>
#include <QQmlContext>

#ifndef Q_OS_ANDROID
#include <KLocalizedContext>
#endif

namespace Minuet
{
UiController::UiController(QObject *parent) : IUiController(parent) {}

bool UiController::initialize(Core *core)
{
    m_errorString.clear();
    auto *engine = new QQmlApplicationEngine(this);
    QQmlContext *rootContext = engine->rootContext();
    rootContext->setContextProperty(QStringLiteral("core"), core);
#ifndef Q_OS_ANDROID
    rootContext->setContextObject(new KLocalizedContext(engine));
#else
    rootContext->setContextObject(new DummyAndroidLocalizer(engine));
#endif
    engine->load(QUrl(QStringLiteral("qrc:/Main.qml")));

    return true;
}

QString UiController::errorString() const
{
    return m_errorString;
}

}
