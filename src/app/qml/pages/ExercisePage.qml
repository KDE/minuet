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

    function exerciseItemValue(propertyName: string, fallback: var): var {
        if (exerciseLoader.status !== Loader.Ready || exerciseLoader.item === null) {
            return fallback;
        }

        const value = exerciseLoader.item[propertyName];
        return value === undefined ? fallback : value;
    }
    function offerOnboarding(): void {
        onboardingPromptLoader.active = page.currentExercise !== undefined && Core.settingsController.takeOnboardingPrompt(internal.inputMode, internal.isRhythmic);
    }
    function pulseCountIn(): void {
        countInPulseAnimation.stop();
        countInCircle.scale = 1;
        countInFlash.opacity = 0;
        countInPulseAnimation.start();
    }
    function resetCountInPulse(): void {
        countInPulseAnimation.stop();
        countInCircle.scale = 1;
        countInFlash.opacity = 0;
    }
    function stopExerciseActivity(): void {
        if (exerciseLoader.status === Loader.Ready && exerciseLoader.item !== null && typeof exerciseLoader.item.stopExerciseActivity === "function") {
            exerciseLoader.item.onboardingCardsHidden = false;
            exerciseLoader.item.stopExerciseActivity();
        }
        resetCountInPulse();
        page.currentExercise = undefined;
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    padding: 0

    actions: [
        Kirigami.Action {
            icon.name: "help-contents"
            text: i18nc("@action:button", "Help")

            onTriggered: Onboarding.start(internal.onboardingGroup)
        }
    ]

    Component.onCompleted: Qt.callLater(page.offerOnboarding)

    QtObject {
        id: internal

        readonly property string inputMode: page.currentExercise !== undefined && page.currentExercise["inputMode"] !== undefined ? page.currentExercise["inputMode"] : "manual"
        readonly property bool isRhythmic: page.currentExercise !== undefined && page.currentExercise["playMode"] === "rhythm"
        readonly property string onboardingGroup: inputMode === "clapping" ? "clapping" : inputMode === "singing" ? "singing" : isRhythmic ? "rhythmic" : "melodic"
        readonly property int rhythmSubTickInterval: Core.soundController === null ? 250 : Math.max(1, Math.round(60000 / Core.soundController.tempo / internal.rhythmSubdivisionCount))
        readonly property int rhythmSubdivisionCount: Core.soundController === null ? 1 : Core.soundController.rhythmCountInSubdivisions
    }
    Item {
        id: onboardingSource

        Onboarding.isSource: page === applicationWindow().currentPage
        Onboarding.sourceGroups: internal.inputMode === "clapping" ? ["clapping"] : internal.inputMode === "singing" ? ["singing"] : internal.isRhythmic ? ["rhythmic"] : ["melodic"]
        anchors.fill: parent

        Item {
            id: countInOverlay

            readonly property color accentColor: initialCount ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.highlightColor
            readonly property int displayedCount: Math.max(page.exerciseItemValue("countIn", 0), page.exerciseItemValue("onboardingCountIn", 0))
            readonly property bool initialCount: page.exerciseItemValue("countInOverlayInitial", false)
            readonly property real preferredSize: page.exerciseItemValue("countInOverlaySize", Kirigami.Units.gridUnit * 5)

            function blendColor(from: color, to: color, amount: real): color {
                const clampedAmount = Math.max(0, Math.min(1, amount));
                return Qt.rgba(from.r + (to.r - from.r) * clampedAmount, from.g + (to.g - from.g) * clampedAmount, from.b + (to.b - from.b) * clampedAmount, from.a + (to.a - from.a) * clampedAmount);
            }

            Onboarding.groups: ["rhythmic", "clapping", "singing"]
            Onboarding.texts: [i18n("A four-beat count-in plays before the rhythm. Listen, then recreate the pattern."), i18n("A four-beat count-in plays before clapping is analyzed. Start clapping when the count finishes."), page.exerciseItemValue("scaleExercise", false) ? i18n("A four-beat count-in plays before the base note. Listen, then sing the scale notes in order.") : i18n("A four-beat count-in plays before the root note. Listen, then sing the interval note.")]
            height: preferredSize
            visible: displayedCount > 0
            width: preferredSize
            x: page.exerciseItemValue("countInOverlayX", Math.max(0, parent.width - width - Kirigami.Units.largeSpacing))
            y: page.exerciseItemValue("countInOverlayY", Kirigami.Units.largeSpacing)
            z: 10

            Onboarding.onAboutToShow: {
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item !== null && exerciseLoader.item["onboardingCountIn"] !== undefined) {
                    exerciseLoader.item["onboardingCountIn"] = 4;
                }
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item !== null && exerciseLoader.item["onboardingPreviewActive"] !== undefined) {
                    exerciseLoader.item["onboardingPreviewActive"] = true;
                }
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item !== null) {
                    exerciseLoader.item.onboardingCardsHidden = true;
                }
            }
            Onboarding.onHide: {
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item !== null && exerciseLoader.item["onboardingCountIn"] !== undefined) {
                    exerciseLoader.item["onboardingCountIn"] = 0;
                }
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item !== null && exerciseLoader.item["onboardingPreviewActive"] !== undefined) {
                    exerciseLoader.item["onboardingPreviewActive"] = false;
                }
                if (exerciseLoader.status === Loader.Ready && exerciseLoader.item !== null) {
                    exerciseLoader.item.onboardingCardsHidden = false;
                }
            }
            onDisplayedCountChanged: {
                if (displayedCount > 0) {
                    page.pulseCountIn();
                } else {
                    page.resetCountInPulse();
                }
            }

            Rectangle {
                id: countInCircle

                anchors.fill: parent
                color: countInOverlay.initialCount ? countInOverlay.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.negativeTextColor, 0.18) : Kirigami.Theme.backgroundColor
                radius: Math.min(width, height) / 2

                border {
                    color: countInOverlay.accentColor
                    width: 2
                }
                Rectangle {
                    id: countInFlash

                    anchors.fill: parent
                    color: countInOverlay.blendColor(Kirigami.Theme.backgroundColor, countInOverlay.accentColor, 0.72)
                    opacity: 0
                    radius: parent.radius
                    visible: countInPulseAnimation.running

                    border {
                        color: countInOverlay.accentColor
                        width: 3
                    }
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
                visible: countInOverlay.displayedCount > 0
            }
        }
        ParallelAnimation {
            id: countInPulseAnimation

            OpacityAnimator {
                duration: Math.max(100, Math.min(240, Math.round(internal.rhythmSubTickInterval * 0.9)))
                easing.type: Easing.OutCubic
                from: 0.62
                target: countInFlash
                to: 0
            }
            ScaleAnimator {
                duration: Math.max(100, Math.min(240, Math.round(internal.rhythmSubTickInterval * 0.9)))
                easing.type: Easing.OutCubic
                from: 1.16
                target: countInCircle
                to: 1
            }
        }
        Connections {
            function onCountInSubTick(): void {
                if (countInOverlay.displayedCount > 0 && internal.rhythmSubdivisionCount > 1) {
                    page.pulseCountIn();
                }
            }

            target: Core.soundController
        }
        Loader {
            id: exerciseLoader

            active: page.currentExercise !== undefined
            anchors.fill: parent
            sourceComponent: {
                if (internal.inputMode === "clapping") {
                    return clappingExerciseComponent;
                }
                if (internal.inputMode === "singing") {
                    return singingExerciseComponent;
                }
                return manualExerciseComponent;
            }
        }
        Component {
            id: manualExerciseComponent

            ExerciseView {
                currentExercise: page.currentExercise
                currentExerciseIconName: page.currentExerciseIconName

                onCountInSubTickRequested: {
                    if (countInOverlay.displayedCount > 0) {
                        page.pulseCountIn();
                    }
                }
            }
        }
        Component {
            id: clappingExerciseComponent

            ExerciseClappingView {
                currentExercise: page.currentExercise
                currentExerciseIconName: page.currentExerciseIconName
            }
        }
        Component {
            id: singingExerciseComponent

            ExerciseSingingView {
                currentExercise: page.currentExercise
                currentExerciseIconName: page.currentExerciseIconName

                onCountInSubTickRequested: {
                    if (countInOverlay.displayedCount > 0) {
                        page.pulseCountIn();
                    }
                }
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
                subtitle: internal.inputMode === "clapping" ? i18n("This is your first clapping exercise. Start a quick guide? You can open it later from the Help icon.") : internal.inputMode === "singing" ? i18n("This is your first singing exercise. Start a quick guide? You can open it later from the Help icon.") : internal.isRhythmic ? i18n("This is your first rhythmic exercise. Start a quick guide? You can open it later from the Help icon.") : i18n("This is your first melodic exercise. Start a quick guide? You can open it later from the Help icon.")
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
                    if (onboardingPrompt.startRequested) {
                        Onboarding.start(internal.onboardingGroup);
                    }
                    onboardingPromptLoader.active = false;
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
