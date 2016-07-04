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

#include "drumsticksoundbackend.h"

#include "song.h"
#include "midisequenceroutputthread.h"

#include <drumstick/alsaqueue.h>
#include <drumstick/alsaclient.h>

#include <QTime>
#include <QtMath>
#include <QJsonObject>

DrumstickSoundBackend::DrumstickSoundBackend(QObject *parent)
    : Minuet::ISoundBackend(parent),
      m_song(0)
{
    // MidiClient configuration
    m_client = new drumstick::MidiClient(this);
    try {
        m_client->open();
    } catch (const drumstick::SequencerError &err) {
//         KMessageBox::error(qobject_cast<QWidget*>(this->parent()), i18n("Fatal error from the ALSA sequencer: \"%1\". "
//                 "This usually happens when the kernel doesn't have ALSA support, "
//                 "or the device node (/dev/snd/seq) doesn't exists, "
//                 "or the kernel module (snd_seq) is not loaded, "
//                 "or the user isn't a member of audio group. "
//                 "Please check your ALSA/MIDI configuration."
//                 , err.qstrError()),
//             i18n("Minuet startup"));
//         m_eventSchedulingMode = DAMAGED;
        return;
    }
    m_client->setClientName(QStringLiteral("MinuetSequencer"));
    m_client->setPoolOutput(50);

    // Connection for events generated when playing MIDI
    connect(m_client, &drumstick::MidiClient::eventReceived, this, &DrumstickSoundBackend::eventReceived, Qt::QueuedConnection);
    m_client->setRealTimeInput(false);
    m_client->startSequencerInput();

    // Output port configuration (to TiMidity)
    m_outputPort = new drumstick::MidiPort(this);
    m_outputPort->attach(m_client);
    m_outputPort->setPortName(QStringLiteral("Minuet Sequencer Output Port"));
    m_outputPort->setCapability(SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ);
    m_outputPort->setPortType(SND_SEQ_PORT_TYPE_APPLICATION | SND_SEQ_PORT_TYPE_MIDI_GENERIC);
    m_outputPortId = m_outputPort->getPortId();

    // Input port configuration (from ALSA)
    m_inputPort = new drumstick::MidiPort(this);
    m_inputPort->attach(m_client);
    m_inputPort->setPortName(QStringLiteral("Minuet Sequencer Input Port"));
    m_inputPort->setCapability(SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_SUBS_WRITE);
    m_inputPort->setPortType(SND_SEQ_PORT_TYPE_APPLICATION);
    m_inputPortId = m_inputPort->getPortId();

    // MidiQueue configuration
    m_queue = m_client->createQueue();
    m_queueId = m_queue->getId();

    // OutputThread
    m_midiSequencerOutputThread = new MidiSequencerOutputThread(m_client, m_outputPortId);
    connect(m_midiSequencerOutputThread, &MidiSequencerOutputThread::stopped, this, &DrumstickSoundBackend::outputThreadStopped);
    connect(m_midiSequencerOutputThread, &MidiSequencerOutputThread::finished, this, [=]() {
        setPlaybackLabel(QStringLiteral("00:00.00"));
        setState(StoppedState);
    });

    // Subscribe to Minuet's virtual piano
    try {
        m_outputPort->subscribeTo(QStringLiteral("MinuetSequencer:1"));
    } catch (const drumstick::SequencerError &err) {
        qCDebug(MINUET) << "Subscribe error";
        throw err;
    }
    setPlaybackLabel(QStringLiteral("00:00.00"));

    startTimidity();
    m_outputPort->subscribeTo("TiMidity:0");
}

DrumstickSoundBackend::~DrumstickSoundBackend()
{
    m_client->stopSequencerInput();
    m_outputPort->detach();
    m_inputPort->detach();
    m_client->close();
    delete m_midiSequencerOutputThread;
    m_timidityProcess.kill();
    qCDebug(MINUET) << "Stoping TiMidity++!";
    if (!m_timidityProcess.waitForFinished(-1))
        qCDebug(MINUET) << "Error when stoping TiMidity++:" << m_timidityProcess.errorString();
    else
        qCDebug(MINUET) << "TiMidity++ stoped!";
}

void DrumstickSoundBackend::setPitch(qint8 pitch)
{
    if (m_midiSequencerOutputThread->pitch() != pitch) {
        m_midiSequencerOutputThread->setPitch(pitch);
        emit pitchChanged(pitch);
    }
}

