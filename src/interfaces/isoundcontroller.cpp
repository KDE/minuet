// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "isoundcontroller.h"

using namespace Qt::StringLiterals;

namespace Minuet
{
ISoundController::ISoundController(QObject *parent)
    : IPlugin(parent)
{
    m_pitch = 0;
    m_volume = 100;
    m_tempo = 60;
    m_rhythmCountInBeats = RhythmExerciseCountInBeats;
    m_rhythmCountInSubdivisions = 1;
    m_instrument = 0;
    m_rhythmInstrument = 37;
    setPlaybackLabel(u"00:00.00"_s);
    setState(State::StoppedState);
}

ISoundController::State ISoundController::state() const
{
    return m_state;
}

QString ISoundController::playbackLabel() const
{
    return m_playbackLabel;
}

int ISoundController::instrument() const
{
    return m_instrument;
}

int ISoundController::rhythmInstrument() const
{
    return m_rhythmInstrument;
}

int ISoundController::rhythmCountInBeats() const
{
    return m_rhythmCountInBeats;
}

int ISoundController::rhythmCountInSubdivisions() const
{
    return m_rhythmCountInSubdivisions;
}

QVariantList ISoundController::instrumentGroups() const
{
    return m_instrumentGroups;
}

QVariantList ISoundController::instruments() const
{
    return m_instruments;
}

QVariantList ISoundController::rhythmInstruments() const
{
    return m_rhythmInstruments;
}

void ISoundController::setPlaybackLabel(const QString &playbackLabel)
{
    if (m_playbackLabel != playbackLabel) {
        m_playbackLabel = playbackLabel;
        emit playbackLabelChanged(m_playbackLabel);
    }
}

void ISoundController::setState(State state)
{
    if (m_state != state) {
        m_state = state;
        emit stateChanged(m_state);
    }
}

bool ISoundController::setInstrumentValue(int instrument)
{
    if (m_instrument == instrument) {
        return false;
    }

    m_instrument = instrument;
    emit instrumentChanged(m_instrument);
    return true;
}

bool ISoundController::setRhythmInstrumentValue(int rhythmInstrument)
{
    if (m_rhythmInstrument == rhythmInstrument) {
        return false;
    }

    m_rhythmInstrument = rhythmInstrument;
    emit rhythmInstrumentChanged(m_rhythmInstrument);
    return true;
}

void ISoundController::setInstrumentGroups(const QVariantList &instrumentGroups)
{
    if (m_instrumentGroups != instrumentGroups) {
        m_instrumentGroups = instrumentGroups;
        emit instrumentGroupsChanged();
    }
}

void ISoundController::setInstruments(const QVariantList &instruments)
{
    if (m_instruments != instruments) {
        m_instruments = instruments;
        emit instrumentsChanged();
    }
}

void ISoundController::setRhythmInstruments(const QVariantList &rhythmInstruments)
{
    if (m_rhythmInstruments != rhythmInstruments) {
        m_rhythmInstruments = rhythmInstruments;
        emit rhythmInstrumentsChanged();
    }
}

}
