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

#include "song.h"

MidiSequencerOutputThread::MidiSequencerOutputThread(drumstick::MidiClient *seq, int portId) :
    drumstick::SequencerOutputThread(seq, portId),
    m_song(0),
    m_songIterator(0)
{
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
}

bool MidiSequencerOutputThread::hasNext()
{
    qDebug() << "hasNext() returns " << m_songIterator->hasNext();
    return m_songIterator->hasNext();
}

drumstick::SequencerEvent *MidiSequencerOutputThread::nextEvent()
{
    qDebug() << "nextEvent()";
    return m_songIterator->next()->clone();
}
