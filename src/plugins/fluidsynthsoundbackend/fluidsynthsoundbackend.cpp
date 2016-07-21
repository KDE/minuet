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

#include <QDebug>
#include <QJsonObject>
#include <QStandardPaths>

FluidSynthSoundBackend::FluidSynthSoundBackend(QObject *parent)
    : Minuet::ISoundBackend(parent),
      m_song(0)
{
    fluid_settings_t *settings;
    settings = new_fluid_settings();
    fluid_settings_setstr(settings, "synth.reverb.active", "no");
    fluid_settings_setstr(settings, "synth.chorus.active", "no");

    m_synth = new_fluid_synth(settings);
    fluid_settings_setstr(settings, "audio.driver", "alsa");
    m_adriver = new_fluid_audio_driver(settings, m_synth);
    m_sequencer = new_fluid_sequencer2(0);

    // register synth as first destination
    m_synthSeqID = fluid_sequencer_register_fluidsynth(m_sequencer, m_synth);

    // load soundfont
    int fluid_res = fluid_synth_sfload(m_synth, QStandardPaths::locate(QStandardPaths::AppDataLocation, QStringLiteral("soundfonts/GeneralUser-v1.47.sf2")).toLatin1(), 1);
    if (fluid_res == FLUID_FAILED)
        qDebug() << "Error when loading soundfont!";
    
    m_tempo = 120;
}

FluidSynthSoundBackend::~FluidSynthSoundBackend()
{
    delete_fluid_sequencer(m_sequencer);
    delete_fluid_audio_driver(m_adriver);
    delete_fluid_synth(m_synth);
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
                appendEvent(1, chosenRootNote + additionalNote.toInt(), 127, 1000*(60.0/m_tempo));
        }
        else {
            appendEvent(9, 80, 127, 1000*(60.0/m_tempo));
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
    if (m_playMode == "rhythm")
        appendEvent(9, 80, 127, 1000*(60.0/m_tempo));
}

void FluidSynthSoundBackend::prepareFromMidiFile(const QString &fileName)
{
    Q_UNUSED(fileName)
}

void FluidSynthSoundBackend::play()
{
    unsigned int now = fluid_sequencer_get_tick(m_sequencer);
    foreach(fluid_event_t *event, *m_song.data()) {
        fluid_sequencer_send_at(m_sequencer, event, now, 1);
        now += (m_playMode == "rhythm") ? fluid_event_get_duration(event):
                   (m_playMode == "scale") ? 1000*(60.0/m_tempo):0;
    }
}

void FluidSynthSoundBackend::pause()
{
}

void FluidSynthSoundBackend::stop()
{
}

void FluidSynthSoundBackend::appendEvent(int channel, short key, short velocity, unsigned int duration) 
{
    fluid_event_t *event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_set_dest(event, m_synthSeqID);
    fluid_event_note(event, channel, key, velocity, duration);
    m_song->append(event);
}

#include "moc_fluidsynthsoundbackend.cpp"
