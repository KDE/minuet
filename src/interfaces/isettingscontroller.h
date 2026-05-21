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

#ifndef MINUET_ISETTINGSCONTROLLER_H
#define MINUET_ISETTINGSCONTROLLER_H

#include <interfaces/minuetinterfacesexport.h>

#include <QObject>
#include <qqmlregistration.h>

namespace Minuet
{
class MINUETINTERFACES_EXPORT ISettingsController : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ISettingsController)
    QML_UNCREATABLE("ISettingsController is provided by Core")

    Q_PROPERTY(int rhythmPatternCount READ rhythmPatternCount WRITE setRhythmPatternCount NOTIFY rhythmPatternCountChanged)
    Q_PROPERTY(int testExerciseCount READ testExerciseCount WRITE setTestExerciseCount NOTIFY testExerciseCountChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(int pitch READ pitch WRITE setPitch NOTIFY pitchChanged)
    Q_PROPERTY(int tempo READ tempo WRITE setTempo NOTIFY tempoChanged)
    Q_PROPERTY(int instrumentGroup READ instrumentGroup WRITE setInstrumentGroup NOTIFY instrumentGroupChanged)
    Q_PROPERTY(int instrument READ instrument WRITE setInstrument NOTIFY instrumentChanged)
    Q_PROPERTY(int rhythmInstrument READ rhythmInstrument WRITE setRhythmInstrument NOTIFY rhythmInstrumentChanged)

public:
    ~ISettingsController() override = default;

    virtual int rhythmPatternCount() const = 0;
    virtual int testExerciseCount() const = 0;
    virtual int volume() const = 0;
    virtual int pitch() const = 0;
    virtual int tempo() const = 0;
    virtual int instrumentGroup() const = 0;
    virtual int instrument() const = 0;
    virtual int rhythmInstrument() const = 0;

public Q_SLOTS:
    virtual void setRhythmPatternCount(int rhythmPatternCount) = 0;
    virtual void setTestExerciseCount(int testExerciseCount) = 0;
    virtual void setVolume(int volume) = 0;
    virtual void setPitch(int pitch) = 0;
    virtual void setTempo(int tempo) = 0;
    virtual void setInstrumentGroup(int instrumentGroup) = 0;
    virtual void setInstrument(int instrument) = 0;
    virtual void setRhythmInstrument(int rhythmInstrument) = 0;

Q_SIGNALS:
    void rhythmPatternCountChanged(int rhythmPatternCount);
    void testExerciseCountChanged(int testExerciseCount);
    void volumeChanged(int volume);
    void pitchChanged(int pitch);
    void tempoChanged(int tempo);
    void instrumentGroupChanged(int instrumentGroup);
    void instrumentChanged(int instrument);
    void rhythmInstrumentChanged(int rhythmInstrument);

protected:
    explicit ISettingsController(QObject *parent = nullptr);
};

}

#endif
