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

#if !defined(Q_OS_ANDROID)
#include <KAboutData>
#include <KCrash>
#include <KLocalizedString>
#endif

#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QIcon>

#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication application(argc, argv);

#if !defined(Q_OS_ANDROID)
    KCrash::initialize();

    KLocalizedString::setApplicationDomain("minuet");

    KAboutData aboutData(QStringLiteral("minuet"), i18n("Minuet"),
                         QStringLiteral(MINUET_VERSION_STRING),
                         i18n("A KDE application for music education"), KAboutLicense::GPL,
                         i18n("(c) 2016, Sandro S. Andrade (sandroandrade@kde.org)"));
    aboutData.addAuthor(QStringLiteral("Sandro S. Andrade"), i18n("Developer"),
                        QStringLiteral("sandroandrade@kde.org"));
    aboutData.addAuthor(QStringLiteral("Ayush Shah"), i18n("Developer"),
                        QStringLiteral("1595ayush@gmail.com"));
    aboutData.addAuthor(QStringLiteral("Alessandro Longo"), i18n("Minuet Icon Designer"),
                        QStringLiteral("alessandro.longo@kdemail.net"));
#endif

    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/minuet.png")));

    QCommandLineParser parser;
#if !defined(Q_OS_ANDROID)
    KAboutData::setApplicationData(aboutData);
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
    if (!QFile("/data/data/org.kde.minuet/files/sf_GMbank.sf2").exists()) {
        if (QFile("assets:/share/sf_GMbank.sf2")
                .copy("/data/data/org.kde.minuet/files/sf_GMbank.sf2"))
            qDebug() << "COPIED "
                     << QFileInfo("/data/data/org.kde.minuet/files/sf_GMbank.sf2").size()
                     << "b soundfound file to /data/data/org.kde.minuet/files/sf_GMbank.sf2";
    }
#endif
    Minuet::Core::initialize();

    return QGuiApplication::exec();
}
