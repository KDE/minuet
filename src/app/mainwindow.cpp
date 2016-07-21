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

#include "mainwindow.h"

#include "core.h"
#include "minuet_version.h"

#include <KMessageBox>
#include <KConfigDialog>
#include <KActionCollection>

#include <QTimer>
#include <QPointer>
#include <QToolBar>
#include <QQmlEngine>
#include <QQuickView>
#include <QQmlContext>
#include <QStringList>
#include <QLoggingCategory>

Q_DECLARE_LOGGING_CATEGORY(MINUET)
Q_LOGGING_CATEGORY(MINUET, "minuet")

MainWindow::MainWindow(Minuet::Core *core, QWidget *parent, Qt::WindowFlags f) :
    KXmlGuiWindow(parent, f),
    m_quickView(new QQuickView),
    m_initialGroup(KSharedConfig::openConfig(), "version")
{
    QQmlContext *rootContext = m_quickView->engine()->rootContext();
    rootContext->setContextProperty(QStringLiteral("core"), core);

    m_quickView->setSource(QUrl::fromLocalFile(QStandardPaths::locate(QStandardPaths::DataLocation, QStringLiteral("qml/Main.qml"))));
    m_quickView->setResizeMode(QQuickView::SizeRootObjectToView);
    setCentralWidget(QWidget::createWindowContainer(m_quickView, this));

    KStandardAction::quit(qApp, SLOT(closeAllWindows()), actionCollection());
    KStandardAction::preferences(this, SLOT(settingsConfigure()), actionCollection());

    setupGUI(Keys | Save | Create);
    foreach (QToolBar *toolBar, findChildren<QToolBar*>())
        delete toolBar;
}

MainWindow::~MainWindow()
{
    delete m_quickView;
}

bool MainWindow::queryClose()
{
    MinuetSettings::self()->save();
    return true;
}

void MainWindow::settingsConfigure()
{
    if (KConfigDialog::showDialog(QStringLiteral("settings")))
        return;

    QPointer<KConfigDialog> dialog = new KConfigDialog(this, QStringLiteral("settings"), MinuetSettings::self());
    QWidget *midiSettingsDialog = new QWidget;
    m_settingsMidi.setupUi(midiSettingsDialog);
    m_settingsMidi.kcfg_midiOutputPort->setVisible(false);
    m_settingsMidi.cboMidiOutputPort->setCurrentIndex(m_settingsMidi.cboMidiOutputPort->findText(MinuetSettings::midiOutputPort()));
    dialog->addPage(midiSettingsDialog, i18n("MIDI"), QStringLiteral("media-playback-start"));
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    dialog->exec();
    delete dialog;
}
