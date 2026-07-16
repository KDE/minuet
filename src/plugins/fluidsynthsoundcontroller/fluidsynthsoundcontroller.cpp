// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "fluidsynthsoundcontroller.h"

#include <utils/rhythmtoken.h>

#include <KLocalizedString>

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QHash>
#include <QJsonObject>
#include <QSet>
#include <QStandardPaths>
#include <QVariantMap>
#include <QtMath>

#include <utils/xdgdatadirs.h>

#include <algorithm>
#include <utility>

using namespace Qt::StringLiterals;

static constexpr int MelodicChannel = 1;
static constexpr int RhythmChannel = 9;
static constexpr short RhythmCountInKey = 76; // High Wood Block
static constexpr short RhythmCountInVelocity = 127;
static constexpr short RhythmSubTickVelocity = 64;
static constexpr short DefaultRhythmInstrumentKey = 37; // Side Stick
static constexpr short FirstRhythmInstrumentKey = 35;
static constexpr short LastRhythmInstrumentKey = 81;

static QString locateSoundFont()
{
#ifdef Q_OS_ANDROID
    return QStandardPaths::locate(QStandardPaths::AppDataLocation, u"soundfonts/GeneralUser-v1.47.sf2"_s);
#elif defined(Q_OS_WIN)
    return QStandardPaths::locate(QStandardPaths::AppDataLocation, u"minuet/soundfonts/GeneralUser-v1.47.sf2"_s);
#else
#ifdef Q_OS_MACOS
    const QString bundleSoundFont = QDir(QCoreApplication::applicationDirPath()).absoluteFilePath(u"../Resources/minuet/soundfonts/GeneralUser-v1.47.sf2"_s);
    if (QFile::exists(bundleSoundFont)) {
        return QDir::cleanPath(bundleSoundFont);
    }
#endif

    QString soundFont = QStandardPaths::locate(QStandardPaths::AppDataLocation, u"soundfonts/GeneralUser-v1.47.sf2"_s);
#ifdef Q_OS_MACOS
    if (soundFont.isEmpty()) {
        const QStringList xdgDataDirs = Utils::xdgDataDirs();
        for (const auto &dirPath : xdgDataDirs) {
            const QFile testFile(QDir(dirPath).absoluteFilePath(u"minuet/soundfonts/GeneralUser-v1.47.sf2"_s));
            if (testFile.exists()) {
                soundFont = testFile.fileName();
                break;
            }
        }
    }
#endif
    return soundFont;
#endif
}

FluidSynthSoundController::FluidSynthSoundController(QObject *parent)
    : Minuet::ISoundController(parent)
    , m_settings(nullptr)
    , m_audioDriver(nullptr)
    , m_sequencer(nullptr)
    , m_synth(nullptr)
    , m_unregisteringEvent(nullptr)
    , m_synthSeqID(0)
    , m_callbackSeqID(0)
    , m_activeCountInBeats(0)
    , m_countInNextValue(0)
    , m_countInOnly(false)
    , m_countInAudible(true)
    , m_countInVisible(false)
    , m_song(nullptr)
{
    m_tempo = 60;

    m_settings = new_fluid_settings();
    fluid_settings_setint(m_settings, "synth.reverb.active", 0);
    fluid_settings_setint(m_settings, "synth.chorus.active", 0);

    m_synth = new_fluid_synth(m_settings);

    fluid_synth_cc(m_synth, MelodicChannel, 100, 0);

    const QString sf_path = locateSoundFont();
    int fluid_res = fluid_synth_sfload(m_synth, sf_path.toUtf8().constData(), 1);
    if (fluid_res == FLUID_FAILED) {
        qCritical() << "Error when loading soundfont in:" << sf_path;
    } else {
        qInfo() << "Loaded soundfont:" << sf_path;
    }
    populateInstruments();
    populateRhythmInstruments();
    applyInstrument();

    m_unregisteringEvent = new_fluid_event();
    fluid_event_set_source(m_unregisteringEvent, -1);

    resetEngine();
}

FluidSynthSoundController::~FluidSynthSoundController()
{
    deleteEngine();
    clearSong();
    if (m_synth) {
        delete_fluid_synth(m_synth);
    }
    if (m_settings) {
        delete_fluid_settings(m_settings);
    }
    if (m_unregisteringEvent) {
        delete_fluid_event(m_unregisteringEvent);
    }
}

