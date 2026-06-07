// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

Item {
    id: root

    property Item initialAnchor
    property int keyHeight
    property int keyWidth

    anchors.left: root.initialAnchor.right
    height: root.keyHeight - 10
    width: 7 * root.keyWidth

    WhiteKey {
        id: whiteKey1

        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    BlackKey {
        anchor: whiteKey1
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    WhiteKey {
        id: whiteKey2

        anchor: whiteKey1
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    BlackKey {
        anchor: whiteKey2
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    WhiteKey {
        id: whiteKey3

        anchor: whiteKey2
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    WhiteKey {
        id: whiteKey4

        anchor: whiteKey3
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    BlackKey {
        anchor: whiteKey4
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    WhiteKey {
        id: whiteKey5

        anchor: whiteKey4
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    BlackKey {
        anchor: whiteKey5
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    WhiteKey {
        id: whiteKey6

        anchor: whiteKey5
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    BlackKey {
        anchor: whiteKey6
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
    WhiteKey {
        anchor: whiteKey6
        keyHeight: root.keyHeight
        keyWidth: root.keyWidth
    }
}
