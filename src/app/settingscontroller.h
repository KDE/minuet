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

#include <QObject>
#include <QString>

namespace Minuet
{
class SettingsController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rhythmPatternCount READ rhythmPatternCount WRITE setRhythmPatternCount NOTIFY rhythmPatternCountChanged)
    Q_PROPERTY(int testExerciseCount READ testExerciseCount WRITE setTestExerciseCount NOTIFY testExerciseCountChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(int pitch READ pitch WRITE setPitch NOTIFY pitchChanged)
    Q_PROPERTY(int tempo READ tempo WRITE setTempo NOTIFY tempoChanged)
    Q_PROPERTY(int instrumentGroup READ instrumentGroup WRITE setInstrumentGroup NOTIFY instrumentGroupChanged)
    Q_PROPERTY(int instrument READ instrument WRITE setInstrument NOTIFY instrumentChanged)
    Q_PROPERTY(int rhythmInstrument READ rhythmInstrument WRITE setRhythmInstrument NOTIFY rhythmInstrumentChanged)

public:
    ~SettingsController() override = default;

    int rhythmPatternCount() const;
    int testExerciseCount() const;
    int volume() const;
    int pitch() const;
    int tempo() const;
    int instrumentGroup() const;
    int instrument() const;
    int rhythmInstrument() const;

public Q_SLOTS:
    void setRhythmPatternCount(int rhythmPatternCount);
    void setTestExerciseCount(int testExerciseCount);
    void setVolume(int volume);
    void setPitch(int pitch);
    void setTempo(int tempo);
    void setInstrumentGroup(int instrumentGroup);
    void setInstrument(int instrument);
    void setRhythmInstrument(int rhythmInstrument);

Q_SIGNALS:
    void rhythmPatternCountChanged(int rhythmPatternCount);
    void testExerciseCountChanged(int testExerciseCount);
    void volumeChanged(int volume);
    void pitchChanged(int pitch);
    void tempoChanged(int tempo);
    void instrumentGroupChanged(int instrumentGroup);
    void instrumentChanged(int instrument);
    void rhythmInstrumentChanged(int rhythmInstrument);

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
