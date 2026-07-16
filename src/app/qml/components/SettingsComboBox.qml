// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property int currentIndex: -1
    property string description: ""
    property string label: ""
    property real labelWidth: Kirigami.Units.gridUnit * 10
    property var model: []
    property string textRole: ""
    property string valueRole: ""

    signal activated(var currentValue, int currentIndex)

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true

        QQC2.Label {
            Layout.preferredWidth: root.labelWidth
            elide: Text.ElideRight
            text: root.label
        }
        QQC2.ComboBox {
            Layout.fillWidth: true
            currentIndex: root.currentIndex
            model: root.model
            textRole: root.textRole
            valueRole: root.valueRole

            onActivated: root.activated(currentValue, currentIndex)
        }
    }
    QQC2.Label {
        Layout.fillWidth: true
        Layout.leftMargin: root.labelWidth + Kirigami.Units.smallSpacing
        color: Kirigami.Theme.disabledTextColor
        text: root.description
        visible: root.description.length > 0
        wrapMode: Text.WordWrap
    }
}
