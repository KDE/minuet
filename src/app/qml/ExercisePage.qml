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
    readonly property string inputMode: currentExercise !== undefined && currentExercise["inputMode"] !== undefined ? currentExercise["inputMode"] : "manual"
    readonly property bool isRhythmic: currentExercise !== undefined && currentExercise["playMode"] === "rhythm"

    function exerciseItemValue(propertyName: string, fallback: var): var {
        if (exerciseLoader.status !== Loader.Ready) {
            return fallback;
        }

        const value = exerciseLoader.item[propertyName];
        return value === undefined ? fallback : value;
    }
    function offerOnboarding(): void {
        if (page.currentExercise === undefined) {
            return;
        }
        if (page.inputMode === "clapping") {
            if (Core.settingsController.clappingOnboardingPromptShown) {
                return;
            }
            Core.settingsController.clappingOnboardingPromptShown = true;
        } else if (page.inputMode === "singing") {
            if (Core.settingsController.singingOnboardingPromptShown) {
                return;
            }
            Core.settingsController.singingOnboardingPromptShown = true;
        } else if (page.isRhythmic) {
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

        Rectangle {
            id: countInOverlay

            readonly property color accentColor: initialCount ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.highlightColor
            readonly property int displayedCount: Math.max(page.exerciseItemValue("countIn", 0), page.exerciseItemValue("onboardingCountIn", 0))
            readonly property bool initialCount: page.exerciseItemValue("countInOverlayInitial", false)
            readonly property real preferredSize: page.exerciseItemValue("countInOverlaySize", Kirigami.Units.gridUnit * 5)

            function blendColor(from: color, to: color, amount: real): color {
                const clampedAmount = Math.max(0, Math.min(1, amount));
                return Qt.rgba(from.r + (to.r - from.r) * clampedAmount, from.g + (to.g - from.g) * clampedAmount, from.b + (to.b - from.b) * clampedAmount, from.a + (to.a - from.a) * clampedAmount);
            }

            Accessible.name: i18n("Count: %1", Math.max(1, displayedCount))
            Accessible.role: Accessible.StaticText
            Onboarding.groups: ["rhythmic", "clapping", "singing"]
            Onboarding.texts: [i18n("A four-beat count-in plays before the rhythm. Listen, then recreate the pattern."), i18n("A four-beat count-in plays before clapping is analyzed. Start clapping when the count finishes."), page.exerciseItemValue("scaleExercise", false) ? i18n("A four-beat count-in plays before the base note. Listen, then sing the scale notes in order.") : i18n("A four-beat count-in plays before the root note. Listen, then sing the interval note.")]
            border.color: accentColor
            border.width: 2
            color: initialCount ? blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.negativeTextColor, 0.18) : Kirigami.Theme.backgroundColor
            height: preferredSize
            radius: Math.min(width, height) / 2
            visible: displayedCount > 0
            width: preferredSize
            x: page.exerciseItemValue("countInOverlayX", Math.max(0, parent.width - width - Kirigami.Units.largeSpacing))
            y: page.exerciseItemValue("countInOverlayY", Kirigami.Units.largeSpacing)
            z: 10

            Onboarding.onAboutToShow: {
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item["onboardingCountIn"] !== undefined) {
                    exerciseLoader.item["onboardingCountIn"] = 4;
                }
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item["onboardingPreviewActive"] !== undefined) {
                    exerciseLoader.item["onboardingPreviewActive"] = true;
                }
            }
            Onboarding.onHide: {
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item["onboardingCountIn"] !== undefined) {
                    exerciseLoader.item["onboardingCountIn"] = 0;
                }
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item["onboardingPreviewActive"] !== undefined) {
                    exerciseLoader.item["onboardingPreviewActive"] = false;
                }
            }

            Kirigami.Heading {
                anchors.centerIn: parent
                color: countInOverlay.accentColor
                font.pixelSize: Math.round(countInOverlay.height * 0.46)
                horizontalAlignment: Text.AlignHCenter
                level: 1
                text: Math.max(1, countInOverlay.displayedCount).toString()
                verticalAlignment: Text.AlignVCenter
            }
        }
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
    }
    Loader {
        id: onboardingPromptLoader

        active: false

        sourceComponent: Component {
            Kirigami.PromptDialog {
                id: onboardingPrompt

                property bool startRequested: false

                dialogType: Kirigami.PromptDialog.Information
                standardButtons: Kirigami.Dialog.NoButton
                subtitle: page.inputMode === "clapping" ? i18n("This is your first clapping exercise. Start a quick guide? You can open it later from the Help icon.") : page.inputMode === "singing" ? i18n("This is your first singing exercise. Start a quick guide? You can open it later from the Help icon.") : page.isRhythmic ? i18n("This is your first rhythmic exercise. Start a quick guide? You can open it later from the Help icon.") : i18n("This is your first melodic exercise. Start a quick guide? You can open it later from the Help icon.")
                title: i18n("First Time Here")

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
