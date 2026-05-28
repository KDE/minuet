/****************************************************************************
**
** Copyright (C) 2026 by Sandro S. Andrade <sandroandrade@kde.org>
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

#include "settingscontroller.h"

#include <QSettings>

#include <algorithm>

using namespace Qt::StringLiterals;

namespace Minuet
{
SettingsController::SettingsController(QObject *parent) : QObject(parent)
{
    load();
}

void SettingsController::load()
{
    QSettings settings;
    settings.beginGroup(u"Settings"_s);
    m_rhythmPatternCount = std::clamp(settings.value(u"RhythmPatternCount"_s, m_rhythmPatternCount).toInt(), 4, 16);
    m_testExerciseCount = std::clamp(settings.value(u"TestExerciseCount"_s, m_testExerciseCount).toInt(), 5, 20);
    m_volume = std::clamp(settings.value(u"Volume"_s, m_volume).toInt(), 0, 200);
    m_pitch = std::clamp(settings.value(u"Pitch"_s, m_pitch).toInt(), -12, 12);
    m_tempo = std::clamp(settings.value(u"Tempo"_s, m_tempo).toInt(), 1, 255);
    m_instrumentGroup = settings.value(u"InstrumentGroup"_s, m_instrumentGroup).toInt();
    m_instrument = std::clamp(settings.value(u"Instrument"_s, m_instrument).toInt(), 0, 127);
    m_rhythmInstrument = std::clamp(settings.value(u"RhythmInstrument"_s, m_rhythmInstrument).toInt(), 35, 81);
}

void SettingsController::write(const QString &key, int value)
{
    QSettings settings;
    settings.beginGroup(u"Settings"_s);
    settings.setValue(key, value);
}

int SettingsController::rhythmPatternCount() const
{
    return m_rhythmPatternCount;
}

int SettingsController::testExerciseCount() const
{
    return m_testExerciseCount;
}

int SettingsController::volume() const
{
    return m_volume;
}

int SettingsController::pitch() const
{
    return m_pitch;
}

int SettingsController::tempo() const
{
    return m_tempo;
}

int SettingsController::instrumentGroup() const
{
    return m_instrumentGroup;
}

int SettingsController::instrument() const
{
    return m_instrument;
}

int SettingsController::rhythmInstrument() const
{
    return m_rhythmInstrument;
}

void SettingsController::setRhythmPatternCount(int rhythmPatternCount)
{
    rhythmPatternCount = std::clamp(rhythmPatternCount, 4, 16);
    if (m_rhythmPatternCount == rhythmPatternCount) {
        return;
    }

    m_rhythmPatternCount = rhythmPatternCount;
    write(u"RhythmPatternCount"_s, m_rhythmPatternCount);
    emit rhythmPatternCountChanged(m_rhythmPatternCount);
}

void SettingsController::setTestExerciseCount(int testExerciseCount)
{
    testExerciseCount = std::clamp(testExerciseCount, 5, 20);
    if (m_testExerciseCount == testExerciseCount) {
        return;
    }

    m_testExerciseCount = testExerciseCount;
    write(u"TestExerciseCount"_s, m_testExerciseCount);
    emit testExerciseCountChanged(m_testExerciseCount);
}

void SettingsController::setVolume(int volume)
{
    volume = std::clamp(volume, 0, 200);
    if (m_volume == volume) {
        return;
    }

    m_volume = volume;
    write(u"Volume"_s, m_volume);
    emit volumeChanged(m_volume);
}

void SettingsController::setPitch(int pitch)
{
    pitch = std::clamp(pitch, -12, 12);
    if (m_pitch == pitch) {
        return;
    }

    m_pitch = pitch;
    write(u"Pitch"_s, m_pitch);
    emit pitchChanged(m_pitch);
}

void SettingsController::setTempo(int tempo)
{
    tempo = std::clamp(tempo, 1, 255);
    if (m_tempo == tempo) {
        return;
    }

    m_tempo = tempo;
    write(u"Tempo"_s, m_tempo);
    emit tempoChanged(m_tempo);
}

void SettingsController::setInstrumentGroup(int instrumentGroup)
{
    if (m_instrumentGroup == instrumentGroup) {
        return;
    }

    m_instrumentGroup = instrumentGroup;
    write(u"InstrumentGroup"_s, m_instrumentGroup);
    emit instrumentGroupChanged(m_instrumentGroup);
}

void SettingsController::setInstrument(int instrument)
{
    instrument = std::clamp(instrument, 0, 127);
    if (m_instrument == instrument) {
        return;
    }

    m_instrument = instrument;
    write(u"Instrument"_s, m_instrument);
    emit instrumentChanged(m_instrument);
}

void SettingsController::setRhythmInstrument(int rhythmInstrument)
{
    rhythmInstrument = std::clamp(rhythmInstrument, 35, 81);
    if (m_rhythmInstrument == rhythmInstrument) {
        return;
    }

    m_rhythmInstrument = rhythmInstrument;
    write(u"RhythmInstrument"_s, m_rhythmInstrument);
    emit rhythmInstrumentChanged(m_rhythmInstrument);
}
}

#include "moc_settingscontroller.cpp"
