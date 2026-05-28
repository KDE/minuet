// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

Repeater {
    id: repeater

    property bool spaced: true
    property int clefType: 0
    property int scoreSpacing: 0

    Note {
        required property int index
        required property var modelData

        midiKey: modelData
        spaced: index === 0 ? true : repeater.spaced
        clefType: repeater.clefType
        scoreSpacing: repeater.scoreSpacing
    }
}
