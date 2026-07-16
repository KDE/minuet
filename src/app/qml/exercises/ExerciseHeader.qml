// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.onboarding

Rectangle {
    id: root

    property real actionButtonWidth: 0
    default property alias actionContent: actionRow.data
    property var actionOnboardingTexts: []
    property bool compactMode: false
    property string iconName: ""
    property var onboardingGroups: []
    property var onboardingTexts: []
    property string subtitle: ""
    property color subtitleColor: Kirigami.Theme.disabledTextColor
    property string title: ""

    Layout.fillWidth: true
    Layout.preferredHeight: headerLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
    color: Kirigami.Theme.alternateBackgroundColor

    QtObject {
        id: internal

        readonly property real iconSideLength: icon.visible ? centerColumn.implicitHeight : 0
    }
    RowLayout {
        id: headerLayout

        spacing: Kirigami.Units.largeSpacing

        anchors {
            fill: parent
            margins: Kirigami.Units.largeSpacing
        }
        Kirigami.Icon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: internal.iconSideLength * 0.75
            Layout.preferredWidth: internal.iconSideLength
            source: root.iconName
            visible: root.iconName.length > 0 && !root.compactMode
        }
        ColumnLayout {
            id: centerColumn

            Layout.fillWidth: true
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Onboarding.groups: root.onboardingGroups
                Onboarding.texts: root.onboardingTexts
                spacing: 0

                Kirigami.Heading {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    level: 3
                    text: root.title
                }
                Kirigami.Heading {
                    Layout.fillWidth: true
                    color: root.subtitleColor
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    level: 3
                    text: root.subtitle
                }
            }
            RowLayout {
                id: actionRow

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Kirigami.Units.smallSpacing
                Onboarding.groups: root.onboardingGroups
                Onboarding.texts: root.actionOnboardingTexts.length > 0 ? root.actionOnboardingTexts : root.onboardingTexts
                spacing: Kirigami.Units.smallSpacing
            }
        }
        Item {
            Layout.preferredHeight: 1
            Layout.preferredWidth: internal.iconSideLength
            visible: icon.visible
        }
    }
    Kirigami.Separator {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
    }
}
