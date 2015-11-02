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

#ifndef MIDISEQUENCEROUTPUTTHREAD_H
#define MIDISEQUENCEROUTPUTTHREAD_H

#include <drumstick/playthread.h>

namespace drumstick {
    class MidiClient;
}

class Song;

class MidiSequencerOutputThread : public drumstick::SequencerOutputThread
{
public:
    MidiSequencerOutputThread(drumstick::MidiClient *client, int portId);
    virtual ~MidiSequencerOutputThread();
    
    // Virtual methods from drumstick::SequencerOutputThread
    virtual bool hasNext();
    virtual drumstick::SequencerEvent *nextEvent();
    virtual unsigned int getInitialPosition() { return m_songPosition; }

    void setSong(Song *song);
    void setVolumeFactor(unsigned int vol);
    void setPitchShift(unsigned int value);
    void setPosition(unsigned int pos);
    void resetPosition();

Q_SIGNALS:
    void allNotesoff();

private:
    void allNotesOff();
    void sendControllerEvent(int chan, int control, int value);
    
private:
    drumstick::MidiClient *m_client;
    Song *m_song;
    unsigned int m_songPosition;
    drumstick::SequencerEvent *m_lastEvent;
    int m_volume[MIDI_CHANNELS];
    unsigned int m_volumeFactor;
    unsigned int m_pitchShift;
    QListIterator<drumstick::SequencerEvent *>* m_songIterator;
};

#endif // MIDISEQUENCEROUTPUTTHREAD_H
