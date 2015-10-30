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

MidiSequencer::MidiSequencer(QObject *parent) :
    QObject(parent)
{
    m_client = new drumstick::MidiClient(this);
    m_client->open();
    m_client->setClientName("Minuet Sequencer");
    m_client->setPoolOutput(100);

    m_port = new drumstick::MidiPort(this);
    m_port->attach(m_client);
    m_port->setPortName("Minuet Sequencer Output Port");
    m_port->setCapability(SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ);
    m_port->setPortType(SND_SEQ_PORT_TYPE_APPLICATION);
    m_portId = m_port->getPortId();

    m_queue = m_client->createQueue();
    m_firstTempo = m_queue->getTempo();
    m_queueId = m_queue->getId();

    m_smfReader = new drumstick::QSmf(this);
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
    
    subscribeTo("TiMidity:0");
}

MidiSequencer::~MidiSequencer()
{
}

void MidiSequencer::subscribeTo(const QString &portName)
{
    try {
        m_port->subscribeTo(portName);
    } catch (const drumstick::SequencerError& err) {
        throw err;
    }
}

void MidiSequencer::play(const QString &fileName)
{
    m_smfReader->readFromFile(fileName);
    try {
        m_client->drainOutput();
        m_client->synchronizeOutput();
        m_queue->stop();
    } catch (const drumstick::SequencerError& err) {
        throw err;
    }
}

void MidiSequencer::SMFHeader(int format, int ntrks, int division)
{
    Q_UNUSED(format);
    Q_UNUSED(ntrks);
    m_firstTempo.setPPQ(division);
    m_queue->start();
}

void MidiSequencer::SMFNoteOn(int chan, int pitch, int vol)
{
    appendEvent(new drumstick::NoteOnEvent(chan, pitch, vol));
}

void MidiSequencer::SMFNoteOff(int chan, int pitch, int vol)
{
    appendEvent(new drumstick::NoteOffEvent(chan, pitch, vol));
}

void MidiSequencer::SMFKeyPress(int chan, int pitch, int press)
{
    appendEvent(new drumstick::KeyPressEvent(chan, pitch, press));
}

void MidiSequencer::SMFCtlChange(int chan, int ctl, int value)
{
    appendEvent(new drumstick::ControllerEvent(chan, ctl, value));
}

void MidiSequencer::SMFPitchBend(int chan, int value)
{
    appendEvent(new drumstick::PitchBendEvent(chan, value));
}

void MidiSequencer::SMFProgram(int chan, int patch)
{
    appendEvent(new drumstick::ProgramChangeEvent(chan, patch));
}

void MidiSequencer::SMFChanPress(int chan, int press)
{
    appendEvent(new drumstick::ChanPressEvent(chan, press));
}

void MidiSequencer::SMFSysex(const QByteArray& data)
{
    appendEvent(new drumstick::SysExEvent(data));
}

void MidiSequencer::SMFText(int typ, const QString& data)
{
    Q_UNUSED(typ);
    Q_UNUSED(data);
}

void MidiSequencer::SMFTempo(int tempo)
{
    m_firstTempo.setTempo(tempo);
    qDebug() << "Tempo: " << tempo;
    appendEvent(new drumstick::TempoEvent(m_queueId, tempo));
}

void MidiSequencer::SMFTimeSig(int b0, int b1, int b2, int b3)
{
    Q_UNUSED(b0);
    Q_UNUSED(b1);
    Q_UNUSED(b2);
    Q_UNUSED(b3);
}

void MidiSequencer::SMFKeySig(int b0, int b1)
{
    Q_UNUSED(b0);
    Q_UNUSED(b1);
}

void MidiSequencer::SMFError(const QString& errorStr)
{
    Q_UNUSED(errorStr);
}

void MidiSequencer::appendEvent(drumstick::SequencerEvent *ev)
{
    ev->setSource(m_portId);
    if (ev->getSequencerType() != SND_SEQ_EVENT_TEMPO)
        ev->setSubscribers();
    ev->scheduleTick(m_queueId, m_smfReader->getCurrentTime(), false);
    m_client->output(ev);
}

#include "midisequencer.moc"