void DrumstickSoundBackend::setVolume(quint8 volume)
{
    if (m_midiSequencerOutputThread->volume() != volume) {
        m_midiSequencerOutputThread->setVolume(volume);
        emit volumeChanged(volume);
    }
}

void DrumstickSoundBackend::setTempo (quint8 tempo)
{
    float tempoFactor = (tempo*tempo + 100.0*tempo + 20000.0) / 40000.0;
    m_midiSequencerOutputThread->setTempoFactor(tempoFactor);

    drumstick::QueueTempo queueTempo = m_queue->getTempo();
    queueTempo.setTempoFactor(tempoFactor);
    m_queue->setTempo(queueTempo);
    m_client->drainOutput();

    m_tempo = tempo;
    emit tempoChanged(m_tempo);
}

void DrumstickSoundBackend::prepareFromExerciseOptions(QJsonArray selectedExerciseOptions, const QString &playMode)
{
    Song *song = new Song;
    song->setHeader(0, 1, 60);
    song->setInitialTempo(600000);
    m_song.reset(song);

    if (m_song->initialTempo() == 0)
        m_song->setInitialTempo(600000);
    appendEvent(new drumstick::TempoEvent(m_queueId, 600000), 0);

    unsigned int barStart = 0;
    if (playMode == "rhythm") {
        appendEvent(new drumstick::NoteOnEvent(9, 80, 120), 0);
        appendEvent(new drumstick::NoteOnEvent(9, 80, 120), 60);
        appendEvent(new drumstick::NoteOnEvent(9, 80, 120), 120);
        appendEvent(new drumstick::NoteOnEvent(9, 80, 120), 180);
        barStart = 240;
    }

    for (int i = 0; i < selectedExerciseOptions.size(); ++i) {
        QString sequence = selectedExerciseOptions[i].toObject()[QStringLiteral("sequence")].toString();

        unsigned int chosenRootNote = selectedExerciseOptions[i].toObject()[QStringLiteral("rootNote")].toString().toInt();
        if (playMode != "rhythm") {
             appendEvent(new drumstick::NoteOnEvent(1, chosenRootNote, 120), barStart);
             appendEvent(new drumstick::NoteOffEvent(1, chosenRootNote, 120), barStart + 60);
 
            unsigned int j = 1;
            drumstick::SequencerEvent *ev;
            foreach(const QString &additionalNote, sequence.split(' ')) {
                appendEvent(ev = new drumstick::NoteOnEvent(1, chosenRootNote + additionalNote.toInt(), 120),
                                                            (playMode == "scale") ? barStart+60*j:barStart);
                ev->setTag(0);
                appendEvent(ev = new drumstick::NoteOffEvent(1, chosenRootNote + additionalNote.toInt(), 120),
                                                             (playMode == "scale") ? barStart+60*(j+1):barStart+60);
                ev->setTag(0);
                ++j;
            }
            barStart += 60;
        }
        else {
            appendEvent(new drumstick::NoteOnEvent(9, 80, 120), barStart);
            foreach(QString additionalNote, sequence.split(' ')) { // krazy:exclude=foreach
                appendEvent(new drumstick::NoteOnEvent(9, 37, 120), barStart);
                float dotted = 1;
                if (additionalNote.endsWith('.')) {
                    dotted = 1.5;
                    additionalNote.chop(1);
                }
                barStart += dotted*60*(4.0/additionalNote.toInt());
            }
        }
    }
    if (playMode == "rhythm")
        appendEvent(new drumstick::NoteOnEvent(9, 80, 120), barStart);
}

void DrumstickSoundBackend::prepareFromMidiFile(const QString &fileName)
{
    Q_UNUSED(fileName)
}

void DrumstickSoundBackend::play()
{
    if (m_song && !m_song->isEmpty() && !m_midiSequencerOutputThread->isRunning()) {
        if(m_midiSequencerOutputThread->getInitialPosition() == 0 || !m_midiSequencerOutputThread->hasNext())
            m_midiSequencerOutputThread->setSong(m_song.data());
        m_midiSequencerOutputThread->start();
        setState(PlayingState);
    }
}

void DrumstickSoundBackend::pause()
{
    if (m_midiSequencerOutputThread->isRunning()) {
        m_midiSequencerOutputThread->stop();
        m_midiSequencerOutputThread->setPosition(m_queue->getStatus().getTickTime());
        setState(PausedState);
    }
}

void DrumstickSoundBackend::stop()
{
    m_midiSequencerOutputThread->stop();
    m_midiSequencerOutputThread->resetPosition();
    setPlaybackLabel(QStringLiteral("00:00.00"));
    setState(StoppedState);
}

