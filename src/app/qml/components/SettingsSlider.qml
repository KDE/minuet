// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property int decimals: 0
    property string description: ""
    property real from: 0
    property string label: ""
    property real labelWidth: Kirigami.Units.gridUnit * 10
    property real stepSize: 1
    property string suffix: ""
    property real to: 100
    property real value: 0

    signal moved(real value)

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true

        QQC2.Label {
            Layout.preferredWidth: root.labelWidth
            elide: Text.ElideRight
            text: root.label
        }
        QQC2.Slider {
            id: slider

            Layout.fillWidth: true
            from: root.from
            snapMode: QQC2.Slider.NoSnap
            stepSize: root.stepSize
            to: root.to
            value: root.value

            onMoved: {
                const adjustedValue = root.decimals === 0 ? Math.round(value) : Number(value.toFixed(root.decimals));
                root.moved(adjustedValue);
            }
        }
        QQC2.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 4
            color: Kirigami.Theme.disabledTextColor
            horizontalAlignment: Text.AlignRight
            text: {
                const numericValue = root.decimals === 0 ? Math.round(slider.value).toString() : slider.value.toFixed(root.decimals);
                return root.suffix.length > 0 ? i18n("%1 %2", numericValue, root.suffix) : numericValue;
            }
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
