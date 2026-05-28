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

#include "pianokeyboardcontroller.h"

#include <algorithm>

namespace Minuet
{
PianoKeyboardController::PianoKeyboardController(QObject *parent)
    : QObject(parent)
{
}

bool PianoKeyboardController::isBlackKey(int pitch) const
{
    const int note = ((pitch % 12) + 12) % 12;
    return note == 1 || note == 3 || note == 6 || note == 8 || note == 10;
}

double PianoKeyboardController::scrollTargetX(int pitch, double contentWidth, double viewportWidth) const
{
    const double targetX = contentWidth / 88.0 * (pitch - 21) - viewportWidth / 2.0;
    return std::clamp(targetX, 0.0, std::max(0.0, contentWidth - viewportWidth));
}

int PianoKeyboardController::keyboardChildIndex(int pitch) const
{
    if (pitch < 24) {
        return pitch - 21;
    }
    if (pitch == 108) {
        return 10;
    }

    const int note = (pitch - 24) % 12;
    const int octave = (pitch - 24 - note) / 12;
    return 3 + octave;
}

int PianoKeyboardController::octaveChildIndex(int pitch) const
{
    if (pitch < 24 || pitch == 108) {
        return -1;
    }
    return (pitch - 24) % 12;
}
}
