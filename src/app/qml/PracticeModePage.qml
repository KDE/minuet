// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: page

    property var currentExercise
    property string currentExerciseIconName: ""
    readonly property var microphone: Core.microphoneInputController
    readonly property bool microphoneInputAvailable: page.microphone !== null && page.microphone.inputDeviceAvailable
    property string practiceMode: ""

    signal practiceSelected(var exercise, string iconName)

    function exerciseForInputMode(inputMode: string): var {
        let exercise = {};
        for (const key in page.currentExercise) {
            exercise[key] = page.currentExercise[key];
        }
        exercise.inputMode = inputMode;
        if (inputMode === "singing") {
            exercise.singingExerciseKind = page.practiceMode;
        }
        return exercise;
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    padding: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 28)

        Kirigami.Heading {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            level: 2
            text: i18n("Choose how you would like to practice this exercise:")
            wrapMode: Text.WordWrap
        }
        ActionListItem {
            Layout.topMargin: Kirigami.Units.largeSpacing

            action: Kirigami.Action {
                icon.name: page.currentExerciseIconName
                text: i18n("Hear and identify")

                onTriggered: page.practiceSelected(page.currentExercise, page.currentExerciseIconName)
            }
        }
        ActionListItem {
            Layout.fillWidth: true

            action: Kirigami.Action {
                enabled: page.microphoneInputAvailable
                icon.name: page.practiceMode === "rhythm" ? "qrc:/icons/22-actions-minuet-clap-symbolic.svg" : "qrc:/icons/22-actions-minuet-sing-symbolic.svg"
                text: (page.practiceMode === "rhythm" ? i18n("Read and clap") : i18n("Read and sing")) + (page.microphone !== null && !page.microphone.inputDeviceAvailable ? " " + i18n("(no microphone input devices found)") : "")

                onTriggered: {
                    if (page.practiceMode === "rhythm") {
                        page.practiceSelected(page.exerciseForInputMode("clapping"), "qrc:/icons/22-actions-minuet-clap-symbolic.svg");
                    } else {
                        page.practiceSelected(page.exerciseForInputMode("singing"), "qrc:/icons/22-actions-minuet-sing-symbolic.svg");
                    }
                }
            }
        }
    }
}
