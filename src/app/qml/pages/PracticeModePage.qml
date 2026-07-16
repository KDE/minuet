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

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    padding: 0

    QtObject {
        id: internal

        readonly property var microphone: Core.microphoneInputController
    }
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
                enabled: internal.microphone !== null && internal.microphone.inputDeviceAvailable
                icon.name: page.practiceMode === "rhythm" ? "qrc:/icons/22-actions-minuet-clap-symbolic.svg" : "qrc:/icons/22-actions-minuet-sing-symbolic.svg"
                text: (page.practiceMode === "rhythm" ? i18n("Read and clap") : i18n("Read and sing")) + (internal.microphone !== null && !internal.microphone.inputDeviceAvailable ? " " + i18n("(no microphone input devices found)") : "")

                onTriggered: {
                    if (page.practiceMode === "rhythm") {
                        page.practiceSelected(Core.exerciseCatalogController.exerciseForInputMode(page.currentExercise, "clapping", page.practiceMode), "qrc:/icons/22-actions-minuet-clap-symbolic.svg");
                    } else {
                        page.practiceSelected(Core.exerciseCatalogController.exerciseForInputMode(page.currentExercise, "singing", page.practiceMode), "qrc:/icons/22-actions-minuet-sing-symbolic.svg");
                    }
                }
            }
        }
    }
}
