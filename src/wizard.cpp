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

#include "wizard.h"

#include "minuetsettings.h"

#include <KI18n/KLocalizedString>

#include <QTimer>
#include <QDirIterator>
#include <QStandardPaths>

#include <QLabel>
#include <QVBoxLayout>

Wizard::Wizard(QWidget *parent, Qt::WindowFlags flags) :
    QWizard(parent, flags),
    m_okIcon (QIcon::fromTheme(QStringLiteral("dialog-ok"))),
    m_badIcon (QIcon::fromTheme(QStringLiteral("dialog-close")))
{
    setWindowTitle(i18n("Config Wizard"));

    QWizardPage *page1 = new QWizardPage;
    page1->setTitle(i18n("Welcome"));
    QLabel *welcomeLabel = new QLabel(i18n("This is the first time you run Minuet. This wizard will let you adjust some basic settings, you will be ready to starting enhancing your music skills in a few seconds ..."), this);
    welcomeLabel->setWordWrap(true);
    QVBoxLayout *startLayout = new QVBoxLayout;
    startLayout->addWidget(welcomeLabel);

    page1->setLayout(startLayout);
    addPage(page1);

    QWizardPage *page2 = new QWizardPage;
    page2->setTitle(i18n("Checking system"));
    m_systemCheck.setupUi(page2);
    WizardDelegate *listViewDelegate = new WizardDelegate(m_systemCheck.programList);
    m_systemCheck.programList->setItemDelegate(listViewDelegate);
    addPage(page2);

    QTimer::singleShot(500, this, &Wizard::checkSystem);
}

bool Wizard::isOk() const
{
    return m_systemCheckIsOk;
}

void Wizard::adjustSettings()
{
    if (!m_timidityPath.isEmpty()) {
        MinuetSettings::setTimidityPath(m_timidityPath);
        if (MinuetSettings::timidityParameters().isEmpty())
            MinuetSettings::setTimidityParameters(QStringLiteral("-iA"));
        if (MinuetSettings::midiOutputPort().isEmpty())
            MinuetSettings::setMidiOutputPort(QStringLiteral("TiMidity:0"));
    }
}

void Wizard::checkSystem()
{
    m_systemCheckIsOk = false;
    m_systemCheck.programList->setColumnWidth(0, 30);
    m_systemCheck.programList->setIconSize(QSize(24, 24));

    QTreeWidgetItem *item = addTreeWidgetItem(QStringLiteral("TiMidity++"), i18n("Required for playing MIDI files and exercises"));
    
    m_timidityPath = QStandardPaths::findExecutable(QStringLiteral("timidity"));
    if (m_timidityPath.isEmpty()) {
        item->setIcon(0, m_badIcon);
        return;
    }

    item = addTreeWidgetItem(i18n("TiMidity++ configuration file"), i18n("Required for setting up TiMidity++"));

    QDirIterator it("/etc", QDirIterator::Subdirectories);
    QString timidityConfig;
    while (it.hasNext()) {
        QString file = it.next();
        if (file.contains(QRegularExpression("timidity(\\+\\+)?.cfg"))) {
            timidityConfig = file;
            break;
        }
    }
    if (!timidityConfig.isEmpty()) {
        QFile timidityConfigFile(timidityConfig);
        if (!timidityConfigFile.open(QIODevice::ReadOnly)) {
            qWarning("Couldn't open TiMidity configuration file.");
            return;
        }
        bool sourceFound = false;
        QTextStream in(&timidityConfigFile);
        while (!in.atEnd())
        {
           QString line = timidityConfigFile.readLine().simplified();
           if (line.contains("source") && !line.startsWith('#')) {
               QRegularExpression regExp("source ([^/]*)\\.cfg");
               QRegularExpressionMatch match = regExp.match(line);
               item = addTreeWidgetItem(i18n("TiMidity++ %1 sound source", match.captured(1)), i18n("Required for setting up TiMidity++ sound sources"));
               sourceFound = true;
           }
        }
        timidityConfigFile.close();
        if (!sourceFound) {
            item = addTreeWidgetItem(i18n("A TiMidity++ sound source"), i18n("No TiMidity++ sound source found! Sounds won't work!"));
            item->setIcon(0, m_badIcon);
            return;
        }
    } else {
        item->setIcon(0, m_badIcon);
	return;
    }
    m_systemCheckIsOk = true;
}

QTreeWidgetItem *Wizard::addTreeWidgetItem(const QString &text, const QString &subText)
{
    QSize itemSize(20, fontMetrics().height() * 2.5);
    QTreeWidgetItem *item = new QTreeWidgetItem(m_systemCheck.programList, QStringList() << QString() << text);
    item->setData(1, Qt::UserRole, subText);
    item->setSizeHint(0, itemSize);
    item->setIcon(0, m_okIcon);

    return item;
}
