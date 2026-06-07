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

    function trigger(): void {
        if (enabled && action) {
            action.trigger();
        }
    }

    Layout.fillWidth: true
    activeFocusOnTab: true

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        KD.IconTitleSubtitle {
            Layout.fillWidth: true
            font: item.font
            icon: icon.fromControlsIcon(item.icon)
            selected: item.highlighted || item.pressed
            title: item.text
        }
    }

    Accessible.onPressAction: trigger()
    Keys.onEnterPressed: trigger()
    Keys.onReturnPressed: trigger()
}
