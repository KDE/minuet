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

#include "fluidsynthsoundbackend.h"

FluidSynthSoundBackend::FluidSynthSoundBackend(QObject *parent)
    : Minuet::ISoundBackend(parent)
{
}

FluidSynthSoundBackend::~FluidSynthSoundBackend()
{
}

void FluidSynthSoundBackend::setTempo (quint8 tempo)
{
    Q_UNUSED(tempo);
}

void FluidSynthSoundBackend::prepareFromExerciseOptions(QJsonArray selectedOptions)
{
    Q_UNUSED(selectedOptions)
}

void FluidSynthSoundBackend::prepareFromMidiFile(const QString &fileName)
{
    Q_UNUSED(fileName)
}

void FluidSynthSoundBackend::play()
{
}

void FluidSynthSoundBackend::pause()
{
}

void FluidSynthSoundBackend::stop()
{
}

#include "moc_fluidsynthsoundbackend.cpp"

