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

#include "csengine.h"
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QStringList>

CsEngine::CsEngine()
{
    m_fileName = (char *)"./template.csd";
}

void CsEngine::run()
{
    cs.setOpenSlCallbacks();  // for android audio to work
    QFile file(m_fileName);
    file.open(QIODevice::ReadOnly);
    qDebug() << "Template: ";
    while (!file.atEnd()) {
        qDebug() << file.readLine();
    }
    file.close();
    qWarning() << "Dir " << QDir::currentPath() << " contains sf_GMbank.sf2? "
               << QDir::current().entryList(QDir::Files).contains("sf_GMbank.sf2");
    qWarning() << "Dir " << QCoreApplication::applicationDirPath()
               << " contains libfluidOpcodes.so? "
               << QDir(QCoreApplication::applicationDirPath())
                      .entryList(QDir::Files)
                      .contains("libfluidOpcodes.so");
    qDebug() << "READING " << QDir::currentPath() + "/template.csd";
    qDebug() << "SOUNDFONT EXISTS? "
             << QFile("/data/data/org.kde.minuet/files/sf_GMbank.sf2").exists() << " "
             << QFileInfo("/data/data/org.kde.minuet/files/sf_GMbank.sf2").size() << "b";
    if (cs.Compile(m_fileName)) {
        cs.Start();
        cs.Perform();
        cs.Cleanup();
        cs.Reset();
        cs.Stop();
    }
}

void CsEngine::stop()
{
    //    cs.Stop();
}
