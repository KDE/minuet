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

#ifndef MINUET_FLUIDSYNTHSOUNDCONTROLLER_H
#define MINUET_FLUIDSYNTHSOUNDCONTROLLER_H

#include <interfaces/isoundcontroller.h>

#include <fluidsynth.h>

class FluidSynthSoundController : public Minuet::ISoundController
{
    Q_OBJECT

    Q_PLUGIN_METADATA(IID "org.kde.minuet.IPlugin" FILE "fluidsynthsoundcontroller.json")
    Q_INTERFACES(Minuet::IPlugin)
    Q_INTERFACES(Minuet::ISoundController)

public:
    explicit FluidSynthSoundController(QObject *parent = 0);
    virtual ~FluidSynthSoundController() override;

public Q_SLOTS:
    virtual void setPitch(qint8 pitch) override;
    virtual void setVolume(quint8 volume) override;
    virtual void setTempo(quint8 tempo) override;

    virtual void prepareFromExerciseOptions(QJsonArray selectedExerciseOptions) override;
    virtual void prepareFromMidiFile(const QString &fileName) override;

    virtual void play() override;
    virtual void pause() override;
    virtual void stop() override;
    virtual void reset() override;

private:
    void appendEvent(int channel, short key, short velocity, unsigned int duration);
    static void sequencerCallback(unsigned int time, fluid_event_t *event, fluid_sequencer_t *seq,
                                  void *data);
    void resetEngine();
    void deleteEngine();

private:
    fluid_settings_t *m_settings;
    fluid_audio_driver_t *m_audioDriver;
    fluid_sequencer_t *m_sequencer;
    fluid_synth_t *m_synth;
    fluid_event_t *m_unregisteringEvent;

    short m_synthSeqID;
    short m_callbackSeqID;
    static unsigned int m_initialTime;

    QScopedPointer<QList<fluid_event_t *>> m_song;
};

#endif