void FluidSynthSoundController::setPitch(qint8 pitch)
{
    if (m_pitch == pitch) {
        return;
    }
    m_pitch = pitch;
    fluid_synth_cc(m_synth, MelodicChannel, 101, 0);
    fluid_synth_cc(m_synth, MelodicChannel, 6, 12);
    float accurate_pitch = (m_pitch + 12) * (2.0 / 3) * 1024;
    fluid_synth_pitch_bend(m_synth, MelodicChannel, std::min(qRound(accurate_pitch), 16 * 1024 - 1));
    emit pitchChanged(m_pitch);
}

void FluidSynthSoundController::setVolume(quint8 volume)
{
    if (m_volume == volume) {
        return;
    }
    m_volume = volume;
    const int midiVolume = m_volume * 127 / 200;
    fluid_synth_cc(m_synth, MelodicChannel, 7, midiVolume);
    fluid_synth_cc(m_synth, RhythmChannel, 7, midiVolume);
    emit volumeChanged(m_volume);
}

void FluidSynthSoundController::setTempo(quint8 tempo)
{
    if (tempo == 0) {
        qWarning() << "Ignoring invalid zero tempo.";
        return;
    }
    if (m_tempo == tempo) {
        return;
    }
    m_tempo = tempo;
    emit tempoChanged(m_tempo);
}

void FluidSynthSoundController::setRhythmCountInBeats(int beats)
{
    beats = std::clamp(beats, 1, 32);
    if (m_rhythmCountInBeats == beats) {
        return;
    }
    m_rhythmCountInBeats = beats;
    emit rhythmCountInBeatsChanged(m_rhythmCountInBeats);
}

void FluidSynthSoundController::setRhythmCountInSubdivisions(int subdivisions)
{
    subdivisions = std::clamp(subdivisions, 1, 16);
    if (m_rhythmCountInSubdivisions == subdivisions) {
        return;
    }
    m_rhythmCountInSubdivisions = subdivisions;
    emit rhythmCountInSubdivisionsChanged(m_rhythmCountInSubdivisions);
}

void FluidSynthSoundController::setInstrument(int instrument)
{
    if (instrument < 0 || instrument > 127) {
        return;
    }

    setInstrumentValue(instrument);
    applyInstrument();
}

void FluidSynthSoundController::setRhythmInstrument(int rhythmInstrument)
{
    if (rhythmInstrument < FirstRhythmInstrumentKey || rhythmInstrument > LastRhythmInstrumentKey) {
        return;
    }

    setRhythmInstrumentValue(rhythmInstrument);
}

void FluidSynthSoundController::prepareFromExerciseOptions(QJsonArray selectedExerciseOptions)
{
    hideCountIn();
    clearSong();
    m_countInOnly = false;
    if (m_tempo == 0) {
        qWarning() << "Cannot prepare exercise options with zero tempo.";
        return;
    }

    auto *song = new QList<fluid_event_t *>;
    m_song.reset(song);

    if (m_playMode == u"rhythm"_s) {
        setRhythmCountInBeats(RhythmExerciseCountInBeats);
        m_activeCountInBeats = RhythmExerciseCountInBeats;
        appendCountInEvents(m_activeCountInBeats);
    }

    for (auto &&selectedExerciseOption : selectedExerciseOptions) {
        QString sequence = selectedExerciseOption.toObject()[u"sequence"_s].toString();

        unsigned int chosenRootNote = selectedExerciseOption.toObject()[u"rootNote"_s].toString().toInt();
        if (m_playMode != u"rhythm"_s) {
            const unsigned int noteDuration = ((m_playMode == u"scale"_s) ? 1000 : 4000) * (60.0 / m_tempo);
            appendEvent(MelodicChannel, chosenRootNote, 127, noteDuration);
            const QStringList additionalNotes = sequence.split(' ', Qt::SkipEmptyParts);
            for (const QString &additionalNote : additionalNotes) {
                appendEvent(MelodicChannel, chosenRootNote + additionalNote.toInt(), 127, noteDuration);
            }
        } else {
            // appendEvent(9, 80, 127, 1000*(60.0/m_tempo));
            const QStringList additionalNotes = sequence.split(QLatin1Char(' '), Qt::SkipEmptyParts);
            for (const QString &additionalNote : additionalNotes) {
                const Minuet::RhythmToken token = Minuet::parseRhythmToken(additionalNote);
                if (!token.valid) {
                    qWarning() << "Ignoring exercise option with invalid rhythm value:" << additionalNote;
                    clearSong();
                    return;
                }
                const unsigned int duration = token.quarterNoteBeats() * 1000 * (60.0 / m_tempo);
                appendEvent(RhythmChannel, m_rhythmInstrument, token.rest ? 0 : 127, duration);
            }
        }
    }
    // if (m_playMode == "rhythm")
    //    appendEvent(9, 80, 127, 1000*(60.0/m_tempo));

    fluid_event_t *event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_all_notes_off(event, MelodicChannel);
    m_song->append(event);
    event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_all_notes_off(event, RhythmChannel);
    m_song->append(event);
}

