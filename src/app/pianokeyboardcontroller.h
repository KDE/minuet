// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_PIANOKEYBOARDCONTROLLER_H
#define MINUET_PIANOKEYBOARDCONTROLLER_H

#include <QObject>
#include <qqmlregistration.h>

namespace Minuet
{
class PianoKeyboardController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("PianoKeyboardController is provided by Core")

public:
    Q_INVOKABLE bool isBlackKey(int pitch) const;
    Q_INVOKABLE int keyboardChildIndex(int pitch) const;
    Q_INVOKABLE int octaveChildIndex(int pitch) const;

private:
    friend class Core;

    explicit PianoKeyboardController(QObject *parent = nullptr);
};
}

#endif
