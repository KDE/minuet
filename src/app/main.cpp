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

#include "core.h"
#include <app/minuet_version.h>

#include <KAboutData>

#if !defined(Q_OS_ANDROID)
#include <KCrash>
#else
#include <KColorSchemeManager>
#endif
#include <KLocalizedString>

#include <QCommandLineParser>
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
    QGuiApplication application(argc, argv);

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