void FluidSynthSoundController::prepareFromMidiFile(const QString &fileName)
{
    Q_UNUSED(fileName)
}

void FluidSynthSoundController::playCountIn(int beats)
{
    playCountIn(beats, true);
}

void FluidSynthSoundController::playSilentCountIn(int beats)
{
    playCountIn(beats, false);
}

void FluidSynthSoundController::playCountIn(int beats, bool audible)
{
    beats = std::clamp(beats, 1, 32);
    if (m_tempo == 0) {
        qWarning() << "Cannot play count-in with zero tempo.";
        return;
    }

    stop();
    clearSong();
    m_countInOnly = true;
    m_countInAudible = audible;
    m_activeCountInBeats = beats;
    auto *song = new QList<fluid_event_t *>;
    m_song.reset(song);
    appendCountInEvents(beats);

    fluid_event_t *event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_all_notes_off(event, RhythmChannel);
    m_song->append(event);
    play();
}

void FluidSynthSoundController::play()
{
    if (!m_song.data()) {
        return;
    }

    if (m_state != State::PlayingState) {
        const bool usesRhythmicTiming = m_playMode == u"rhythm"_s || m_countInOnly;
        m_countInNextValue = usesRhythmicTiming ? 1 : 0;
        m_countInVisible = false;
        unsigned int now = fluid_sequencer_get_tick(m_sequencer);
        unsigned int chordDuration = 0;
        if (m_playMode == u"chord"_s) {
            for (fluid_event_t *event : std::as_const(*m_song.data())) {
                if (fluid_event_get_type(event) == FLUID_SEQ_NOTE) {
                    chordDuration = std::max(chordDuration, fluid_event_get_duration(event));
                }
            }
        }
        for (fluid_event_t *event : std::as_const(*m_song.data())) {
            const bool silentCountInNote = m_countInOnly && !m_countInAudible && fluid_event_get_type(event) == FLUID_SEQ_NOTE
                && fluid_event_get_channel(event) == RhythmChannel && fluid_event_get_key(event) == RhythmCountInKey;
            if (!silentCountInNote && (fluid_event_get_type(event) != FLUID_SEQ_ALLNOTESOFF || m_playMode != u"chord"_s)) {
                fluid_event_set_dest(event, m_synthSeqID);
                fluid_sequencer_send_at(m_sequencer, event, now, 1);
            }
            fluid_event_set_dest(event, m_callbackSeqID);
            fluid_sequencer_send_at(m_sequencer,
                                    event,
                                    now + ((m_playMode == u"chord"_s && fluid_event_get_type(event) == FLUID_SEQ_ALLNOTESOFF) ? chordDuration : 0),
                                    1);
            now += usesRhythmicTiming ? fluid_event_get_duration(event) : (m_playMode == u"scale"_s) ? 1000 * (60.0 / m_tempo) : 0;
        }
        setState(State::PlayingState);
    }
}

void FluidSynthSoundController::pause()
{
}

