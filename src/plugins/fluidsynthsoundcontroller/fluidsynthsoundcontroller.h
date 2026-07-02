// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_FLUIDSYNTHSOUNDCONTROLLER_H
#define MINUET_FLUIDSYNTHSOUNDCONTROLLER_H

#include <interfaces/isoundcontroller.h>

#ifdef Q_OS_MACOS
#include <FluidSynth/fluidsynth.h>
#else
#include <fluidsynth.h>
#endif

#include <QHash>

class FluidSynthSoundController : public Minuet::ISoundController
{
    Q_OBJECT

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    Q_PLUGIN_METADATA(IID "org.kde.minuet.IPlugin" FILE "fluidsynthsoundcontroller.json")
#endif
    Q_INTERFACES(Minuet::IPlugin)
    Q_INTERFACES(Minuet::ISoundController)

public:
    explicit FluidSynthSoundController(QObject *parent = nullptr);
    ~FluidSynthSoundController() override;

public Q_SLOTS:
    void setPitch(qint8 pitch) override;
    void setVolume(quint8 volume) override;
    void setTempo(quint8 tempo) override;
    void setRhythmCountInBeats(int beats) override;
    void setInstrument(int instrument) override;
    void setRhythmInstrument(int rhythmInstrument) override;

    void prepareFromExerciseOptions(QJsonArray selectedExerciseOptions) override;
    void prepareFromMidiFile(const QString &fileName) override;
    void playCountIn(int beats) override;

    void play() override;
    void pause() override;
    void stop() override;
    void reset() override;

private:
    void appendEvent(int channel, short key, short velocity, unsigned int duration);
    static void sequencerCallback(unsigned int time, fluid_event_t *event, fluid_sequencer_t *seq, void *data);
    void populateInstruments();
    void populateRhythmInstruments();
    void applyInstrument();
    static QString instrumentGroupName(int group);
    static QString rhythmInstrumentName(int key);
    void hideCountIn();
    void clearSong();
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
    QHash<int, int> m_instrumentSoundFontIds;
    int m_countInNextValue;
    bool m_countInOnly;
    bool m_countInVisible;

    QScopedPointer<QList<fluid_event_t *>> m_song;
};

#endif
