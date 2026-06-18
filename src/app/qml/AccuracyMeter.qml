// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property color accentColor: Kirigami.Theme.highlightColor
    property string label: ""
    property real value: 0
    property string valueText: ""

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true

        QQC2.Label {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.label
        }
        QQC2.Label {
            color: Kirigami.Theme.disabledTextColor
            text: root.valueText
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit
        color: Kirigami.Theme.alternateBackgroundColor
        radius: Kirigami.Units.cornerRadius

        Rectangle {
            color: root.accentColor
            radius: parent.radius
            width: parent.width * Math.max(0, Math.min(1, root.value))

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }
    }
}
