// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_RHYTHMTOKEN_H
#define MINUET_RHYTHMTOKEN_H

#include <QStringView>

namespace Minuet
{
struct RhythmToken {
    bool valid = false;
    bool rest = false;
    bool dotted = false;
    int denominator = 0;

    double quarterNoteBeats() const
    {
        return valid ? 4.0 / denominator * (dotted ? 1.5 : 1.0) : 0.0;
    }
};

inline RhythmToken parseRhythmToken(QStringView text)
{
    RhythmToken token;
    if (text.startsWith(u'r')) {
        token.rest = true;
        text = text.sliced(1);
    }
    if (text.endsWith(u'.')) {
        token.dotted = true;
        text = text.first(text.size() - 1);
    }

    bool ok = false;
    token.denominator = text.toInt(&ok);
    token.valid = ok && token.denominator > 0;
    return token;
}
}

#endif
