// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: page

    property var currentExercise

    padding: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        ExerciseView {
            id: exerciseView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentExercise: page.currentExercise
        }
    }

    Rectangle {
        id: countInOverlay

        anchors.fill: parent
        z: 10
        visible: exerciseView.countIn > 0 && page.currentExercise != undefined && page.currentExercise["playMode"] === "rhythm"
        color: Qt.rgba(0, 0, 0, 0.28)

        Rectangle {
            id: countInBubble

            anchors.centerIn: parent
            width: Kirigami.Units.gridUnit * 10
            height: width
            radius: width / 2
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.highlightColor
            border.width: 3
            opacity: 0.92
        }

        Kirigami.Heading {
            id: countInNumber

            anchors.centerIn: countInBubble
            text: exerciseView.countIn.toString()
            level: 1
            font.pointSize: Kirigami.Units.gridUnit * 3.5
            color: Kirigami.Theme.highlightColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    ParallelAnimation {
        id: countInPulse

        NumberAnimation {
            target: countInNumber
            property: "scale"
            from: 0.65
            to: 1.0
            duration: 180
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: countInBubble
            property: "scale"
            from: 0.85
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: Core.soundController
        function onCountInChanged(count: int): void {
            if (count > 0) {
                countInPulse.restart()
            } else {
                countInPulse.stop()
                countInNumber.scale = 1
                countInBubble.scale = 1
            }
        }
    }
}
