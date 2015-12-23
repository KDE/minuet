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

#include "song.h"

#include <QtCore/QObject>

#include <drumstick/alsaqueue.h>

namespace drumstick {
    class QSmf;
    class MidiClient;
    class MidiPort;
    class SequencerEvent;
}

class MidiSequencerOutputThread;

class MidiSequencer : public QObject
{
    Q_OBJECT

public:
    MidiSequencer(QObject *parent = 0);
    virtual ~MidiSequencer();

    void subscribeTo(const QString &portName);
    void openFile(const QString &fileName);
    void appendEvent(drumstick::SequencerEvent *ev, unsigned long tick);
    QStringList availableOutputPorts() const;
    
    enum EventSchedulingMode {
        FROM_ENGINE = 0,
        EXPLICIT
    };

Q_SIGNALS:
    void noteOn(int chan, int pitch, int vel);
    void noteOff(int chan, int pitch, int vel);
    void allNotesOff();
    void timeLabelChanged(QString timeLabel);
    void volumeChanged(unsigned int vol);
    void tempoChanged(unsigned int vol);
    void pitchChanged(unsigned int vol);
    
public Q_SLOTS:
    void play();
    void pause();
    void stop();
    void setVolumeFactor(unsigned int vol);
    void setTempoFactor(unsigned int value);
    void setPitchShift(unsigned int value);
    void setSong(Song *song);
    
    // Slots for events generated when reading a MIDI file
    void SMFHeader(int format, int ntrks, int division);
    drumstick::SequencerEvent *SMFNoteOn(int chan, int pitch, int vel);
    drumstick::SequencerEvent *SMFNoteOff(int chan, int pitch, int vel);
    drumstick::SequencerEvent *SMFKeyPress(int chan, int pitch, int press);
    drumstick::SequencerEvent *SMFCtlChange(int chan, int ctl, int value);
    drumstick::SequencerEvent *SMFPitchBend(int chan, int value);
    drumstick::SequencerEvent *SMFProgram(int chan, int patch);
    drumstick::SequencerEvent *SMFChanPress(int chan, int press);
    drumstick::SequencerEvent *SMFSysex(const QByteArray &data);
    drumstick::SequencerEvent *SMFText(int typ, const QString &data);
    drumstick::SequencerEvent *SMFTempo(int tempo);
    drumstick::SequencerEvent *SMFTimeSig(int b0, int b1, int b2, int b3);
    drumstick::SequencerEvent *SMFKeySig(int b0, int b1);
    void SMFError(const QString &errorStr);

private Q_SLOTS:
    // Slots for events generated when playing a MIDI
    void eventReceived(drumstick::SequencerEvent *ev);

    void outputThreadStopped();

private:
    void appendEvent(drumstick::SequencerEvent *ev);

private:
    int m_outputPortId;
    int m_inputPortId;
    int m_queueId;
    unsigned long m_tick;
    Song *m_song;
    drumstick::MidiPort *m_outputPort;
    drumstick::MidiPort *m_inputPort;
    drumstick::QSmf *m_smfReader;
    drumstick::MidiQueue *m_queue;
    drumstick::QueueTempo m_firstTempo;
    drumstick::MidiClient *m_client;
    MidiSequencerOutputThread *m_midiSequencerOutputThread;
    EventSchedulingMode m_eventSchedulingMode;
    QString m_currentSubscribedPort;
};

#endif // MIDISEQUENCER_H