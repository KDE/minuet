// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "isoundcontroller.h"

#include <QJsonArray>
#include <QJsonDocument>

using namespace Qt::StringLiterals;

namespace Minuet
{
ISoundController::ISoundController(QObject *parent) : IPlugin(parent)
{
    m_pitch = 0;
    m_volume = 100;
    m_tempo = 60;
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

QString ISoundController::instrumentGroupsJson() const
{
    return m_instrumentGroupsJson;
}

QString ISoundController::instrumentsJson() const
{
    return m_instrumentsJson;
}

QString ISoundController::rhythmInstrumentsJson() const
{
    return m_rhythmInstrumentsJson;
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
        m_instrumentGroupsJson = QString::fromUtf8(
            QJsonDocument(QJsonArray::fromVariantList(m_instrumentGroups)).toJson(QJsonDocument::Compact));
        emit instrumentGroupsChanged();
    }
}

void ISoundController::setInstruments(const QVariantList &instruments)
{
    if (m_instruments != instruments) {
        m_instruments = instruments;
        m_instrumentsJson = QString::fromUtf8(
            QJsonDocument(QJsonArray::fromVariantList(m_instruments)).toJson(QJsonDocument::Compact));
        emit instrumentsChanged();
    }
}

void ISoundController::setRhythmInstruments(const QVariantList &rhythmInstruments)
{
    if (m_rhythmInstruments != rhythmInstruments) {
        m_rhythmInstruments = rhythmInstruments;
        m_rhythmInstrumentsJson = QString::fromUtf8(
            QJsonDocument(QJsonArray::fromVariantList(m_rhythmInstruments)).toJson(QJsonDocument::Compact));
        emit rhythmInstrumentsChanged();
    }
}

}

#include "moc_isoundcontroller.cpp"
