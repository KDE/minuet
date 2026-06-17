// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.onboarding

Kirigami.Page {
    id: page

    property var currentExercise
    property string currentExerciseIconName: ""
    readonly property bool isRhythmic: currentExercise !== undefined && currentExercise["playMode"] === "rhythm"
    readonly property string inputMode: currentExercise !== undefined && currentExercise["inputMode"] !== undefined ? currentExercise["inputMode"] : "manual"

    function offerOnboarding(): void {
        if (page.currentExercise === undefined) {
            return;
        }
        if (page.isRhythmic) {
            if (Core.settingsController.rhythmicOnboardingPromptShown) {
                return;
            }
            Core.settingsController.rhythmicOnboardingPromptShown = true;
        } else {
            if (Core.settingsController.melodicOnboardingPromptShown) {
                return;
            }
            Core.settingsController.melodicOnboardingPromptShown = true;
        }
        onboardingPromptLoader.active = true;
    }
    function startOnboarding(): void {
        Onboarding.start(page.inputMode === "clapping" ? "clapping" : page.inputMode === "singing" ? "singing" : page.isRhythmic ? "rhythmic" : "melodic");
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    padding: 0

    actions: [
        Kirigami.Action {
            icon.name: "help-contents"
            text: i18nc("@action:button", "Help")

            onTriggered: page.startOnboarding()
        }
    ]

    Component.onCompleted: Qt.callLater(page.offerOnboarding)

    Item {
        id: onboardingSource

        Onboarding.isSource: page === applicationWindow().currentPage
        Onboarding.sourceGroups: page.inputMode === "clapping" ? ["clapping"] : page.inputMode === "singing" ? ["singing"] : page.isRhythmic ? ["rhythmic"] : ["melodic"]
        anchors.fill: parent

        Loader {
            id: exerciseLoader

            anchors.fill: parent
            sourceComponent: {
                if (page.inputMode === "clapping") {
                    return clappingExerciseComponent;
                }
                if (page.inputMode === "singing") {
                    return singingExerciseComponent;
                }
                return manualExerciseComponent;
            }

            onLoaded: {
                if (status === Loader.Ready) {
                    item.currentExercise = page.currentExercise;
                    item.currentExerciseIconName = page.currentExerciseIconName;
                }
            }
        }
        Component {
            id: manualExerciseComponent

            ExerciseView {
            }
        }
        Component {
            id: clappingExerciseComponent

            ExerciseClappingView {
            }
        }
        Component {
            id: singingExerciseComponent

            ExerciseSingingView {
            }
        }
        Rectangle {
            id: countInOverlay

            readonly property int displayedCount: Math.max(exerciseLoader.status === Loader.Ready && exerciseLoader.item.countIn !== undefined ? exerciseLoader.item.countIn : 0, exerciseLoader.status === Loader.Ready && exerciseLoader.item.onboardingCountIn !== undefined ? exerciseLoader.item.onboardingCountIn : 0)

            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.28)
            visible: displayedCount > 0
            z: Onboarding.active ? 0 : 10

            onDisplayedCountChanged: {
                if (displayedCount > 0) {
                    countInPulse.restart();
                }
            }

            Rectangle {
                id: countInBubble

                Onboarding.groups: ["rhythmic", "clapping", "singing"]
                Onboarding.texts: [
                    i18n("Rhythm questions begin with a count-in."),
                    i18n("Clapping exercises count to the number of rhythm patterns before recording, then repeat that count while you clap."),
                    i18n("Singing exercises count in before the first note; then sing one displayed note on each count.")
                ]
                Onboarding.onAboutToShow: {
                    if (exerciseLoader.status === Loader.Ready && exerciseLoader.item.onboardingCountIn !== undefined) {
                        exerciseLoader.item.onboardingCountIn = 4;
                    }
                }
                Onboarding.onHide: {
                    if (exerciseLoader.status === Loader.Ready && exerciseLoader.item.onboardingCountIn !== undefined) {
                        exerciseLoader.item.onboardingCountIn = 0;
                    }
                }

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
                text: countInOverlay.displayedCount.toString()
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
                if (page.inputMode !== "manual") {
                    return;
                }
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
    Loader {
        id: onboardingPromptLoader

        active: false
        sourceComponent: Component {
            Kirigami.PromptDialog {
                id: onboardingPrompt

                property bool startRequested: false

                dialogType: Kirigami.PromptDialog.Information
                subtitle: page.inputMode === "clapping" ? i18n("This is your first clapping exercise. Start a quick guide? You can open it later from the Help icon.") : page.inputMode === "singing" ? i18n("This is your first singing exercise. Start a quick guide? You can open it later from the Help icon.") : page.isRhythmic ? i18n("This is your first rhythmic exercise. Start a quick guide? You can open it later from the Help icon.") : i18n("This is your first melodic exercise. Start a quick guide? You can open it later from the Help icon.")
                title: i18n("First Time Here")
                standardButtons: Kirigami.Dialog.NoButton

                customFooterActions: [
                    Kirigami.Action {
                        icon.name: "help-contents"
                        text: i18nc("@action:button", "Start Guide")

                        onTriggered: {
                            onboardingPrompt.startRequested = true;
                            onboardingPrompt.close();
                        }
                    },
                    Kirigami.Action {
                        icon.name: "dialog-cancel-symbolic"
                        text: i18nc("@action:button", "Not Now")

                        onTriggered: onboardingPrompt.close()
                    }
                ]

                onClosed: {
                    const shouldStart = onboardingPrompt.startRequested;
                    Qt.callLater(function () {
                        onboardingPromptLoader.active = false;
                        if (shouldStart) {
                            page.startOnboarding();
                        }
                    });
                }
            }
        }

        onLoaded: {
            if (status === Loader.Ready) {
                (item as Kirigami.PromptDialog).open();
            }
        }
    }
}
