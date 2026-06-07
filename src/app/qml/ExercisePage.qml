// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: page

    property var currentExercise
    property string currentExerciseIconName: ""

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    padding: 0

    ExerciseView {
        id: exerciseView

        anchors.fill: parent
        currentExercise: page.currentExercise
        currentExerciseIconName: page.currentExerciseIconName
    }
    Rectangle {
        id: countInOverlay

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.28)
        visible: exerciseView.countIn > 0 && page.currentExercise != undefined && page.currentExercise["playMode"] === "rhythm"
        z: 10

        Rectangle {
            id: countInBubble

            anchors.centerIn: parent
            color: Kirigami.Theme.backgroundColor
            height: width
            opacity: 0.92
            radius: width / 2
            width: Kirigami.Units.gridUnit * 10

            border {
                color: Kirigami.Theme.highlightColor
                width: 3
            }
        }
        Kirigami.Heading {
            id: countInNumber

            anchors.centerIn: countInBubble
            color: Kirigami.Theme.highlightColor
            font.pointSize: Kirigami.Units.gridUnit * 3.5
            horizontalAlignment: Text.AlignHCenter
            level: 1
            text: exerciseView.countIn.toString()
            verticalAlignment: Text.AlignVCenter
        }
    }
    ParallelAnimation {
        id: countInPulse

        NumberAnimation {
            duration: 180
            easing.type: Easing.OutBack
            from: 0.65
            property: "scale"
            target: countInNumber
            to: 1.0
        }
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
            from: 0.85
            property: "scale"
            target: countInBubble
            to: 1.0
        }
    }
    Connections {
        function onCountInChanged(count: int): void {
            if (count > 0) {
                countInPulse.restart();
            } else {
                countInPulse.stop();
                countInNumber.scale = 1;
                countInBubble.scale = 1;
            }
        }

        target: Core.soundController
    }
}
