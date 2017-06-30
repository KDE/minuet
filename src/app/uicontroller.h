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

#ifndef MINUET_UICONTROLLER_H
#define MINUET_UICONTROLLER_H

#include <interfaces/iuicontroller.h>
#include <QQmlApplicationEngine>

#ifdef Q_OS_ANDROID
#include <QVariant>

class DummyAndroidLocalizer : public QObject
{
    Q_OBJECT

public:
    explicit DummyAndroidLocalizer(QObject *parent = 0) : QObject(parent) { }

    Q_INVOKABLE QString i18n (const QString &message, const QVariant &p1=QVariant(), const QVariant &p2=QVariant(), const QVariant &p3=QVariant(), const QVariant &p4=QVariant(), const QVariant &p5=QVariant(), const QVariant &p6=QVariant(), const QVariant &p7=QVariant(), const QVariant &p8=QVariant(), const QVariant &p9=QVariant(), const QVariant &p10=QVariant()) const
    {
        return message;
    }

    Q_INVOKABLE QString i18nc (const QString &context, const QString &message, const QVariant &p1=QVariant(), const QVariant &p2=QVariant(), const QVariant &p3=QVariant(), const QVariant &p4=QVariant(), const QVariant &p5=QVariant(), const QVariant &p6=QVariant(), const QVariant &p7=QVariant(), const QVariant &p8=QVariant(), const QVariant &p9=QVariant(), const QVariant &p10=QVariant()) const
    {
        return message;
    }
};
#endif

namespace Minuet
{

class Core;

class UiController : public IUiController
{
    Q_OBJECT

public:
    UiController(QObject *parent = 0);
    ~UiController() override;
    QQmlApplicationEngine *engine;

    bool initialize(Core *core);
    bool initializePlugins();
    virtual QString errorString() const;

private:
    QString m_errorString;
};

}

#endif