void DrumstickSoundBackend::eventReceived(drumstick::SequencerEvent *ev)
{
    static QChar fill('0');
    drumstick::KeyEvent *kev;
    if (!(kev = static_cast<drumstick::KeyEvent*>(ev)))
        return;
//     if (kev->getSequencerType() == SND_SEQ_EVENT_NOTEON && kev->getTag() == 1)
//         emit noteOn(kev->getChannel(), kev->getKey(), kev->getVelocity());
//     if (kev->getSequencerType() == SND_SEQ_EVENT_NOTEOFF && kev->getTag() == 1)
//         emit noteOff(kev->getChannel(), kev->getKey(), kev->getVelocity());

    if (m_tick != 0 && m_midiSequencerOutputThread->isRunning()) {
        const snd_seq_real_time_t *rt = m_queue->getStatus().getRealtime();
        int mins = rt->tv_sec / 60;
        int secs = rt->tv_sec % 60;
        int cnts = qFloor( rt->tv_nsec / 1.0e7 );
        setPlaybackLabel(QStringLiteral("%1:%2.%3").arg(mins,2,10,fill).arg(secs,2,10,fill).arg(cnts,2,10,fill));
    }
}

void DrumstickSoundBackend::outputThreadStopped()
{
    for (int channel = 0; channel < 16; ++channel) {
        drumstick::ControllerEvent ev1(channel, MIDI_CTL_ALL_NOTES_OFF, 0);
        ev1.setSource(m_outputPortId);
        ev1.setSubscribers();
        ev1.setDirect();
        m_client->outputDirect(&ev1);
        drumstick::ControllerEvent ev2(channel, MIDI_CTL_ALL_SOUNDS_OFF, 0);
        ev2.setSource(m_outputPortId);
        ev2.setSubscribers();
        ev2.setDirect();
        m_client->outputDirect(&ev2);
    }
    m_client->drainOutput();
}

void DrumstickSoundBackend::appendEvent(drumstick::SequencerEvent *ev, unsigned long tick)
{
    ev->setSource(m_outputPortId);
    if (ev->getSequencerType() != SND_SEQ_EVENT_TEMPO)
        ev->setSubscribers();
    ev->scheduleTick(m_queueId, tick, false);
    ev->setTag(1);
    m_song->append(ev);
    if (tick > m_tick)
        m_tick = tick;
}

void DrumstickSoundBackend::startTimidity()
{
    QString error;
    if (!availableOutputPorts().contains(QStringLiteral("TiMidity:0"))) {
//        qCDebug(MINUET) << "Starting TiMidity++ at" << MinuetSettings::timidityLocation().remove(QStringLiteral("file://"));
//        m_timidityProcess.setProgram(MinuetSettings::timidityLocation().remove(QStringLiteral("file://")), QStringList() << MinuetSettings::timidityParameters());
        m_timidityProcess.setProgram("/usr/bin/timidity", QStringList() << "-iA");
        m_timidityProcess.start();
        if (!m_timidityProcess.waitForStarted(-1)) {
            error = m_timidityProcess.errorString();
        }
        else {
            if (!waitForTimidityOutputPorts(3000))
//                error = i18n("error when waiting for TiMidity++ output ports!");
                error = "error when waiting for TiMidity++ output ports!";
            else
                qCDebug(MINUET) << "TiMidity++ started!";
        }
    }
    else {
        qCDebug(MINUET) << "TiMidity++ already running!";
    }
//    if (!error.isEmpty())
//        KMessageBox::error(this,
//                           i18n("There was an error when starting TiMidity++: \"%1\". "
//                                "Is another application using the audio system? "
//                                "Also, please check Minuet settings!", error),
//                           i18n("Minuet startup"));
}

bool DrumstickSoundBackend::waitForTimidityOutputPorts(int msecs)
{
    QTime time;
    time.start();
    while (!availableOutputPorts().contains(QStringLiteral("TiMidity:0")))
        if (msecs != -1 && time.elapsed() > msecs)
            return false;
    return true;
}

QStringList DrumstickSoundBackend::availableOutputPorts() const
{
    QStringList availableOutputPorts;
    QListIterator<drumstick::PortInfo> it(m_client->getAvailableOutputs());
    while(it.hasNext()) {
        drumstick::PortInfo p = it.next();
        availableOutputPorts << QStringLiteral("%1:%2").arg(p.getClientName()).arg(p.getPort());
    }
    return availableOutputPorts;
}

#include "moc_drumsticksoundbackend.cpp"
