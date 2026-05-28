// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

BravuraText {
    id: root

    property int clefType: 0 // [0 treble, 1 bass]
    
    objectName: "symbol"

    anchors {
        left: parent.children[0].left;
        bottom: parent.children[0].bottom;
        bottomMargin: root.clefType === 0 ? 10 : 30
    }
    text: root.clefType === 0 ? "\ue050" : "\ue062"
}
