// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real accuracy: 0
    property string meterKind: "pitch"
    property string noReadingText: internal.defaultReadoutText
    property string readoutText: root.noReadingText
    property real value: 0

    implicitHeight: internal.meterHeight + internal.spacing + deviationLabel.implicitHeight
    implicitWidth: Math.max(Kirigami.Units.gridUnit * 3.2, sampleReadoutLabel.implicitWidth + Kirigami.Units.smallSpacing)

    QtObject {
        id: internal

        readonly property int activeSteps: Math.ceil(Math.abs(internal.clampedValue) * internal.centerIndex)
        readonly property int centerIndex: Math.floor(internal.segmentCount / 2)
        readonly property real clampedAccuracy: Math.max(0, Math.min(1, root.accuracy))
        readonly property real clampedValue: Math.max(-1, Math.min(1, root.value))
        readonly property string defaultReadoutText: root.meterKind === "pitch" ? i18n("No pitch") : i18n("No onset")
        readonly property string displayText: root.readoutText.length > 0 ? root.readoutText : internal.defaultReadoutText
        readonly property bool hasReading: internal.displayText !== root.noReadingText
        readonly property real meterHeight: internal.segmentCount * internal.segmentHeight + Math.max(0, internal.segmentCount - 1) * internal.segmentSpacing + Kirigami.Units.smallSpacing * 2
        readonly property int segmentCount: 15
        readonly property real segmentHeight: Math.max(4, Math.round(Kirigami.Units.gridUnit * 0.34))
        readonly property real segmentSpacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 2))
        readonly property real spacing: Kirigami.Units.smallSpacing

        function activeSegmentColor(distance: int): color {
            const ratio = Math.abs(distance) / internal.centerIndex;
            const amount = 0.72 + internal.clampedAccuracy * 0.2;
            if (ratio >= 0.76) {
                return internal.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.negativeTextColor, amount);
            }
            if (ratio >= 0.46) {
                return internal.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.neutralTextColor, amount);
            }
            return internal.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.positiveTextColor, amount);
        }
        function blendColor(from: color, to: color, amount: real): color {
            const clampedAmount = Math.max(0, Math.min(1, amount));
            return Qt.rgba(from.r + (to.r - from.r) * clampedAmount, from.g + (to.g - from.g) * clampedAmount, from.b + (to.b - from.b) * clampedAmount, from.a + (to.a - from.a) * clampedAmount);
        }
        function inactiveSegmentColor(distance: int): color {
            const base = distance === 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor;
            const amount = distance === 0 ? 0.32 : 0.14;
            return internal.blendColor(Kirigami.Theme.backgroundColor, base, amount);
        }
    }
    QQC2.Label {
        id: sampleReadoutLabel

        font: deviationLabel.font
        text: root.meterKind === "pitch" ? i18n("%1 cents").arg(12345) : i18n("%1 ms").arg(12345)
        visible: false
    }
    Column {
        anchors.fill: parent
        spacing: internal.spacing

        Item {
            id: meterBody

            height: internal.meterHeight
            width: parent.width

            Rectangle {
                anchors.fill: parent
                color: internal.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.alternateBackgroundColor, 0.62)
                radius: Kirigami.Units.cornerRadius

                border {
                    color: internal.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.22)
                    width: 1
                }
            }
            Column {
                anchors.centerIn: parent
                spacing: internal.segmentSpacing

                Repeater {
                    model: internal.segmentCount

                    delegate: Rectangle {
                        id: segment

                        required property int index

                        color: {
                            if (segmentInternal.centered && internal.hasReading && internal.activeSteps === 0) {
                                return internal.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.positiveTextColor, 0.72 + internal.clampedAccuracy * 0.2);
                            }
                            if (segmentInternal.active) {
                                return internal.activeSegmentColor(segmentInternal.signedDistance);
                            }
                            return internal.inactiveSegmentColor(segmentInternal.signedDistance);
                        }
                        height: internal.segmentHeight
                        radius: Math.max(1, Math.round(internal.segmentHeight / 4))
                        width: Math.max(Kirigami.Units.gridUnit * 1.2, Math.min(meterBody.width - Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 2.4))

                        QtObject {
                            id: segmentInternal

                            readonly property bool active: internal.hasReading && segmentInternal.signedDistance !== 0 && Math.sign(internal.clampedValue) === Math.sign(segmentInternal.signedDistance) && Math.abs(segmentInternal.signedDistance) <= internal.activeSteps
                            readonly property bool centered: segmentInternal.signedDistance === 0
                            readonly property int signedDistance: internal.centerIndex - segment.index
                        }
                        border {
                            color: segmentInternal.centered ? Kirigami.Theme.highlightColor : internal.blendColor(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, segmentInternal.active ? 0.44 : 0.18)
                            width: segmentInternal.centered ? 2 : 1
                        }
                    }
                }
            }
        }
        QQC2.Label {
            id: deviationLabel

            color: internal.hasReading ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            font.bold: internal.hasReading
            horizontalAlignment: Text.AlignHCenter
            text: internal.displayText
            width: parent.width
        }
    }
}