void FluidSynthSoundController::stop()
{
    hideCountIn();
    if (m_sequencer) {
        fluid_sequencer_remove_events(m_sequencer, -1, m_synthSeqID, -1);
        fluid_sequencer_remove_events(m_sequencer, -1, m_callbackSeqID, -1);
    }

    if (m_state != State::StoppedState) {
        fluid_event_t *event = new_fluid_event();
        fluid_event_set_source(event, -1);
        fluid_event_all_notes_off(event, MelodicChannel);
        fluid_event_set_dest(event, m_synthSeqID);
        if (m_sequencer) {
            fluid_sequencer_send_now(m_sequencer, event);
        }
        delete_fluid_event(event);
        event = new_fluid_event();
        fluid_event_set_source(event, -1);
        fluid_event_all_notes_off(event, RhythmChannel);
        fluid_event_set_dest(event, m_synthSeqID);
        if (m_sequencer) {
            fluid_sequencer_send_now(m_sequencer, event);
        }
        delete_fluid_event(event);
    }
    m_initialTime = 0;
    setPlaybackLabel(u"00:00.00"_s);
    setState(State::StoppedState);
}

void FluidSynthSoundController::reset()
{
    hideCountIn();
    stop();
    clearSong();
}

void FluidSynthSoundController::appendEvent(int channel, short key, short velocity, unsigned int duration)
{
    fluid_event_t *event = new_fluid_event();
    fluid_event_set_source(event, -1);
    fluid_event_note(event, channel, key, velocity, duration);
    m_song->append(event);
}

void FluidSynthSoundController::appendCountInEvents(int beats)
{
    const unsigned int subdivisionDuration = 1000 * (60.0 / m_tempo) / m_rhythmCountInSubdivisions;
    for (int beat = 0; beat < beats; ++beat) {
        appendEvent(RhythmChannel, RhythmCountInKey, RhythmCountInVelocity, subdivisionDuration);
        for (int subdivision = 1; subdivision < m_rhythmCountInSubdivisions; ++subdivision) {
            appendEvent(RhythmChannel, RhythmCountInKey, RhythmSubTickVelocity, subdivisionDuration);
        }
    }
}

void FluidSynthSoundController::hideCountIn()
{
    m_activeCountInBeats = 0;
    m_countInNextValue = 0;
    if (m_countInVisible) {
        m_countInVisible = false;
        emit countInChanged(0);
    }
}

void FluidSynthSoundController::clearSong()
{
    if (!m_song.data()) {
        return;
    }

    for (fluid_event_t *event : std::as_const(*m_song.data())) {
        delete_fluid_event(event);
    }
    m_song.reset(nullptr);
}

void FluidSynthSoundController::populateInstruments()
{
    QList<QVariantMap> instrumentMaps;
    QSet<int> seenPrograms;
    m_instrumentSoundFontIds.clear();

    const int soundFontCount = fluid_synth_sfcount(m_synth);
    for (int soundFontIndex = 0; soundFontIndex < soundFontCount; ++soundFontIndex) {
        fluid_sfont_t *soundFont = fluid_synth_get_sfont(m_synth, soundFontIndex);
        if (!soundFont) {
            continue;
        }

        fluid_sfont_iteration_start(soundFont);
        fluid_preset_t *preset = nullptr;
        while ((preset = fluid_sfont_iteration_next(soundFont)) != nullptr) {
            const int bank = fluid_preset_get_banknum(preset);
            const int program = fluid_preset_get_num(preset);
            if (bank != 0 || program < 0 || program > 127 || seenPrograms.contains(program)) {
                continue;
            }

            seenPrograms.insert(program);
            m_instrumentSoundFontIds.insert(program, fluid_sfont_get_id(soundFont));

            const QString name = QString::fromUtf8(fluid_preset_get_name(preset));
            const int group = program / 8;
            QVariantMap instrument;
            instrument.insert(u"group"_s, group);
            instrument.insert(u"bank"_s, bank);
            instrument.insert(u"program"_s, program);
            instrument.insert(u"number"_s, program + 1);
            instrument.insert(u"name"_s, name);
            instrument.insert(u"displayName"_s, u"%1 %2"_s.arg(program + 1, 3, 10, QLatin1Char('0')).arg(name));
            instrumentMaps.push_back(instrument);
        }
    }

    std::sort(instrumentMaps.begin(), instrumentMaps.end(), [](const QVariantMap &lhs, const QVariantMap &rhs) {
        return lhs.value(u"program"_s).toInt() < rhs.value(u"program"_s).toInt();
    });

    QVariantList instruments;
    QSet<int> availableGroups;
    for (const QVariantMap &instrument : std::as_const(instrumentMaps)) {
        instruments.push_back(instrument);
        availableGroups.insert(instrument.value(u"group"_s).toInt());
    }

    QVariantList groups;
    for (int group = 0; group < 16; ++group) {
        if (!availableGroups.contains(group)) {
            continue;
        }

        QVariantMap groupData;
        groupData.insert(u"id"_s, group);
        groupData.insert(u"name"_s, instrumentGroupName(group));
        groups.push_back(groupData);
    }

    if (instruments.isEmpty()) {
        qWarning() << "No General MIDI bank 0 instruments found in loaded SoundFonts.";
    } else if (instruments.size() < 128) {
        qWarning() << "Only" << instruments.size() << "General MIDI bank 0 instruments found in loaded SoundFonts.";
    }

    setInstrumentGroups(groups);
    setInstruments(instruments);
}

