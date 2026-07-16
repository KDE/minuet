// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.onboarding

RowLayout {
    id: root

    required property string calibrationHelpText
    required property string inputHelpText
    property IMicrophoneInputController microphone
    property bool microphoneReady: false
    required property string onboardingGroup

    signal calibrateRequested

    spacing: Kirigami.Units.largeSpacing

    AccuracyMeter {
        Layout.fillWidth: true
        Onboarding.groups: [root.onboardingGroup]
        Onboarding.texts: [root.inputHelpText]
        accentColor: root.microphone && root.microphone.inputGateOpen ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
        label: i18n("Input level")
        value: root.microphone ? Math.min(1, root.microphone.audioLevel * 12) : 0
        valueText: root.microphone && root.microphone.inputGateOpen ? i18n("Open") : i18n("Closed")
    }
    QQC2.Button {
        id: calibrateButton

        Layout.preferredWidth: Math.max(calibrateButton.implicitWidth, calibrationProbe.implicitWidth)
        Onboarding.groups: [root.onboardingGroup]
        Onboarding.texts: [root.calibrationHelpText]
        enabled: root.microphoneReady
        text: root.microphone && root.microphone.noiseCalibrationActive ? i18n("Calibrating...") : i18n("Calibrate Silence")

        onClicked: root.calibrateRequested()
    }
    QQC2.Button {
        id: calibrationProbe

        text: i18n("Calibrating...")
        visible: false
    }
}
