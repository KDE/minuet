// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

Item {
    id: root

    property Item initialAnchor
    property int keyWidth
    property int keyHeight

    width: 7 * root.keyWidth; height: root.keyHeight - 10
    anchors.left: root.initialAnchor.right

    WhiteKey { id: whiteKey1; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    BlackKey { anchor: whiteKey1; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    WhiteKey { id: whiteKey2; anchor: whiteKey1; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    BlackKey { anchor: whiteKey2; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    WhiteKey { id: whiteKey3; anchor: whiteKey2; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    WhiteKey { id: whiteKey4; anchor: whiteKey3; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    BlackKey { anchor: whiteKey4; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    WhiteKey { id: whiteKey5; anchor: whiteKey4; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    BlackKey { anchor: whiteKey5; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    WhiteKey { id: whiteKey6; anchor: whiteKey5; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    BlackKey { anchor: whiteKey6; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
    WhiteKey { anchor: whiteKey6; keyWidth: root.keyWidth; keyHeight: root.keyHeight }
}
