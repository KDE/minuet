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

#include "midisequenceroutputthread.h"

#include "song.h"

#include <drumstick/alsaqueue.h>

MidiSequencerOutputThread::MidiSequencerOutputThread(drumstick::MidiClient *client, int portId) :
    drumstick::SequencerOutputThread(client, portId),
    m_client(client),
    m_song(0),
    m_songPosition(0),
    m_lastEvent(0), 
    m_volumeFactor(100),
    m_pitchShift(0),
    m_songIterator(0)
{
    for (int chan = 0; chan < MIDI_CHANNELS; ++chan)
        m_volume[chan] = 100;
}

MidiSequencerOutputThread::~MidiSequencerOutputThread()
{
    if (isRunning())
        stop();
    if (m_songIterator != 0)
        delete m_songIterator;
    if (m_lastEvent != 0)
        delete m_lastEvent;
}

bool MidiSequencerOutputThread::hasNext()
{
    return m_songIterator->hasNext();
}

drumstick::SequencerEvent *MidiSequencerOutputThread::nextEvent()
{
    if (m_lastEvent != 0)
        delete m_lastEvent;

    m_lastEvent = m_songIterator->next()->clone();
    switch (m_lastEvent->getSequencerType()) {
        case SND_SEQ_EVENT_NOTE:
        case SND_SEQ_EVENT_NOTEON:
        case SND_SEQ_EVENT_NOTEOFF:
        case SND_SEQ_EVENT_KEYPRESS: {
            drumstick::KeyEvent *kev = static_cast<drumstick::KeyEvent*>(m_lastEvent);
            if (kev->getChannel() != MIDI_GM_DRUM_CHANNEL)
                kev->setKey(kev->getKey() + m_pitchShift);
        }
        break;
        case SND_SEQ_EVENT_CONTROLLER: {
            drumstick::ControllerEvent *cev = static_cast<drumstick::ControllerEvent*>(m_lastEvent);
            if (cev->getParam() == MIDI_CTL_MSB_MAIN_VOLUME) {
                int chan = cev->getChannel();
                int value = cev->getValue();
                m_volume[chan] = value;
                value = floor(value * m_volumeFactor / 100.0);
                if (value < 0) value = 0;
                if (value > 127) value = 127;
                cev->setValue(value);
            }
        }
        break;
    }
    return m_lastEvent;
}

void MidiSequencerOutputThread::setSong(Song *song)
{
    m_song = song;
    if (m_songIterator)
        delete m_songIterator;
    m_songIterator = new QListIterator<drumstick::SequencerEvent *>(*song);
    m_songPosition = 0;
    drumstick::QueueTempo firstTempo = m_Queue->getTempo();
    firstTempo.setPPQ(m_song->division());
    firstTempo.setTempo(m_song->initialTempo());
    firstTempo.setTempoFactor(1.0);
    m_Queue->setTempo(firstTempo);
}

void MidiSequencerOutputThread::setVolumeFactor(unsigned int vol)
{
    m_volumeFactor = vol;
    for(int chan = 0; chan < MIDI_CHANNELS; ++chan) {
        int value = m_volume[chan];
        value = floor(value * m_volumeFactor / 100.0);
        if (value < 0) value = 0;
        if (value > 127) value = 127;
        sendControllerEvent(chan, MIDI_CTL_MSB_MAIN_VOLUME, value);
    }
}

void MidiSequencerOutputThread::setPitchShift(int value)
{
    bool playing = isRunning();
    if (playing) {
        stop();
        unsigned int pos = m_Queue->getStatus().getTickTime();
        m_Queue->clear();
        allNotesOff();
        setPosition(pos);
    }
    m_pitchShift = value;
    if (playing)
        start();
}

void MidiSequencerOutputThread::setPosition(unsigned int pos)
{
    m_songPosition = pos;
    m_songIterator->toFront();
    while (m_songIterator->hasNext() && (m_songIterator->next()->getTick() < pos)) { };
    if (m_songIterator->hasPrevious())
        m_songIterator->previous();
}

void MidiSequencerOutputThread::resetPosition()
{
    if ((m_song != NULL) && (m_songIterator != NULL)) {
        m_songIterator->toFront();
        m_songPosition = 0;
    }
}

void MidiSequencerOutputThread::allNotesOff()
{
    for(int chan = 0; chan < MIDI_CHANNELS; ++chan) {
        sendControllerEvent(chan, MIDI_CTL_ALL_NOTES_OFF, 0);
        sendControllerEvent(chan, MIDI_CTL_ALL_SOUNDS_OFF, 0);
    }
}

void MidiSequencerOutputThread::sendControllerEvent(int chan, int control, int value)
{
    drumstick::ControllerEvent ev(chan, control, value);
    ev.setSource(m_PortId);
    ev.setSubscribers();
    ev.setDirect();
    sendSongEvent(&ev);
}
