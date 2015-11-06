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

#include "midisequencer.h"

#include <drumstick/qsmf.h>
#include <drumstick/alsaevent.h>
#include <drumstick/alsaclient.h>

#include <QtMath>

#include "midisequenceroutputthread.h"

MidiSequencer::MidiSequencer(QObject *parent) :
    QObject(parent),
    m_tick(0),
    m_song(0),
    m_eventSchedulingMode(FROM_ENGINE)
{
    // MidiClient configuration
    m_client = new drumstick::MidiClient(this);
    m_client->open();
    m_client->setClientName("MinuetSequencer");
    m_client->setPoolOutput(50);
    // Connection for events generated when playing a MIDI
    connect(m_client, &drumstick::MidiClient::eventReceived, this, &MidiSequencer::eventReceived, Qt::QueuedConnection);
    m_client->setRealTimeInput(false);
    m_client->startSequencerInput();

    // Output port configuration
    m_outputPort = new drumstick::MidiPort(this);
    m_outputPort->attach(m_client);
    m_outputPort->setPortName("Minuet Sequencer Output Port");
    m_outputPort->setCapability(SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ);
    m_outputPort->setPortType(SND_SEQ_PORT_TYPE_APPLICATION | SND_SEQ_PORT_TYPE_MIDI_GENERIC);
    m_outputPortId = m_outputPort->getPortId();
    
    // Input port configuration
    m_inputPort = new drumstick::MidiPort(this);
    m_inputPort->attach(m_client);
    m_inputPort->setPortName("Minuet Sequencer Input Port");
    m_inputPort->setCapability(SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_SUBS_WRITE);
    m_inputPort->setPortType(SND_SEQ_PORT_TYPE_APPLICATION);
    m_inputPortId = m_inputPort->getPortId();

    // MidiQueue configuration
    m_queue = m_client->createQueue();
    m_firstTempo = m_queue->getTempo();
    m_queueId = m_queue->getId();

    // SMFReader configuration
    m_smfReader = new drumstick::QSmf(this);
    // Connections for events generated when reading a MIDI file
    connect(m_smfReader, &drumstick::QSmf::signalSMFHeader, this, &MidiSequencer::SMFHeader);
    connect(m_smfReader, &drumstick::QSmf::signalSMFNoteOn, this, &MidiSequencer::SMFNoteOn);
    connect(m_smfReader, &drumstick::QSmf::signalSMFNoteOff, this, &MidiSequencer::SMFNoteOff);
    connect(m_smfReader, &drumstick::QSmf::signalSMFKeyPress, this, &MidiSequencer::SMFKeyPress);
    connect(m_smfReader, &drumstick::QSmf::signalSMFCtlChange, this, &MidiSequencer::SMFCtlChange);
    connect(m_smfReader, &drumstick::QSmf::signalSMFPitchBend, this, &MidiSequencer::SMFPitchBend);
    connect(m_smfReader, &drumstick::QSmf::signalSMFProgram, this, &MidiSequencer::SMFProgram);
    connect(m_smfReader, &drumstick::QSmf::signalSMFChanPress, this, &MidiSequencer::SMFChanPress);
    connect(m_smfReader, &drumstick::QSmf::signalSMFSysex, this, &MidiSequencer::SMFSysex);
    connect(m_smfReader, &drumstick::QSmf::signalSMFText, this, &MidiSequencer::SMFText);
    connect(m_smfReader, &drumstick::QSmf::signalSMFTempo, this, &MidiSequencer::SMFTempo);
    connect(m_smfReader, &drumstick::QSmf::signalSMFTimeSig, this, &MidiSequencer::SMFTimeSig);
    connect(m_smfReader, &drumstick::QSmf::signalSMFKeySig, this, &MidiSequencer::SMFKeySig);
    connect(m_smfReader, &drumstick::QSmf::signalSMFError, this, &MidiSequencer::SMFError);

    // OutputThread
    m_midiSequencerOutputThread = new MidiSequencerOutputThread(m_client, m_outputPortId);
    connect(m_midiSequencerOutputThread, &MidiSequencerOutputThread::stopped, this, &MidiSequencer::outputThreadStopped);

    // Subscribe to TiMidity and Minuet's virtual piano
    subscribeTo("TiMidity:0");
    subscribeTo("MinuetSequencer:1");
}

MidiSequencer::~MidiSequencer()
{
    m_client->stopSequencerInput();
    m_outputPort->detach();
    m_inputPort->detach();
    m_client->close();
    delete m_midiSequencerOutputThread;
    delete m_song;
}

void MidiSequencer::subscribeTo(const QString &portName)
{
    try {
        m_outputPort->subscribeTo(portName);
    } catch (const drumstick::SequencerError &err) {
        throw err;
    }
}

void MidiSequencer::openFile(const QString &fileName)
{
    m_tick = 0;
    if (m_song) delete m_song;
    m_song = new Song();
    m_eventSchedulingMode = FROM_ENGINE;
    m_smfReader->readFromFile(fileName);
    emit tempoChanged(6.0e7f / m_song->initialTempo());
    m_song->sort();
    m_midiSequencerOutputThread->setSong(m_song);
}

void MidiSequencer::appendEvent(drumstick::SequencerEvent *ev, unsigned long tick)
{
    ev->setSource(m_outputPortId);
    if (ev->getSequencerType() != SND_SEQ_EVENT_TEMPO)
        ev->setSubscribers();
    ev->scheduleTick(m_queueId, tick, false);
    m_song->append(ev);
    if (tick > m_tick)
        m_tick = tick;
}

