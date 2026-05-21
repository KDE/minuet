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

#ifndef MINUET_SETTINGSCONTROLLER_H
#define MINUET_SETTINGSCONTROLLER_H

#include <interfaces/isettingscontroller.h>

#include <QString>

namespace Minuet
{
class SettingsController : public ISettingsController
{
    Q_OBJECT

public:
    ~SettingsController() override = default;

    int rhythmPatternCount() const override;
    int testExerciseCount() const override;
    int volume() const override;
    int pitch() const override;
    int tempo() const override;
    int instrumentGroup() const override;
    int instrument() const override;
    int rhythmInstrument() const override;

public Q_SLOTS:
    void setRhythmPatternCount(int rhythmPatternCount) override;
    void setTestExerciseCount(int testExerciseCount) override;
    void setVolume(int volume) override;
    void setPitch(int pitch) override;
    void setTempo(int tempo) override;
    void setInstrumentGroup(int instrumentGroup) override;
    void setInstrument(int instrument) override;
    void setRhythmInstrument(int rhythmInstrument) override;

private:
    friend class Core;

    explicit SettingsController(QObject *parent = nullptr);

    void load();
    void write(const QString &key, int value);

    int m_rhythmPatternCount = 4;
    int m_testExerciseCount = 10;
    int m_volume = 100;
    int m_pitch = 0;
    int m_tempo = 60;
    int m_instrumentGroup = -1;
    int m_instrument = 0;
    int m_rhythmInstrument = 37;
};
}

#endif
