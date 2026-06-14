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
        Onboarding.start(page.isRhythmic ? "rhythmic" : "melodic");
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
        Onboarding.sourceGroups: page.isRhythmic ? ["rhythmic"] : ["melodic"]
        anchors.fill: parent

        ExerciseView {
            id: exerciseView

            anchors.fill: parent
            currentExercise: page.currentExercise
            currentExerciseIconName: page.currentExerciseIconName
        }
        Rectangle {
            id: countInOverlay

            readonly property int displayedCount: Math.max(exerciseView.countIn, exerciseView.onboardingCountIn)

            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.28)
            visible: displayedCount > 0 && page.isRhythmic
            z: Onboarding.active ? 0 : 10

            Rectangle {
                id: countInBubble

                Onboarding.groups: ["rhythmic"]
                Onboarding.texts: [i18n("Rhythm questions begin with a four-beat count-in.")]
                Onboarding.onAboutToShow: {
                    exerciseView.onboardingCountIn = 4;
                }
                Onboarding.onHide: exerciseView.onboardingCountIn = 0

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
                subtitle: page.isRhythmic ? i18n("This is your first rhythmic exercise. Start a quick guide? You can open it later from the Help icon.") : i18n("This is your first melodic exercise. Start a quick guide? You can open it later from the Help icon.")
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