void FluidSynthSoundController::populateRhythmInstruments()
{
    QVariantList rhythmInstruments;
    for (int key = FirstRhythmInstrumentKey; key <= LastRhythmInstrumentKey; ++key) {
        QVariantMap instrument;
        instrument.insert(u"key"_s, key);
        instrument.insert(u"number"_s, key);
        instrument.insert(u"name"_s, rhythmInstrumentName(key));
        instrument.insert(u"displayName"_s, u"%1 %2"_s.arg(key, 3, 10, QLatin1Char('0')).arg(rhythmInstrumentName(key)));
        rhythmInstruments.push_back(instrument);
    }
    setRhythmInstruments(rhythmInstruments);
    if (m_rhythmInstrument < FirstRhythmInstrumentKey || m_rhythmInstrument > LastRhythmInstrumentKey) {
        setRhythmInstrumentValue(DefaultRhythmInstrumentKey);
    }
}

void FluidSynthSoundController::applyInstrument()
{
    if (!m_synth) {
        return;
    }

    const int soundFontId = m_instrumentSoundFontIds.value(m_instrument, -1);
    if (soundFontId >= 0) {
        fluid_synth_program_select(m_synth, MelodicChannel, soundFontId, 0, m_instrument);
    } else {
        fluid_synth_program_change(m_synth, MelodicChannel, m_instrument);
    }
}

QString FluidSynthSoundController::rhythmInstrumentName(int key)
{
    switch (key) {
    case 35:
        return i18nc("General MIDI percussion instrument", "Acoustic Bass Drum");
    case 36:
        return i18nc("General MIDI percussion instrument", "Bass Drum 1");
    case 37:
        return i18nc("General MIDI percussion instrument", "Side Stick");
    case 38:
        return i18nc("General MIDI percussion instrument", "Acoustic Snare");
    case 39:
        return i18nc("General MIDI percussion instrument", "Hand Clap");
    case 40:
        return i18nc("General MIDI percussion instrument", "Electric Snare");
    case 41:
        return i18nc("General MIDI percussion instrument", "Low Floor Tom");
    case 42:
        return i18nc("General MIDI percussion instrument", "Closed Hi-hat");
    case 43:
        return i18nc("General MIDI percussion instrument", "High Floor Tom");
    case 44:
        return i18nc("General MIDI percussion instrument", "Pedal Hi-hat");
    case 45:
        return i18nc("General MIDI percussion instrument", "Low Tom");
    case 46:
        return i18nc("General MIDI percussion instrument", "Open Hi-hat");
    case 47:
        return i18nc("General MIDI percussion instrument", "Low-Mid Tom");
    case 48:
        return i18nc("General MIDI percussion instrument", "Hi-Mid Tom");
    case 49:
        return i18nc("General MIDI percussion instrument", "Crash Cymbal 1");
    case 50:
        return i18nc("General MIDI percussion instrument", "High Tom");
    case 51:
        return i18nc("General MIDI percussion instrument", "Ride Cymbal 1");
    case 52:
        return i18nc("General MIDI percussion instrument", "Chinese Cymbal");
    case 53:
        return i18nc("General MIDI percussion instrument", "Ride Bell");
    case 54:
        return i18nc("General MIDI percussion instrument", "Tambourine");
    case 55:
        return i18nc("General MIDI percussion instrument", "Splash Cymbal");
    case 56:
        return i18nc("General MIDI percussion instrument", "Cowbell");
    case 57:
        return i18nc("General MIDI percussion instrument", "Crash Cymbal 2");
    case 58:
        return i18nc("General MIDI percussion instrument", "Vibraslap");
    case 59:
        return i18nc("General MIDI percussion instrument", "Ride Cymbal 2");
    case 60:
        return i18nc("General MIDI percussion instrument", "Hi Bongo");
    case 61:
        return i18nc("General MIDI percussion instrument", "Low Bongo");
    case 62:
        return i18nc("General MIDI percussion instrument", "Mute Hi Conga");
    case 63:
        return i18nc("General MIDI percussion instrument", "Open Hi Conga");
    case 64:
        return i18nc("General MIDI percussion instrument", "Low Conga");
    case 65:
        return i18nc("General MIDI percussion instrument", "High Timbale");
    case 66:
        return i18nc("General MIDI percussion instrument", "Low Timbale");
    case 67:
        return i18nc("General MIDI percussion instrument", "High Agogo");
    case 68:
        return i18nc("General MIDI percussion instrument", "Low Agogo");
    case 69:
        return i18nc("General MIDI percussion instrument", "Cabasa");
    case 70:
        return i18nc("General MIDI percussion instrument", "Maracas");
    case 71:
        return i18nc("General MIDI percussion instrument", "Short Whistle");
    case 72:
        return i18nc("General MIDI percussion instrument", "Long Whistle");
    case 73:
        return i18nc("General MIDI percussion instrument", "Short Guiro");
    case 74:
        return i18nc("General MIDI percussion instrument", "Long Guiro");
    case 75:
        return i18nc("General MIDI percussion instrument", "Claves");
    case 76:
        return i18nc("General MIDI percussion instrument", "Hi Wood Block");
    case 77:
        return i18nc("General MIDI percussion instrument", "Low Wood Block");
    case 78:
        return i18nc("General MIDI percussion instrument", "Mute Cuica");
    case 79:
        return i18nc("General MIDI percussion instrument", "Open Cuica");
    case 80:
        return i18nc("General MIDI percussion instrument", "Mute Triangle");
    case 81:
        return i18nc("General MIDI percussion instrument", "Open Triangle");
    default:
        return i18nc("General MIDI percussion instrument", "Percussion");
    }
}

