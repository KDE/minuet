// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

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
