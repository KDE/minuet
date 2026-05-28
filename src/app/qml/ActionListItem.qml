// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigami.delegates as KD

QQC2.ItemDelegate {
    id: item

    Layout.fillWidth: true
    activeFocusOnTab: true

    Keys.onEnterPressed: trigger()
    Keys.onReturnPressed: trigger()
    Accessible.onPressAction: trigger()

    function trigger(): void {
        if (enabled && action) {
            action.trigger()
        }
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        KD.IconTitleSubtitle {
            Layout.fillWidth: true
            icon: icon.fromControlsIcon(item.icon)
            title: item.text
            selected: item.highlighted || item.pressed
            font: item.font
        }
    }
}
