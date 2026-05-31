// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "core.h"
#include <app/minuet_version.h>

#include <KAboutData>

#if !defined(Q_OS_ANDROID)
#include <KCrash>
#if defined(Q_OS_MACOS)
#include <KIconTheme>
#endif
#else
#include <KColorSchemeManager>
#endif
#include <KLocalizedString>

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QStringList>

#include <QDebug>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
#if defined(Q_OS_MACOS)
    KIconTheme::initTheme();
#endif

    QGuiApplication application(argc, argv);

#if defined(Q_OS_MACOS)
    QCoreApplication::addLibraryPath(QDir(QCoreApplication::applicationDirPath()).absoluteFilePath(u"../PlugIns"_s));
#endif

#if !defined(Q_OS_ANDROID)
    KCrash::initialize();
#endif

    KLocalizedString::setApplicationDomain("minuet");

    KAboutData aboutData(u"minuet"_s, i18n("Minuet"),
                         QString::fromUtf8(MINUET_VERSION_STRING),
                         i18n("A KDE application for music education"), KAboutLicense::GPL,
                         i18n("(c) 2016, Sandro S. Andrade (sandroandrade@kde.org)"));
    aboutData.setHomepage(u"https://minuet.kde.org"_s);
    aboutData.setBugAddress("submit@bugs.kde.org");
    aboutData.setProductName("minuet");
    aboutData.setDesktopFileName(u"org.kde.minuet"_s);
    aboutData.addAuthor(u"Sandro S. Andrade"_s, i18n("Developer"),
                        u"sandroandrade@kde.org"_s);
    aboutData.addAuthor(u"Ayush Shah"_s, i18n("Developer"),
                        u"1595ayush@gmail.com"_s);
    aboutData.addAuthor(u"Alessandro Longo"_s, i18n("Minuet Icon Designer"),
                        u"alessandro.longo@kdemail.net"_s);
    aboutData.addComponent(i18nc("@info:credit", "Fluidsynth"), i18nc("@info:credit", "Software synthesizer based on the SoundFont 2 specifications. © 2003 Peter Hanappe and others."), {}, u"https://github.com/FluidSynth/fluidsynth"_s, KAboutLicense::LGPL_V2_1);

#if defined(Q_OS_ANDROID)
    QQuickStyle::setStyle(u"org.kde.breeze"_s);
    KColorSchemeManager::instance();
#else
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
    }
#endif

    QGuiApplication::setWindowIcon(QIcon(u":/icons/64-apps-minuet.png"_s));

    QCommandLineParser parser;
    KAboutData::setApplicationData(aboutData);
#if !defined(Q_OS_ANDROID)
    aboutData.setupCommandLine(&parser);
#else
    parser.addHelpOption();
    parser.addVersionOption();
#endif
    parser.process(application);
#if !defined(Q_OS_ANDROID)
    aboutData.processCommandLine(&parser);
#endif

#if defined(Q_OS_ANDROID)
    const QDir writableDataDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    const QString soundfontDirPath = writableDataDir.absoluteFilePath(u"soundfonts"_s);
    const QString soundfontPath = QDir(soundfontDirPath).absoluteFilePath(u"GeneralUser-v1.47.sf2"_s);
    if (!QFile::exists(soundfontPath)) {
        QDir().mkpath(soundfontDirPath);
        const QStringList assetPaths = {
            u"assets:/share/minuet/soundfonts/GeneralUser-v1.47.sf2"_s,
            u"assets:/data/soundfonts/GeneralUser-v1.47.sf2"_s,
            u"assets:/share/GeneralUser-v1.47.sf2"_s,
        };
        for (const QString &assetPath : assetPaths) {
            QFile assetFile(assetPath);
            if (assetFile.exists() && assetFile.copy(soundfontPath)) {
                qDebug() << "Copied" << QFileInfo(soundfontPath).size()
                         << "b soundfont file to" << soundfontPath;
                break;
            }
        }
    }
#endif
    Minuet::Core::initialize();

    return QGuiApplication::exec();
}
