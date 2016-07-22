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

#include "fluidsynthsoundbackend.h"

#include <QtMath>
#include <QDebug>
#include <QJsonObject>
#include <QStandardPaths>

#include <functional>

unsigned int FluidSynthSoundBackend::m_initialTime = 0;

FluidSynthSoundBackend::FluidSynthSoundBackend(QObject *parent)
    : Minuet::ISoundBackend(parent),
      m_audioDriver(0),
      m_sequencer(0),
      m_song(0)
{
    m_tempo = 120;

    m_settings = new_fluid_settings();
    fluid_settings_setstr(m_settings, "synth.reverb.active", "no");
    fluid_settings_setstr(m_settings, "synth.chorus.active", "no");

    m_synth = new_fluid_synth(m_settings);

    int fluid_res = fluid_synth_sfload(m_synth, QStandardPaths::locate(QStandardPaths::AppDataLocation, QStringLiteral("soundfonts/GeneralUser-v1.47.sf2")).toLatin1(), 1);
    if (fluid_res == FLUID_FAILED)
        qDebug() << "Error when loading soundfont!";

    resetEngine();
}

FluidSynthSoundBackend::~FluidSynthSoundBackend()
{
    deleteEngine();
    if (m_synth) delete_fluid_synth(m_synth);
    if (m_settings) delete_fluid_settings(m_settings);
}

void FluidSynthSoundBackend::setPitch(qint8 pitch)
{
    Q_UNUSED(pitch);
}

void FluidSynthSoundBackend::setVolume(quint8 volume)
{
    Q_UNUSED(volume);
}

void FluidSynthSoundBackend::setTempo (quint8 tempo)
{
    Q_UNUSED(tempo);
}

void FluidSynthSoundBackend::prepareFromExerciseOptions(QJsonArray selectedExerciseOptions)
{
    QList<fluid_event_t *> *song = new QList<fluid_event_t *>;
    m_song.reset(song);

    if (m_playMode == "rhythm")
        for (int i = 0; i < 4; ++i)
            appendEvent(9, 80, 127, 1000*(60.0/m_tempo));

    for (int i = 0; i < selectedExerciseOptions.size(); ++i) {
        QString sequence = selectedExerciseOptions[i].toObject()[QStringLiteral("sequence")].toString();

        unsigned int chosenRootNote = selectedExerciseOptions[i].toObject()[QStringLiteral("rootNote")].toString().toInt();
        if (m_playMode != "rhythm") {
            appendEvent(1, chosenRootNote, 127, 1000*(60.0/m_tempo));
            foreach(const QString &additionalNote, sequence.split(' '))
                appendEvent(1, chosenRootNote + additionalNote.toInt(), 127, ((m_playMode == "scale") ? 1000:4000)*(60.0/m_tempo));
        }
        else {
            //appendEvent(9, 80, 127, 1000*(60.0/m_tempo));
            foreach(QString additionalNote, sequence.split(' ')) { // krazy:exclude=foreach
                float dotted = 1;
                if (additionalNote.endsWith('.')) {
                    dotted = 1.5;
                    additionalNote.chop(1);
                }
                unsigned int duration = dotted*1000*(60.0/m_tempo)*(4.0/additionalNote.toInt());
                appendEvent(9, 37, 127, duration);
            }
        }
    }
    //if (m_playMode == "rhythm")
    //    appendEvent(9, 80, 127, 1000*(60.0/m_tempo));

    fluid_event_t *event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_all_notes_off(event, 1);
    m_song->append(event);
}

void FluidSynthSoundBackend::prepareFromMidiFile(const QString &fileName)
{
    Q_UNUSED(fileName)
}

void FluidSynthSoundBackend::play()
{
    if (!m_song.data())
        return;

    if (m_state != PlayingState) {
        unsigned int now = fluid_sequencer_get_tick(m_sequencer);
        foreach(fluid_event_t *event, *m_song.data()) {
            if (fluid_event_get_type(event) != FLUID_SEQ_ALLNOTESOFF || m_playMode != "chord") {
                fluid_event_set_dest(event, m_synthSeqID);
                fluid_sequencer_send_at(m_sequencer, event, now, 1);
            }
            fluid_event_set_dest(event, m_callbackSeqID);
            fluid_sequencer_send_at(m_sequencer, event, now, 1);
            now += (m_playMode == "rhythm") ? fluid_event_get_duration(event):
                (m_playMode == "scale")  ? 1000*(60.0/m_tempo):0;
        }
        setState(PlayingState);
    }
}

void FluidSynthSoundBackend::pause()
{
}

void FluidSynthSoundBackend::stop()
{
    if (m_state != StoppedState) {
        fluid_event_t *event = new_fluid_event();
        fluid_event_set_source(event, -1);
        fluid_event_all_notes_off(event, 1);
        fluid_event_set_dest(event, m_synthSeqID);
        fluid_sequencer_send_now(m_sequencer, event);
        resetEngine();
    }
}

void FluidSynthSoundBackend::reset()
{
    stop();
    m_song.reset(0);
}

void FluidSynthSoundBackend::appendEvent(int channel, short key, short velocity, unsigned int duration) 
{
    fluid_event_t *event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_note(event, channel, key, velocity, duration);
    m_song->append(event);
}

void FluidSynthSoundBackend::sequencerCallback(unsigned int time, fluid_event_t *event, fluid_sequencer_t *seq, void *data)
{
    Q_UNUSED(seq);

    // This is safe!
    FluidSynthSoundBackend *soundBackend = reinterpret_cast<FluidSynthSoundBackend *>(data);

    int eventType = fluid_event_get_type(event);
    switch (eventType) {
        case FLUID_SEQ_NOTE: {
            if (m_initialTime == 0)
                m_initialTime = time;
            double adjustedTime = (time - m_initialTime)/1000.0;
            int mins = adjustedTime / 60;
            int secs = ((int)adjustedTime) % 60;
            int cnts = 100*(adjustedTime-qFloor(adjustedTime));

            static QChar fill('0');
            soundBackend->setPlaybackLabel(QStringLiteral("%1:%2.%3").arg(mins, 2, 10, fill).arg(secs, 2, 10, fill).arg(cnts, 2, 10, fill));
            break;
        }
        case FLUID_SEQ_ALLNOTESOFF: {
            m_initialTime = 0;
            soundBackend->setPlaybackLabel(QStringLiteral("00:00.00"));
            soundBackend->setState(StoppedState);
            break;
        }
    }
}

void FluidSynthSoundBackend::resetEngine()
{
    deleteEngine();
    fluid_settings_setstr(m_settings, "audio.driver", "pulseaudio");
    m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
    if (!m_audioDriver) {
        fluid_settings_setstr(m_settings, "audio.driver", "alsa");
        m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
    }
    if (!m_audioDriver) {
        qDebug() << "Couldn't start audio driver!";
    }

    m_sequencer = new_fluid_sequencer2(0);
    m_synthSeqID = fluid_sequencer_register_fluidsynth(m_sequencer, m_synth);
    m_callbackSeqID = fluid_sequencer_register_client (m_sequencer, "Minuet Fluidsynth Sound Backend", &FluidSynthSoundBackend::sequencerCallback, this);

    m_initialTime = 0;
    setPlaybackLabel(QStringLiteral("00:00.00"));
    setState(StoppedState);
}

void FluidSynthSoundBackend::deleteEngine()
{
    if (m_sequencer) delete_fluid_sequencer(m_sequencer);
    if (m_audioDriver) delete_fluid_audio_driver(m_audioDriver);
}

#include "moc_fluidsynthsoundbackend.cpp"
