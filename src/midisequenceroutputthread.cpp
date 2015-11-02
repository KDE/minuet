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

#include "midisequenceroutputthread.h"

#include <drumstick/alsaqueue.h>
#include <drumstick/alsaclient.h>

#include "song.h"

MidiSequencerOutputThread::MidiSequencerOutputThread(drumstick::MidiClient *midiClient, int portId) :
    drumstick::SequencerOutputThread(midiClient, portId),
    m_midiClient(midiClient),
    m_song(0),
    m_songIterator(0)
{
    for (int chan = 0; chan < MIDI_CHANNELS; ++chan)
    m_volume[chan] = 100;
}

MidiSequencerOutputThread::~MidiSequencerOutputThread()
{
}

void MidiSequencerOutputThread::setSong(Song *song)
{
    m_song = song;
    if (m_songIterator)
        delete m_songIterator;
    m_songIterator = new QListIterator<drumstick::SequencerEvent *>(*song);
    drumstick::MidiQueue *midiQueue = m_midiClient->getQueue();
    drumstick::QueueTempo firstTempo = midiQueue->getTempo();
    firstTempo.setPPQ(m_song->division());
    firstTempo.setTempo(song->initialTempo());
    firstTempo.setTempoFactor(1.0);
    midiQueue->setTempo(firstTempo);
}

void MidiSequencerOutputThread::setVolumeFactor(unsigned int vol)
{
    for(int chan = 0; chan < MIDI_CHANNELS; ++chan) {
        int value = m_volume[chan];
        value = floor(value*vol/100.0);
        if (value < 0) value = 0;
        if (value > 127) value = 127;
        sendControllerEvent(chan, MIDI_CTL_MSB_MAIN_VOLUME, value);
    }
}

bool MidiSequencerOutputThread::hasNext()
{
    return m_songIterator->hasNext();
}

drumstick::SequencerEvent *MidiSequencerOutputThread::nextEvent()
{
    return m_songIterator->next()->clone();
}

void MidiSequencerOutputThread::sendControllerEvent(int chan, int control, int value)
{
    drumstick::ControllerEvent ev(chan, control, value);
    ev.setSource(m_PortId);
    ev.setSubscribers();
    ev.setDirect();
    sendSongEvent(&ev);
}
