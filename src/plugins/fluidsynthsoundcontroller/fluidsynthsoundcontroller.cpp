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

#include "fluidsynthsoundcontroller.h"

#include <QUrl>
#include <QtMath>
#include <QDebug>
#include <QJsonObject>
#include <QStandardPaths>

unsigned int FluidSynthSoundController::m_initialTime = 0;

FluidSynthSoundController::FluidSynthSoundController(QObject *parent)
    : Minuet::ISoundController(parent),
      m_audioDriver(0),
      m_sequencer(0),
      m_song(0)
{
    m_tempo = 60;

    m_settings = new_fluid_settings();
    fluid_settings_setstr(m_settings, "synth.reverb.active", "no");
    fluid_settings_setstr(m_settings, "synth.chorus.active", "no");

    m_synth = new_fluid_synth(m_settings);

    fluid_synth_cc(m_synth, 1, 100, 0);

#ifdef Q_OS_WIN
    const QString sf_path = QStandardPaths::locate(QStandardPaths::AppDataLocation, QStringLiteral("minuet/soundfonts/GeneralUser-v1.47.sf2"));
#else
    const QString sf_path = QStandardPaths::locate(QStandardPaths::AppDataLocation, QStringLiteral("soundfonts/GeneralUser-v1.47.sf2"));
#endif
    int fluid_res = fluid_synth_sfload(m_synth, sf_path.toLatin1(), 1);
    if (fluid_res == FLUID_FAILED)
        qCritical() << "Error when loading soundfont!";

    resetEngine();
}

FluidSynthSoundController::~FluidSynthSoundController()
{
    deleteEngine();
    if (m_synth) delete_fluid_synth(m_synth);
    if (m_settings) delete_fluid_settings(m_settings);
}

void FluidSynthSoundController::setPitch(qint8 pitch)
{
    m_pitch = pitch;
    fluid_synth_cc(m_synth, 1, 101, 0);
    fluid_synth_cc(m_synth, 1, 6, 12);
    float accurate_pitch = (m_pitch + 12) * (2.0 / 3) * 1024;
    fluid_synth_pitch_bend(m_synth, 1, qMin(qRound(accurate_pitch), 16 * 1024 - 1));
}

void FluidSynthSoundController::setVolume(quint8 volume)
{
    m_volume = volume;
    fluid_synth_cc(m_synth, 1, 7, m_volume * 127 / 200);
}

void FluidSynthSoundController::setTempo (quint8 tempo)
{
    m_tempo = tempo;
}

void FluidSynthSoundController::prepareFromExerciseOptions(QJsonArray selectedExerciseOptions)
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

void FluidSynthSoundController::prepareFromMidiFile(const QString &fileName)
{
    Q_UNUSED(fileName)
}

void FluidSynthSoundController::play()
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

void FluidSynthSoundController::pause()
{
}

void FluidSynthSoundController::stop()
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

void FluidSynthSoundController::reset()
{
    stop();
    m_song.reset(0);
}

void FluidSynthSoundController::appendEvent(int channel, short key, short velocity, unsigned int duration) 
{
    fluid_event_t *event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_note(event, channel, key, velocity, duration);
    m_song->append(event);
}

void FluidSynthSoundController::sequencerCallback(unsigned int time, fluid_event_t *event, fluid_sequencer_t *seq, void *data)
{
    Q_UNUSED(seq);

    // This is safe!
    FluidSynthSoundController *soundController = reinterpret_cast<FluidSynthSoundController *>(data);

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
            soundController->setPlaybackLabel(QStringLiteral("%1:%2.%3").arg(mins, 2, 10, fill).arg(secs, 2, 10, fill).arg(cnts, 2, 10, fill));
            break;
        }
        case FLUID_SEQ_ALLNOTESOFF: {
            m_initialTime = 0;
            soundController->setPlaybackLabel(QStringLiteral("00:00.00"));
            soundController->setState(StoppedState);
            break;
        }
    }
}

void FluidSynthSoundController::resetEngine()
{
    deleteEngine();
#ifdef Q_OS_LINUX
    fluid_settings_setstr(m_settings, "audio.driver", "pulseaudio");
#endif
#ifdef Q_OS_WIN
    fluid_settings_setstr(m_settings, "audio.driver", "dsound");
#endif
    m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
    if (!m_audioDriver) {
        fluid_settings_setstr(m_settings, "audio.driver", "alsa");
        m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
    }
    if (!m_audioDriver) {
        qCritical() << "Couldn't start audio driver!";
    }

    m_sequencer = new_fluid_sequencer2(0);
    m_synthSeqID = fluid_sequencer_register_fluidsynth(m_sequencer, m_synth);
    m_callbackSeqID = fluid_sequencer_register_client (m_sequencer, "Minuet Fluidsynth Sound Controller", &FluidSynthSoundController::sequencerCallback, this);

    m_initialTime = 0;
    setPlaybackLabel(QStringLiteral("00:00.00"));
    setState(StoppedState);
}

void FluidSynthSoundController::deleteEngine()
{
    if (m_sequencer) delete_fluid_sequencer(m_sequencer);
    if (m_audioDriver) delete_fluid_audio_driver(m_audioDriver);
}

