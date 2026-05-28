// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

Rectangle {
    id: root

    property Item anchor
    property int keyWidth
    property int keyHeight
    property bool marked: false
    property color markColor: "transparent"

    width: 0.6 * root.keyWidth; height: 0.6 * root.keyHeight
    anchors { left: root.anchor.right; leftMargin: -(0.6 * root.keyWidth) / 2; top: root.anchor.top }
    border { width: 1; color: "black" }
    color: "black"
    z: 1

    Rectangle {
        width: root.keyWidth - 4; height: root.keyWidth - 4
        radius: (root.keyWidth - 4) / 2
        border.color: "black"
        color: root.markColor
        visible: root.marked
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 2 }
    }
}
