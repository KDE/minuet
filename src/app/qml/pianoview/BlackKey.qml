// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

Rectangle {
    id: root

    property Item anchor
    property int keyHeight
    property int keyWidth
    property color markColor: "transparent"
    property bool marked: false

    color: "black"
    height: 0.6 * root.keyHeight
    width: 0.6 * root.keyWidth
    z: 1

    anchors {
        left: root.anchor.right
        leftMargin: -(0.6 * root.keyWidth) / 2
        top: root.anchor.top
    }
    border {
        color: "black"
        width: 1
    }
    Rectangle {
        border.color: "black"
        color: root.markColor
        height: root.keyWidth - 4
        radius: (root.keyWidth - 4) / 2
        visible: root.marked
        width: root.keyWidth - 4

        anchors {
            bottom: parent.bottom
            bottomMargin: 2
            horizontalCenter: parent.horizontalCenter
        }
    }
}
