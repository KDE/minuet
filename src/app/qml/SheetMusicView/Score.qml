// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

Item {
    id: score

    implicitWidth: row.implicitWidth

    property int pointSize
    property int spacing
    property Clef clef

    objectName: "score"

    Row {
        id: row

        width: score.width
        anchors.verticalCenter: score.verticalCenter
        clip: true
        spacing: 0

        BravuraText {
            id: staffSegmentMetrics

            visible: false
            text: "\ue014"
        }

        Repeater {
            model: staffSegmentMetrics.implicitWidth > 0 ? Math.max(15, Math.ceil(score.width / staffSegmentMetrics.implicitWidth) + 1) : 15
            BravuraText { text: "\ue014" }
        }
    }
}
