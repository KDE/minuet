// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real accuracy: 0
    readonly property real assetAspectRatio: 1448 / 1086
    readonly property real clampedValue: Math.max(-1, Math.min(1, value))
    readonly property string defaultReadoutText: meterKind === "pitch" ? i18n("No pitch") : i18n("No onset")
    readonly property string displayText: readoutText.length > 0 ? readoutText : defaultReadoutText
    readonly property real faceHeight: Math.max(1, faceWidth / assetAspectRatio)
    readonly property real faceWidth: Math.max(1, Math.min(width, Math.max(1, height - deviationLabel.implicitHeight - spacing) * assetAspectRatio))
    readonly property real maximumNeedleAngle: meterKind === "pitch" ? 52 : 58
    readonly property string meterBackgroundSource: meterKind === "pitch" ? "qrc:/icons/pitch-meter-background.png" : "qrc:/icons/tempo-meter-background.png"
    property string meterKind: "pitch"
    readonly property real needleAngle: clampedValue * maximumNeedleAngle
    readonly property real needleFacePivotY: 0.617 //meterKind === "pitch" ? 0.617 : 0.765
    readonly property real needleLocalPivotY: meterKind === "pitch" ? 0.812 : 0.765
    readonly property real needleScale: 0.53 //meterKind === "pitch" ? 0.53 : 0.80
    readonly property string needleSource: "qrc:/icons/meter-needle.png"
    property string readoutText: valueText.length > 0 ? valueText : defaultReadoutText
    readonly property real spacing: Kirigami.Units.smallSpacing
    property real value: 0
    property string valueText: ""

    Accessible.ignored: true
    implicitHeight: Math.max(1, width > 0 ? width : implicitWidth) / assetAspectRatio + deviationLabel.implicitHeight + spacing
    implicitWidth: Kirigami.Units.gridUnit * 8

    Item {
        id: meterFace

        height: root.faceHeight
        width: root.faceWidth

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }
        Image {
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.Stretch
            mipmap: true
            smooth: true
            source: root.meterBackgroundSource
            sourceSize.height: 1086
            sourceSize.width: 1448
        }
        Image {
            id: needleImage

            antialiasing: true
            asynchronous: true
            fillMode: Image.Stretch
            height: parent.height * root.needleScale
            mipmap: true
            smooth: true
            source: root.needleSource
            sourceSize.height: 1086
            sourceSize.width: 1448
            width: parent.width * root.needleScale
            x: parent.width * 0.5 - width * 0.5
            y: parent.height * root.needleFacePivotY - height * root.needleLocalPivotY

            transform: Rotation {
                angle: root.needleAngle
                origin.x: needleImage.width * 0.5
                origin.y: needleImage.height * root.needleLocalPivotY
            }
        }
    }
    QQC2.Label {
        id: deviationLabel

        color: root.displayText === root.defaultReadoutText ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
        elide: Text.ElideRight
        font.bold: root.displayText !== root.defaultReadoutText
        horizontalAlignment: Text.AlignHCenter
        text: root.displayText
        width: root.width

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: meterFace.bottom
            topMargin: root.spacing
        }
    }
}
