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

#ifndef MINUET_ISOUNDCONTROLLER_H
#define MINUET_ISOUNDCONTROLLER_H

#include "iplugin.h"

#include <interfaces/minuetinterfacesexport.h>

#include <QJsonArray>

namespace Minuet
{
class MINUETINTERFACES_EXPORT ISoundController : public IPlugin
{
    Q_OBJECT

    // Read-write properties with simple mutators
    Q_PROPERTY(QString playMode MEMBER m_playMode NOTIFY playModeChanged)

    // Read-write properties with custom mutators
    Q_PROPERTY(qint8 pitch MEMBER m_pitch WRITE setPitch NOTIFY pitchChanged)
    Q_PROPERTY(quint8 volume MEMBER m_volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(quint8 tempo MEMBER m_tempo WRITE setTempo NOTIFY tempoChanged)

    // Read-only properties
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString playbackLabel READ playbackLabel NOTIFY playbackLabelChanged)

public:
    virtual ~ISoundController() override = default;

    enum State { StoppedState = 0, PlayingState, PausedState };
    Q_ENUM(State)
    Minuet::ISoundController::State state() const;

    QString playbackLabel() const;

public Q_SLOTS:
    virtual void setPitch(qint8 pitch) = 0;
    virtual void setVolume(quint8 volume) = 0;
    virtual void setTempo(quint8 tempo) = 0;

    virtual void prepareFromExerciseOptions(QJsonArray selectedExerciseOptions) = 0;
    virtual void prepareFromMidiFile(const QString &fileName) = 0;

    virtual void play() = 0;
    virtual void pause() = 0;
    virtual void stop() = 0;
    virtual void reset() = 0;

Q_SIGNALS:
    void playModeChanged(QString newPlayMode);
    void pitchChanged(qint8 newPitch);
    void volumeChanged(quint8 newVolume);
    void tempoChanged(quint8 newTempo);
    void stateChanged(Minuet::ISoundController::State newState);
    void playbackLabelChanged(QString newPlaybackLabel);

protected:
    explicit ISoundController(QObject *parent = 0);

    void setPlaybackLabel(const QString &playbackLabel);
    void setState(State state);

    qint8 m_pitch;
    quint8 m_volume;
    quint8 m_tempo;
    QString m_playbackLabel;
    State m_state;
    QString m_playMode;
};

}

Q_DECLARE_INTERFACE(Minuet::ISoundController, "org.kde.minuet.ISoundController")

#endif
