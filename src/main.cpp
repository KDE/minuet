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

#include "minuet.h"

#include "minuet_version.h"

#include <KCrash/KCrash>
#include <KCoreAddons/KAboutData>

#include <QCommandLineParser>

Q_DECLARE_LOGGING_CATEGORY(MINUET)
Q_LOGGING_CATEGORY(MINUET, "minuet")

//#include <QQmlDebuggingEnabler>
//QQmlDebuggingEnabler enabler;

int main(int argc, char **argv)
{
    QApplication application(argc, argv);

    KCrash::initialize();

    KLocalizedString::setApplicationDomain("minuet");
    KAboutData aboutData( QStringLiteral("minuet"),
                          i18n("Minuet"),
                          QStringLiteral(MINUET_VERSION_STRING),
                          i18n("A KDE application for music education"),
                          KAboutLicense::GPL,
                          i18n("(c) 2016, Sandro S. Andrade (sandroandrade@kde.org)"));

    aboutData.addAuthor(i18n("Sandro S. Andrade"),i18n("Developer"), QStringLiteral("sandroandrade@kde.org"));
    aboutData.addAuthor(i18n("Alessandro Longo"),i18n("Minuet Icon Designer"), QStringLiteral("alessandro.longo@kdemail.net"));
    application.setWindowIcon(QIcon::fromTheme(QStringLiteral("minuet")));
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    aboutData.setupCommandLine(&parser);
    parser.process(application);
    aboutData.processCommandLine(&parser);
    KAboutData::setApplicationData(aboutData);

    Minuet *appwindow = new Minuet;
    appwindow->show();
    return application.exec();
}
