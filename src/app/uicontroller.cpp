// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "uicontroller.h"

#include "core.h"

#include <QQmlApplicationEngine>
#include <QQuickWindow>

#include <KLocalizedQmlContext>
#include <KLocalizedString>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#elif defined(Q_OS_IOS)
#include "ios/iossplashscreen.h"
#endif

using namespace Qt::StringLiterals;

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
namespace
{
void hidePlatformSplashScreen()
{
#if defined(Q_OS_ANDROID)
    QJniObject::callStaticMethod<void>("org/kde/minuet/MinuetActivity", "hideSplashScreen", "()V");
#else
    Minuet::hideIosSplashScreen();
#endif
}
}
#endif

namespace Minuet
{
UiController::UiController(QObject *parent)
    : QObject(parent)
{
}

bool UiController::initialize(Core *core)
{
    Q_UNUSED(core)

    m_errorString.clear();
    auto *engine = new QQmlApplicationEngine(this);
    KLocalization::setupLocalizedContext(engine);
    engine->loadFromModule(u"org.kde.minuet"_s, u"Main"_s);

    if (engine->rootObjects().isEmpty()) {
#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
        hidePlatformSplashScreen();
#endif
        m_errorString = i18n("Could not load the main user interface.");
        return false;
    }

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    if (auto *window = qobject_cast<QQuickWindow *>(engine->rootObjects().constFirst())) {
#if defined(Q_OS_IOS)
        Minuet::showIosSplashScreen();
#endif
        QObject::connect(
            window,
            &QQuickWindow::frameSwapped,
            window,
            []() {
                hidePlatformSplashScreen();
            },
            Qt::SingleShotConnection);
#if defined(Q_OS_IOS)
        window->update();
#endif
    } else {
        hidePlatformSplashScreen();
    }
#endif

    return true;
}

QString UiController::errorString() const
{
    return m_errorString;
}

}

#include "moc_uicontroller.cpp"
