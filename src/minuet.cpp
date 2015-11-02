/****************************************************************************
**
** Copyright (C) 2015 by Sandro S. Andrade <sandroandrade@kde.org>
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

#include <KConfigDialog>
#include <KActionCollection>

#include <QtCore/QDebug>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlContext>
#include <QtQuick/QQuickView>
#include <QtWidgets/QFileDialog>

#include "midisequencer.h"

Minuet::Minuet() :
    KXmlGuiWindow(),
    m_midiSequencer(new MidiSequencer(this))
{
    QQuickView *quickView = new QQuickView;
    quickView->engine()->rootContext()->setContextProperty("sequencer", m_midiSequencer);
    quickView->setSource(QUrl("qrc:/main.qml"));
    quickView->setResizeMode(QQuickView::SizeRootObjectToView);
    setCentralWidget(QWidget::createWindowContainer(quickView, this));

    KStandardAction::open(this, SLOT(fileOpen()), actionCollection());
    KStandardAction::quit(qApp, SLOT(closeAllWindows()), actionCollection());
    KStandardAction::preferences(this, SLOT(settingsConfigure()), actionCollection());
    setStandardToolBarMenuEnabled(false);
    setupGUI();    
}

Minuet::~Minuet()
{
}

void Minuet::fileOpen()
{
    QString fileName = QFileDialog::getOpenFileName(this, i18n("Open File"));
    m_midiSequencer->openFile(fileName);
}

void Minuet::settingsConfigure()
{
    qCDebug(MINUET) << "Minuet:settingsConfigure()";

    if (KConfigDialog::showDialog("settings"))
        return;

    KConfigDialog *dialog = new KConfigDialog(this, "settings", MinuetSettings::self());
    QWidget *generalSettingsDialog = new QWidget;
    settingsBase.setupUi(generalSettingsDialog);
    dialog->addPage(generalSettingsDialog, i18n("General"), "package_setting");
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    dialog->show();
}

#include "minuet.moc"
