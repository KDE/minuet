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

#ifndef MIDISEQUENCER_H
#define MIDISEQUENCER_H

#include "song.h"

#include <QObject>

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

    Q_PROPERTY(int pitch READ pitch WRITE setPitch NOTIFY pitchChanged)
    Q_PROPERTY(unsigned int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(unsigned int tempo READ tempo WRITE setTempo NOTIFY tempoChanged)
    Q_PROPERTY(QString playbackLabel READ playbackLabel WRITE setPlaybackLabel NOTIFY playbackLabelChanged)
    Q_ENUMS(State)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_ENUMS(PlayMode)

public:
    explicit MidiSequencer(QObject *parent = 0);
    virtual ~MidiSequencer();

    enum EventSchedulingMode {
        FROM_ENGINE = 0,
        EXPLICIT,
        DAMAGED
    };
    enum State {
        StoppedState = 0,
        PlayingState,
        PausedState
    };
    enum PlayMode {
        ScalePlayMode = 0,
        ChordPlayMode,
        RhythmPlayMode
    };

    void subscribeTo(const QString &portName);
    void openFile(const QString &fileName);
    void appendEvent(drumstick::SequencerEvent *ev, unsigned long tick);
    QStringList availableOutputPorts() const;
    EventSchedulingMode schedulingMode() const;

    int pitch() const;
    unsigned int volume() const;
    unsigned int tempo() const;
    QString playbackLabel() const;
    State state() const;

Q_SIGNALS:
    void noteOn(int chan, int pitch, int vel);
    void noteOff(int chan, int pitch, int vel);
    void allNotesOff();
    void pitchChanged();
    void volumeChanged();
    void tempoChanged();
    void playbackLabelChanged();
    void stateChanged();

public Q_SLOTS:
    void play();
    void pause();
    void stop();
    void setPitch(int pitch);
    void setVolume(unsigned int volume);
    void setTempo(unsigned int tempo);
    void setPlaybackLabel(QString playbackLabel);
    void setState(State state);
    void setSong(Song *song);
    void clearSong();
    void generateSong(QJsonArray selectedOptions);
    void setPlayMode(PlayMode playMode);

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
    void resetMidiPlayer();

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
    QString m_playbackLabel;
    State m_state;
    PlayMode m_playMode;
};

#endif // MIDISEQUENCER_H