QString FluidSynthSoundController::instrumentGroupName(int group)
{
    switch (group) {
    case 0:
        return i18nc("General MIDI instrument group", "Piano");
    case 1:
        return i18nc("General MIDI instrument group", "Chromatic Percussion");
    case 2:
        return i18nc("General MIDI instrument group", "Organ");
    case 3:
        return i18nc("General MIDI instrument group", "Guitar");
    case 4:
        return i18nc("General MIDI instrument group", "Bass");
    case 5:
        return i18nc("General MIDI instrument group", "Strings");
    case 6:
        return i18nc("General MIDI instrument group", "Ensemble");
    case 7:
        return i18nc("General MIDI instrument group", "Brass");
    case 8:
        return i18nc("General MIDI instrument group", "Reed");
    case 9:
        return i18nc("General MIDI instrument group", "Pipe");
    case 10:
        return i18nc("General MIDI instrument group", "Synth Lead");
    case 11:
        return i18nc("General MIDI instrument group", "Synth Pad");
    case 12:
        return i18nc("General MIDI instrument group", "Synth Effects");
    case 13:
        return i18nc("General MIDI instrument group", "Ethnic");
    case 14:
        return i18nc("General MIDI instrument group", "Percussive");
    case 15:
        return i18nc("General MIDI instrument group", "Sound Effects");
    default:
        return i18nc("General MIDI instrument group", "Other");
    }
}

void FluidSynthSoundController::sequencerCallback(unsigned int time, fluid_event_t *event, fluid_sequencer_t *seq, void *data)
{
    Q_UNUSED(seq);

    auto *soundController = reinterpret_cast<FluidSynthSoundController *>(data);
    const int eventType = fluid_event_get_type(event);
    const int channel = eventType == FLUID_SEQ_NOTE ? fluid_event_get_channel(event) : -1;
    const short key = eventType == FLUID_SEQ_NOTE ? fluid_event_get_key(event) : 0;
    const int velocity = eventType == FLUID_SEQ_NOTE ? fluid_event_get_velocity(event) : 0;
    QMetaObject::invokeMethod(soundController, [soundController, time, eventType, channel, key, velocity] {
        soundController->handleSequencerEvent(time, eventType, channel, key, velocity);
    });
}

