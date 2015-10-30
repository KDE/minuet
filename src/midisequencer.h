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

#ifndef MIDISEQUENCER_H
#define MIDISEQUENCER_H

#include <QtCore/QObject>

#include <QtCore/QList>

#include <drumstick/alsaqueue.h>

namespace drumstick {
    class QSmf;
    class MidiClient;
    class MidiPort;
    class SequencerEvent;
}

class MidiSequencer : public QObject
{
    Q_OBJECT

public:
    MidiSequencer(QObject *parent = 0);
    virtual ~MidiSequencer();

    void subscribeTo(const QString &portName);
    void play(const QString &fileName);

private Q_SLOTS:
    void SMFHeader(int format, int ntrks, int division);
    void SMFNoteOn(int chan, int pitch, int vol);
    void SMFNoteOff(int chan, int pitch, int vol);
    void SMFKeyPress(int chan, int pitch, int press);
    void SMFCtlChange(int chan, int ctl, int value);
    void SMFPitchBend(int chan, int value);
    void SMFProgram(int chan, int patch);
    void SMFChanPress(int chan, int press);
    void SMFSysex(const QByteArray &data);
    void SMFText(int typ, const QString &data);
    void SMFTempo(int tempo);
    void SMFTimeSig(int b0, int b1, int b2, int b3);
    void SMFKeySig(int b0, int b1);
    void SMFError(const QString &errorStr);

private:
    void appendEvent(drumstick::SequencerEvent *ev);
    
private:
    int m_portId;
    int m_queueId;
    drumstick::MidiPort *m_port;
    drumstick::QSmf *m_smfReader;
    drumstick::MidiQueue *m_queue;
    drumstick::QueueTempo m_firstTempo;
    drumstick::MidiClient *m_client;
};

#endif // MIDISEQUENCER_H
