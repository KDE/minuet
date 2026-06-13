// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

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
    Q_PROPERTY(
        bool melodicOnboardingPromptShown READ melodicOnboardingPromptShown WRITE setMelodicOnboardingPromptShown NOTIFY melodicOnboardingPromptShownChanged)
    Q_PROPERTY(bool rhythmicOnboardingPromptShown READ rhythmicOnboardingPromptShown WRITE setRhythmicOnboardingPromptShown NOTIFY
                   rhythmicOnboardingPromptShownChanged)

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
    bool melodicOnboardingPromptShown() const;
    bool rhythmicOnboardingPromptShown() const;

public Q_SLOTS:
    void setRhythmPatternCount(int rhythmPatternCount);
    void setTestExerciseCount(int testExerciseCount);
    void setVolume(int volume);
    void setPitch(int pitch);
    void setTempo(int tempo);
    void setInstrumentGroup(int instrumentGroup);
    void setInstrument(int instrument);
    void setRhythmInstrument(int rhythmInstrument);
    void setMelodicOnboardingPromptShown(bool shown);
    void setRhythmicOnboardingPromptShown(bool shown);

Q_SIGNALS:
    void rhythmPatternCountChanged(int rhythmPatternCount);
    void testExerciseCountChanged(int testExerciseCount);
    void volumeChanged(int volume);
    void pitchChanged(int pitch);
    void tempoChanged(int tempo);
    void instrumentGroupChanged(int instrumentGroup);
    void instrumentChanged(int instrument);
    void rhythmInstrumentChanged(int rhythmInstrument);
    void melodicOnboardingPromptShownChanged(bool shown);
    void rhythmicOnboardingPromptShownChanged(bool shown);

private:
    friend class Core;

    explicit SettingsController(QObject *parent = nullptr);

    void load();
    void write(const QString &key, int value);
    void write(const QString &key, bool value);

    int m_rhythmPatternCount = 4;
    int m_testExerciseCount = 10;
    int m_volume = 100;
    int m_pitch = 0;
    int m_tempo = 60;
    int m_instrumentGroup = -1;
    int m_instrument = 0;
    int m_rhythmInstrument = 37;
    bool m_melodicOnboardingPromptShown = false;
    bool m_rhythmicOnboardingPromptShown = false;
};
}

#endif