void FluidSynthSoundController::handleSequencerEvent(unsigned int time, int eventType, int channel, short key, int velocity)
{
    switch (eventType) {
    case FLUID_SEQ_NOTE: {
        if ((m_playMode == u"rhythm"_s || m_countInOnly) && channel == RhythmChannel) {
            if (key == RhythmCountInKey && velocity == RhythmCountInVelocity && m_countInNextValue <= m_activeCountInBeats) {
                m_countInVisible = true;
                Q_EMIT countInChanged(m_countInNextValue);
                ++m_countInNextValue;
            } else if (key == RhythmCountInKey && velocity == RhythmSubTickVelocity && m_countInVisible) {
                Q_EMIT countInSubTick();
            } else if (key == m_rhythmInstrument) {
                hideCountIn();
            }
        }

        if (m_initialTime == 0) {
            m_initialTime = time;
        }
        double adjustedTime = (time - m_initialTime) / 1000.0;
        int mins = adjustedTime / 60;
        int secs = ((int)adjustedTime) % 60;
        int cnts = 100 * (adjustedTime - qFloor(adjustedTime));

        static QChar fill('0');
        setPlaybackLabel(u"%1:%2.%3"_s.arg(mins, 2, 10, fill).arg(secs, 2, 10, fill).arg(cnts, 2, 10, fill));
        break;
    }
    case FLUID_SEQ_ALLNOTESOFF: {
        m_initialTime = 0;
        setPlaybackLabel(u"00:00.00"_s);
        setState(State::StoppedState);
        hideCountIn();
        break;
    }
    default:
        break;
    }
}

void FluidSynthSoundController::resetEngine()
{
    deleteEngine();
#if defined(Q_OS_ANDROID)
    for (const char *driver : {"oboe", "opensles"}) {
        if (fluid_settings_setstr(m_settings, "audio.driver", driver) != FLUID_OK) {
            qWarning() << "FluidSynth audio driver is not available:" << driver;
            continue;
        }

        m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
        if (m_audioDriver) {
            qInfo() << "Using FluidSynth audio driver:" << driver;
            break;
        }

        qWarning() << "Could not start FluidSynth audio driver:" << driver;
    }
#elif defined(Q_OS_LINUX)
    fluid_settings_setstr(m_settings, "audio.driver", "pulseaudio");
    m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
    if (!m_audioDriver) {
        fluid_settings_setstr(m_settings, "audio.driver", "alsa");
        m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
    }
#elif defined(Q_OS_MACOS) || defined(Q_OS_IOS)
    fluid_settings_setstr(m_settings, "audio.driver", "coreaudio");
    m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
#elif defined(Q_OS_WIN)
    fluid_settings_setstr(m_settings, "audio.driver", "dsound");
    m_audioDriver = new_fluid_audio_driver(m_settings, m_synth);
#endif
    if (!m_audioDriver) {
        qCritical() << "Couldn't start audio driver!";
    } else {
        qInfo() << "Started FluidSynth audio driver";
    }

    m_sequencer = new_fluid_sequencer2(0);
    m_synthSeqID = fluid_sequencer_register_fluidsynth(m_sequencer, m_synth);
    m_callbackSeqID = fluid_sequencer_register_client(m_sequencer, "Minuet Fluidsynth Sound Controller", &FluidSynthSoundController::sequencerCallback, this);

    m_initialTime = 0;
    setPlaybackLabel(u"00:00.00"_s);
    setState(State::StoppedState);
}

void FluidSynthSoundController::deleteEngine()
{
    if (m_sequencer) {
#if FLUIDSYNTH_VERSION_MAJOR >= 2
        // explicit client unregistering required
        fluid_sequencer_unregister_client(m_sequencer, m_callbackSeqID);
        fluid_event_set_dest(m_unregisteringEvent, m_synthSeqID);
        fluid_event_unregistering(m_unregisteringEvent);
        fluid_sequencer_send_now(m_sequencer, m_unregisteringEvent);
#endif
        delete_fluid_sequencer(m_sequencer);
        m_sequencer = nullptr;
    }
    if (m_audioDriver) {
        delete_fluid_audio_driver(m_audioDriver);
        m_audioDriver = nullptr;
    }
}