void MidiSequencer::play()
{
    if (!m_song->isEmpty() && !m_midiSequencerOutputThread->isRunning()) {
        if (m_eventSchedulingMode == EXPLICIT)
            m_midiSequencerOutputThread->setSong(m_song);
        m_midiSequencerOutputThread->start();
    }
}

void MidiSequencer::pause()
{
    if (m_midiSequencerOutputThread->isRunning()) {
        m_midiSequencerOutputThread->stop();
        m_midiSequencerOutputThread->setPosition(m_queue->getStatus().getTickTime());
    }
}

void MidiSequencer::stop()
{
    m_midiSequencerOutputThread->stop();
    m_midiSequencerOutputThread->resetPosition();
    emit allNotesOff();
    emit timeLabelChanged("00:00.00");
}

void MidiSequencer::setVolumeFactor(unsigned int vol)
{
    m_midiSequencerOutputThread->setVolumeFactor(vol);
    emit volumeChanged(vol);
}

void MidiSequencer::setTempoFactor(unsigned int value)
{
    float tempoFactor = (value*value + 100.0*value + 20000.0) / 40000.0;
    drumstick::QueueTempo queueTempo = m_queue->getTempo();
    queueTempo.setTempoFactor(tempoFactor);
    m_queue->setTempo(queueTempo);
    m_client->drainOutput();
    emit tempoChanged(queueTempo.getRealBPM());
}

void MidiSequencer::setPitchShift(unsigned int value)
{
    m_midiSequencerOutputThread->setPitchShift(value);
    emit allNotesOff();
    emit pitchChanged(value);
}

void MidiSequencer::setSong(Song *song)
{
    delete m_song;
    m_song = song;
    m_eventSchedulingMode = EXPLICIT;
}

void MidiSequencer::SMFHeader(int format, int ntrks, int division)
{
    m_song->setHeader(format, ntrks, division);
}

drumstick::SequencerEvent *MidiSequencer::SMFNoteOn(int chan, int pitch, int vel)
{
    drumstick::SequencerEvent *ev = new drumstick::NoteOnEvent(chan, pitch, vel);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFNoteOff(int chan, int pitch, int vel)
{
    drumstick::SequencerEvent *ev = new drumstick::NoteOffEvent(chan, pitch, vel);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFKeyPress(int chan, int pitch, int press)
{
    drumstick::SequencerEvent *ev = new drumstick::KeyPressEvent(chan, pitch, press);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFCtlChange(int chan, int ctl, int value)
{
    drumstick::SequencerEvent *ev = new drumstick::ControllerEvent(chan, ctl, value);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFPitchBend(int chan, int value)
{
    drumstick::SequencerEvent *ev =new drumstick::PitchBendEvent(chan, value);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFProgram(int chan, int patch)
{
    drumstick::SequencerEvent *ev = new drumstick::ProgramChangeEvent(chan, patch);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFChanPress(int chan, int press)
{
    drumstick::SequencerEvent *ev = new drumstick::ChanPressEvent(chan, press);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFSysex(const QByteArray &data)
{
    drumstick::SequencerEvent *ev = new drumstick::SysExEvent(data);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
   return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFText(int typ, const QString &data)
{
    Q_UNUSED(typ);
    Q_UNUSED(data);
    return 0;
}

drumstick::SequencerEvent *MidiSequencer::SMFTempo(int tempo)
{
    if (m_song->initialTempo() == 0)
        m_song->setInitialTempo(tempo);
    drumstick::SequencerEvent *ev = new drumstick::TempoEvent(m_queueId, tempo);
    if (m_eventSchedulingMode == FROM_ENGINE) appendEvent(ev);
    return ev;
}

drumstick::SequencerEvent *MidiSequencer::SMFTimeSig(int b0, int b1, int b2, int b3)
{
    Q_UNUSED(b0);
    Q_UNUSED(b1);
    Q_UNUSED(b2);
    Q_UNUSED(b3);
    return 0;
}

drumstick::SequencerEvent *MidiSequencer::SMFKeySig(int b0, int b1)
{
    Q_UNUSED(b0);
    Q_UNUSED(b1);
    return 0;
}

void MidiSequencer::SMFError(const QString &errorStr)
{
    Q_UNUSED(errorStr);
}

void MidiSequencer::eventReceived(drumstick::SequencerEvent *ev)
{
    static QChar fill('0');
    drumstick::KeyEvent *kev;
    if (!(kev = static_cast<drumstick::KeyEvent*>(ev)))
        return;
    if (kev->getSequencerType() == SND_SEQ_EVENT_NOTEON)
        emit noteOn(kev->getChannel(), kev->getKey(), kev->getVelocity());
    if (kev->getSequencerType() == SND_SEQ_EVENT_NOTEOFF)
        emit noteOff(kev->getChannel(), kev->getKey(), kev->getVelocity());
    
    if (m_tick != 0 && m_midiSequencerOutputThread->isRunning()) {
        const snd_seq_real_time_t *rt = m_queue->getStatus().getRealtime();
        int mins = rt->tv_sec / 60;
        int secs = rt->tv_sec % 60;
        int cnts = qFloor( rt->tv_nsec / 1.0e7 );
        emit timeLabelChanged(QString("%1:%2.%3").arg(mins,2,10,fill).arg(secs,2,10,fill).arg(cnts,2,10,fill));
    }
}

void MidiSequencer::outputThreadStopped()
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

void MidiSequencer::appendEvent(drumstick::SequencerEvent *ev)
{
    appendEvent(ev, m_smfReader->getCurrentTime());
}

#include "midisequencer.moc"
