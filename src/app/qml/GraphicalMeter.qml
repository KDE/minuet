// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string meterKind: "pitch"
    property real value: 0
    property real accuracy: 0
    property string valueText: ""
    property string readoutText: valueText.length > 0 ? valueText : (meterKind === "pitch" ? i18n("No pitch") : i18n("No onset"))
    readonly property string topLabel: meterKind === "pitch" ? i18n("TUNE") : i18n("TEMPO")
    readonly property string leftLabel: meterKind === "pitch" ? i18n("FLAT") : i18n("LATE")
    readonly property string rightLabel: meterKind === "pitch" ? i18n("SHARP") : i18n("ADVANCED")
    readonly property real needleAngle: Math.max(-1, Math.min(1, value)) * 52
    readonly property color glowColor: accuracy >= 0.75 ? Kirigami.Theme.positiveTextColor : accuracy > 0 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.disabledTextColor

    Accessible.ignored: true
    implicitHeight: Kirigami.Units.gridUnit * 8
    implicitWidth: Kirigami.Units.gridUnit * 8

    Rectangle {
        anchors.fill: parent
        color: "#442414"
        radius: width / 2

        Rectangle {
            anchors.centerIn: parent
            color: "#6c3b23"
            height: parent.height * 0.92
            radius: width / 2
            width: parent.width * 0.92
        }
        Rectangle {
            anchors.centerIn: parent
            border.color: "#ffd95c"
            border.width: Math.max(2, width * 0.035)
            color: "#d99219"
            height: parent.height * 0.82
            radius: width / 2
            width: parent.width * 0.82

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                color: "#4b2316"
                height: parent.height * 0.32
                radius: parent.width * 0.05
                width: parent.width * 0.92
            }
            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: parent.height * 0.08
                }
                color: "#ffef92"
                height: parent.height * 0.44
                radius: height / 2
                width: parent.width * 0.74
            }
/*
            Repeater {
                model: 25

                delegate: Rectangle {
                    required property int index

                    readonly property real tickAngle: -52 + index * (104 / 24)
                    readonly property bool majorTick: index % 4 === 0

                    antialiasing: true
                    color: "#5b2b17"
                    height: majorTick ? parent.height * 0.085 : parent.height * 0.052
                    radius: width / 2
                    transform: [
                        Translate {
                            x: parent.width * 0.50 - width / 2
                            y: parent.height * 0.50 - parent.height * 0.31
                        },
                        Rotation {
                            angle: tickAngle
                            origin.x: parent.width * 0.50
                            origin.y: parent.height * 0.50
                        }
                    ]
                    width: majorTick ? Math.max(2, parent.width * 0.015) : Math.max(1, parent.width * 0.01)
                }
            }
            Repeater {
                model: 5

                delegate: Rectangle {
                    required property int index

                    readonly property real markAngle: -38 + index * 19

                    antialiasing: true
                    color: "#a56413"
                    height: parent.height * 0.018
                    radius: height / 2
                    transform: [
                        Translate {
                            x: parent.width * 0.50 - width / 2
                            y: parent.height * 0.50 - parent.height * 0.20
                        },
                        Rotation {
                            angle: markAngle
                            origin.x: parent.width * 0.50
                            origin.y: parent.height * 0.50
                        }
                    ]
                    width: parent.width * 0.20
                }
            }
*/
            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: parent.height * 0.20
                }
                color: "#4d2114"
                font.bold: true
                font.pixelSize: Math.max(8, parent.width * 0.105)
                horizontalAlignment: Text.AlignHCenter
                text: root.topLabel
            }
            Text {
                anchors {
                    left: parent.left
                    leftMargin: parent.width * 0.18
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: parent.height * 0.08
                }
                color: "#4d2114"
                font.bold: true
                font.pixelSize: Math.max(7, parent.width * 0.085)
                text: root.leftLabel
            }
            Text {
                anchors {
                    right: parent.right
                    rightMargin: parent.width * 0.15
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: parent.height * 0.08
                }
                color: "#4d2114"
                font.bold: true
                font.pixelSize: Math.max(7, parent.width * 0.085)
                horizontalAlignment: Text.AlignRight
                text: root.rightLabel
            }
            Item {
                id: needlePivot

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: parent.height * 0.09
                }
                height: 1
                width: 1

                Item {
                    id: needleArm

                    height: parent.parent.height * 0.39
                    rotation: root.needleAngle
                    transformOrigin: Item.Bottom
                    width: Math.max(3, parent.parent.width * 0.025)
                    x: -width / 2
                    y: -height

                    Rectangle {
                        anchors.fill: parent
                        antialiasing: true
                        color: "#f7f7f7"
                        radius: width / 2
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.glowColor
                        height: parent.height
                        opacity: 0.28
                        radius: width / 2
                        width: parent.width * 0.42
                    }
                }
            }
            Rectangle {
                anchors.centerIn: needlePivot
                border.color: "#f4f0e8"
                border.width: Math.max(1, width * 0.09)
                color: "#c8c5bd"
                height: parent.width * 0.16
                radius: width / 2
                width: height

                Rectangle {
                    anchors.centerIn: parent
                    color: "#7d6d62"
                    height: parent.height * 0.38
                    radius: width / 2
                    width: height
                }
            }
            Rectangle {
                anchors {
                    bottom: parent.bottom
                    bottomMargin: parent.height * 0.05
                    horizontalCenter: parent.horizontalCenter
                }
                border.color: "#ffd95c"
                border.width: Math.max(1, width * 0.035)
                color: "#3c1b12"
                height: parent.height * 0.25
                radius: width / 2
                width: parent.width * 0.38

                Text {
                    anchors.centerIn: parent
                    color: "#f7dd59"
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: Math.max(7, parent.width * 0.18)
                    horizontalAlignment: Text.AlignHCenter
                    text: root.readoutText
                    width: parent.width * 0.82
                }
            }
        }
    }
}
