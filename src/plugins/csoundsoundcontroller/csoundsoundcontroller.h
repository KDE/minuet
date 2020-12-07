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
#ifndef MINUET_CSOUNDSOUNDCONTROLLER_H
#define MINUET_CSOUNDSOUNDCONTROLLER_H

#include <interfaces/isoundcontroller.h>

class CsEngine;

class CsoundSoundController : public Minuet::ISoundController
{
    Q_OBJECT

    Q_INTERFACES(Minuet::IPlugin)
    Q_INTERFACES(Minuet::ISoundController)

public:
    explicit CsoundSoundController(QObject *parent = 0);
    virtual ~CsoundSoundController() override;

public Q_SLOTS:
    virtual void setPitch(qint8 pitch);
    virtual void setVolume(quint8 volume);
    virtual void setTempo(quint8 tempo);

    virtual void prepareFromExerciseOptions(QJsonArray selectedExerciseOptions) override;
    virtual void prepareFromMidiFile(const QString &fileName) override;

    virtual void play() override;
    virtual void pause() override;
    virtual void stop() override;
    virtual void reset() override;

private:
    void appendEvent(QList<unsigned int> midiNotes, QList<float> barStartInfo, QString playMode);
    void openExerciseFile();
    void openCsdFile();

private:
    CsEngine *m_csoundEngine;
    QStringList m_begLine;
    QStringList m_endLine;
    QList<qint16> m_size;
};

#endif
