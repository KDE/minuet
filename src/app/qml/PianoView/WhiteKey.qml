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

    color: "white"
    height: root.keyHeight
    width: root.keyWidth

    Component.onCompleted: if (root.anchor !== null)
        anchors.left = root.anchor.right

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
