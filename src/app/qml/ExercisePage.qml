/****************************************************************************
**
** Copyright (C) 2016 by Sandro S. Andrade <sandroandrade@kde.org>
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation; either version 2 of
** the License or (at your option) version 3 or any later version
** accepted by the membership of KDE e.V. (or its successor approved
** by the membership of KDE e.V.), which shall act as a proxy
** defined in Section 14 of version 3 of the license.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: page

    property var currentExercise
    property string pathText: title

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
            font.pixelSize: Kirigami.Units.gridUnit * 5
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
