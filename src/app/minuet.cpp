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

#include "wizard.h"
#include "midisequencer.h"
#include "exercisecontroller.h"

#include <KXmlGui/KActionCollection>
#include <KWidgetsAddons/KMessageBox>
#include <KConfigWidgets/KConfigDialog>

#include <QQmlEngine>
#include <QQmlContext>

#include <QTimer>
#include <QPointer>
#include <QStringList>

#include <QQuickView>

#include <QToolBar>

Minuet::Minuet() :
    KXmlGuiWindow(),
    m_midiSequencer(new MidiSequencer(this)),
    m_exerciseController(new ExerciseController(m_midiSequencer)),
    m_quickView(new QQuickView),
    m_initialGroup(KSharedConfig::openConfig(), "version")
{
    if (m_midiSequencer->schedulingMode() == MidiSequencer::DAMAGED) {
        QTimer::singleShot(0, qApp, SLOT(quit()));
        return;
    }

    if (!m_exerciseController->configureExercises())
        KMessageBox::error(this,
                           i18n("There was an error when parsing exercises JSON files: \"%1\".", m_exerciseController->errorString()),
                           i18n("Minuet startup"));

    QQmlContext *rootContext = m_quickView->engine()->rootContext();
    rootContext->setContextProperty(QStringLiteral("exerciseCategories"), m_exerciseController->exercises()[QStringLiteral("exercises")].toArray());
    rootContext->setContextProperty(QStringLiteral("sequencer"), m_midiSequencer);
    rootContext->setContextProperty(QStringLiteral("exerciseController"), m_exerciseController);
    m_quickView->setSource(QUrl::fromLocalFile(QStandardPaths::locate(QStandardPaths::DataLocation, QStringLiteral("qml/Main.qml"))));
    m_quickView->setResizeMode(QQuickView::SizeRootObjectToView);
    setCentralWidget(QWidget::createWindowContainer(m_quickView, this));

//    KStandardAction::open(this, SLOT(fileOpen()), actionCollection());
    KStandardAction::quit(qApp, SLOT(closeAllWindows()), actionCollection());
    KStandardAction::preferences(this, SLOT(settingsConfigure()), actionCollection());

    QAction *action = new QAction(i18n("Run Configuration Wizard"), this);
    action->setIcon(QIcon::fromTheme(QStringLiteral("tools-wizard")));
    connect(action, &QAction::triggered, this, &Minuet::runWizard);
    actionCollection()->addAction(QStringLiteral("run_wizard"), action);

    setupGUI(Keys | Save | Create);
    foreach (QToolBar *toolBar, findChildren<QToolBar*>())
        delete toolBar;

    if (!m_initialGroup.exists())
        runWizard();

    startTimidity();
    subscribeToMidiOutputPort();
}

void Minuet::startTimidity()
{
    QString error;
    if (!m_midiSequencer->availableOutputPorts().contains(QStringLiteral("TiMidity:0"))) {
	qCDebug(MINUET) << "Starting TiMidity++ at" << MinuetSettings::timidityLocation().remove(QStringLiteral("file://"));
	m_timidityProcess.setProgram(MinuetSettings::timidityLocation().remove(QStringLiteral("file://")), QStringList() << MinuetSettings::timidityParameters());
	m_timidityProcess.start();
	if (!m_timidityProcess.waitForStarted(-1)) {
	    error = m_timidityProcess.errorString();
	}
	else {
	    if (!waitForTimidityOutputPorts(3000))
		error = i18n("error when waiting for TiMidity++ output ports!");
	    else
		qCDebug(MINUET) << "TiMidity++ started!";
	}
    }
    else {
	qCDebug(MINUET) << "TiMidity++ already running!";
    }
    if (!error.isEmpty())
        KMessageBox::error(this,
                           i18n("There was an error when starting TiMidity++: \"%1\". "
                                "Is another application using the audio system? "
                                "Also, please check Minuet settings!", error),
                           i18n("Minuet startup"));
}

bool Minuet::waitForTimidityOutputPorts(int msecs)
{
    QTime time;
    time.start();
    while (!m_midiSequencer->availableOutputPorts().contains(QStringLiteral("TiMidity:0")))
	if (msecs != -1 && time.elapsed() > msecs)
	    return false;
    return true;
}

void Minuet::subscribeToMidiOutputPort()
{
    QString midiOutputPort = MinuetSettings::midiOutputPort();
    if (!midiOutputPort.isEmpty() && m_midiSequencer->availableOutputPorts().contains(midiOutputPort))
        m_midiSequencer->subscribeTo(midiOutputPort);
}

Minuet::~Minuet()
{
    delete m_quickView;
    delete m_exerciseController;
    m_timidityProcess.kill();
    qCDebug(MINUET) << "Stoping TiMidity++!";
    if (!m_timidityProcess.waitForFinished(-1))
        qCDebug(MINUET) << "Error when stoping TiMidity++:" << m_timidityProcess.errorString();
    else
	qCDebug(MINUET) << "TiMidity++ stoped!";
}

bool Minuet::queryClose()
{
    MinuetSettings::self()->save();
    return true;
}

/*
void Minuet::fileOpen()
{
    QString fileName = QFileDialog::getOpenFileName(this, i18n("Open File")); // krazy:exclude=qclasses
    if (!fileName.isEmpty())
        m_midiSequencer->openFile(fileName);
}
*/

void Minuet::runWizard()
{
    QScopedPointer<Wizard> w (new Wizard(this));
    if (w->exec() == QDialog::Accepted && w->isOk()) {
        w->adjustSettings();
        m_initialGroup.writeEntry("version", "1.0");
    }
}

void Minuet::settingsConfigure()
{
    if (KConfigDialog::showDialog(QStringLiteral("settings")))
        return;

    QPointer<KConfigDialog> dialog = new KConfigDialog(this, QStringLiteral("settings"), MinuetSettings::self());
    QWidget *midiSettingsDialog = new QWidget;
    m_settingsMidi.setupUi(midiSettingsDialog);
    m_settingsMidi.kcfg_midiOutputPort->setVisible(false);
    m_settingsMidi.cboMidiOutputPort->insertItems(0, m_midiSequencer->availableOutputPorts());
    m_settingsMidi.cboMidiOutputPort->setCurrentIndex(m_settingsMidi.cboMidiOutputPort->findText(MinuetSettings::midiOutputPort()));
    dialog->addPage(midiSettingsDialog, i18n("MIDI"), QStringLiteral("media-playback-start"));
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    if (dialog->exec() == QDialog::Accepted)
	subscribeToMidiOutputPort();
    delete dialog;
}
