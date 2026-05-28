// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_ISOUNDCONTROLLER_H
#define MINUET_ISOUNDCONTROLLER_H

#include "iplugin.h"

#include <interfaces/minuetinterfacesexport.h>

#include <QJsonArray>
#include <QVariantList>
#include <qqmlregistration.h>

namespace Minuet
{
class MINUETINTERFACES_EXPORT ISoundController : public IPlugin
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("ISoundController is provided by Core")

    // Read-write properties with simple mutators
    Q_PROPERTY(QString playMode MEMBER m_playMode NOTIFY playModeChanged)

    // Read-write properties with custom mutators
    Q_PROPERTY(qint8 pitch MEMBER m_pitch WRITE setPitch NOTIFY pitchChanged)
    Q_PROPERTY(quint8 volume MEMBER m_volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(quint8 tempo MEMBER m_tempo WRITE setTempo NOTIFY tempoChanged)
    Q_PROPERTY(int instrument READ instrument WRITE setInstrument NOTIFY instrumentChanged)
    Q_PROPERTY(int rhythmInstrument READ rhythmInstrument WRITE setRhythmInstrument NOTIFY rhythmInstrumentChanged)

    // Read-only properties
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString playbackLabel READ playbackLabel NOTIFY playbackLabelChanged)
    Q_PROPERTY(QString instrumentGroupsJson READ instrumentGroupsJson NOTIFY instrumentGroupsChanged)
    Q_PROPERTY(QString instrumentsJson READ instrumentsJson NOTIFY instrumentsChanged)
    Q_PROPERTY(QString rhythmInstrumentsJson READ rhythmInstrumentsJson NOTIFY rhythmInstrumentsChanged)

public:
    ~ISoundController() override = default;

    enum class State { StoppedState, PlayingState, PausedState };
    Q_ENUM(State)
    Minuet::ISoundController::State state() const;

    QString playbackLabel() const;
    int instrument() const;
    int rhythmInstrument() const;
    QVariantList instrumentGroups() const;
    QVariantList instruments() const;
    QVariantList rhythmInstruments() const;
    QString instrumentGroupsJson() const;
    QString instrumentsJson() const;
    QString rhythmInstrumentsJson() const;

public Q_SLOTS:
    virtual void setPitch(qint8 pitch) = 0;
    virtual void setVolume(quint8 volume) = 0;
    virtual void setTempo(quint8 tempo) = 0;
    virtual void setInstrument(int instrument) = 0;
    virtual void setRhythmInstrument(int rhythmInstrument) = 0;

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
    void instrumentChanged(int newInstrument);
    void rhythmInstrumentChanged(int newRhythmInstrument);
    void stateChanged(Minuet::ISoundController::State newState);
    void playbackLabelChanged(QString newPlaybackLabel);
    void instrumentGroupsChanged();
    void instrumentsChanged();
    void rhythmInstrumentsChanged();
    void countInChanged(int count);

protected:
    explicit ISoundController(QObject *parent = nullptr);

    void setPlaybackLabel(const QString &playbackLabel);
    void setState(State state);
    bool setInstrumentValue(int instrument);
    bool setRhythmInstrumentValue(int rhythmInstrument);
    void setInstrumentGroups(const QVariantList &instrumentGroups);
    void setInstruments(const QVariantList &instruments);
    void setRhythmInstruments(const QVariantList &rhythmInstruments);

    qint8 m_pitch;
    quint8 m_volume;
    quint8 m_tempo;
    int m_instrument;
    int m_rhythmInstrument;
    QString m_playbackLabel;
    State m_state;
    QString m_playMode;
    QVariantList m_instrumentGroups;
    QVariantList m_instruments;
    QVariantList m_rhythmInstruments;
    QString m_instrumentGroupsJson;
    QString m_instrumentsJson;
    QString m_rhythmInstrumentsJson;
};

}

Q_DECLARE_INTERFACE(Minuet::ISoundController, "org.kde.minuet.ISoundController")

#endif
