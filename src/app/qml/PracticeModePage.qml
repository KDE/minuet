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
    property string practiceMode: ""

    signal practiceSelected(var exercise, string iconName)

    function buttonIconColor(button: var): color {
        if (!button.enabled) {
            return Kirigami.Theme.disabledTextColor;
        }
        if (button.down || button.checked || button.highlighted) {
            return Kirigami.Theme.highlightedTextColor;
        }
        return Kirigami.Theme.textColor;
    }
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
        spacing: Kirigami.Units.largeSpacing
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 28)

        Kirigami.Heading {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            level: 2
            text: i18n("Choose how you would like to practice this exercise:")
            wrapMode: Text.WordWrap
        }
        QQC2.Button {
            id: identifyButton

            Layout.fillWidth: true
            icon.color: page.buttonIconColor(identifyButton)
            icon.source: page.currentExerciseIconName
            text: i18n("Hear and identify")

            onClicked: page.practiceSelected(page.currentExercise, page.currentExerciseIconName)
        }
        QQC2.Button {
            id: inputModeButton

            Layout.fillWidth: true
            icon.color: page.buttonIconColor(inputModeButton)
            icon.source: page.practiceMode === "rhythm" ? "qrc:/icons/22-actions-minuet-clap-symbolic.svg" : "qrc:/icons/22-actions-minuet-sing-symbolic.svg"
            text: page.practiceMode === "rhythm" ? i18n("Read and clap") : i18n("Read and sing")

            onClicked: {
                if (page.practiceMode === "rhythm") {
                    page.practiceSelected(page.exerciseForInputMode("clapping"), "qrc:/icons/22-actions-minuet-clap-symbolic.svg");
                } else {
                    page.practiceSelected(page.exerciseForInputMode("singing"), "qrc:/icons/22-actions-minuet-sing-symbolic.svg");
                }
            }
        }
    }
}
