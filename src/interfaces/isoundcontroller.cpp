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

#include "isoundcontroller.h"

namespace Minuet
{
ISoundController::ISoundController(QObject *parent) : IPlugin(parent)
{
    setPlaybackLabel(QStringLiteral("00:00.00"));
    setState(StoppedState);
}

ISoundController::State ISoundController::state() const
{
    return m_state;
}

QString ISoundController::playbackLabel() const
{
    return m_playbackLabel;
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

}

#include "moc_isoundcontroller.cpp"
