// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real accuracy: 0
    readonly property int activeSteps: Math.ceil(Math.abs(root.clampedValue) * root.centerIndex)
    readonly property int centerIndex: Math.floor(root.segmentCount / 2)
    readonly property real clampedAccuracy: Math.max(0, Math.min(1, root.accuracy))
    readonly property real clampedValue: Math.max(-1, Math.min(1, root.value))
    readonly property string defaultReadoutText: root.meterKind === "pitch" ? i18n("No pitch") : i18n("No onset")
    readonly property string displayText: root.readoutText.length > 0 ? root.readoutText : root.defaultReadoutText
    readonly property bool hasReading: root.displayText !== root.noReadingText
    readonly property real meterHeight: root.segmentCount * root.segmentHeight + Math.max(0, root.segmentCount - 1) * root.segmentSpacing + Kirigami.Units.smallSpacing * 2
    property string meterKind: "pitch"
    property string noReadingText: root.defaultReadoutText
    property string readoutText: root.valueText.length > 0 ? root.valueText : root.noReadingText
    property string sampleReadoutText: root.meterKind === "pitch" ? i18n("%1 cents").arg(12345) : i18n("%1 ms").arg(12345)
    readonly property int segmentCount: 17
    readonly property real segmentHeight: Math.max(4, Math.round(Kirigami.Units.gridUnit * 0.34))
    readonly property real segmentSpacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 2))
    readonly property real spacing: Kirigami.Units.smallSpacing
    property real value: 0
    property string valueText: ""

    function activeSegmentColor(distance: int): color {
        const ratio = Math.abs(distance) / root.centerIndex;
        const amount = 0.72 + root.clampedAccuracy * 0.2;
        if (ratio >= 0.76) {
            return root.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.negativeTextColor, amount);
        }
        if (ratio >= 0.46) {
            return root.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.neutralTextColor, amount);
        }
        return root.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.positiveTextColor, amount);
    }
    function blendColor(from: color, to: color, amount: real): color {
        const clampedAmount = Math.max(0, Math.min(1, amount));
        return Qt.rgba(from.r + (to.r - from.r) * clampedAmount, from.g + (to.g - from.g) * clampedAmount, from.b + (to.b - from.b) * clampedAmount, from.a + (to.a - from.a) * clampedAmount);
    }
    function inactiveSegmentColor(distance: int): color {
        const base = distance === 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor;
        const amount = distance === 0 ? 0.32 : 0.14;
        return root.blendColor(Kirigami.Theme.backgroundColor, base, amount);
    }

    Accessible.name: root.meterKind === "pitch" ? i18n("Pitch deviation: %1", root.displayText) : i18n("Onset deviation: %1", root.displayText)
    Accessible.role: Accessible.ProgressBar
    implicitHeight: root.meterHeight + root.spacing + deviationLabel.implicitHeight
    implicitWidth: Math.max(Kirigami.Units.gridUnit * 3.2, sampleReadoutLabel.implicitWidth + Kirigami.Units.smallSpacing)

    QQC2.Label {
        id: sampleReadoutLabel

        font: deviationLabel.font
        text: root.sampleReadoutText
        visible: false
    }
    Column {
        anchors.fill: parent
        spacing: root.spacing

        Item {
            id: meterBody

            height: root.meterHeight
            width: parent.width

            Rectangle {
                anchors.fill: parent
                border.color: root.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.22)
                border.width: 1
                color: root.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.alternateBackgroundColor, 0.62)
                radius: Kirigami.Units.cornerRadius
            }
            Column {
                anchors.centerIn: parent
                spacing: root.segmentSpacing

                Repeater {
                    model: root.segmentCount

                    delegate: Rectangle {
                        id: segment

                        readonly property bool active: root.hasReading && segment.signedDistance !== 0 && Math.sign(root.clampedValue) === Math.sign(segment.signedDistance) && Math.abs(segment.signedDistance) <= root.activeSteps
                        readonly property bool centered: segment.signedDistance === 0
                        required property int index
                        readonly property int signedDistance: root.centerIndex - segment.index

                        border.color: segment.centered ? Kirigami.Theme.highlightColor : root.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, segment.active ? 0.44 : 0.18)
                        border.width: segment.centered ? 2 : 1
                        color: {
                            if (segment.centered && root.hasReading && root.activeSteps === 0) {
                                return root.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.positiveTextColor, 0.72 + root.clampedAccuracy * 0.2);
                            }
                            if (segment.active) {
                                return root.activeSegmentColor(segment.signedDistance);
                            }
                            return root.inactiveSegmentColor(segment.signedDistance);
                        }
                        height: root.segmentHeight
                        radius: Math.max(1, Math.round(root.segmentHeight / 4))
                        width: Math.max(Kirigami.Units.gridUnit * 1.2, Math.min(meterBody.width - Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 2.4))
                    }
                }
            }
        }
        QQC2.Label {
            id: deviationLabel

            color: root.hasReading ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            font.bold: root.hasReading
            horizontalAlignment: Text.AlignHCenter
            text: root.displayText
            width: parent.width
        }
    }
}
