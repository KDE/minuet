// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigami.delegates as KD
import org.kde.kirigami.primitives as Primitives

QQC2.ItemDelegate {
    id: item

    readonly property bool active: highlighted || checked || down || pressed
    readonly property color backgroundColor: active ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
    readonly property color foregroundColor: active ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
    readonly property bool hasIcon: icon.name.length > 0 || icon.source.toString().length > 0
    readonly property bool iconIsSymbolic: {
        const iconName = icon.name;
        const iconSource = icon.source.toString();

        return iconName.endsWith("-symbolic") || iconSource.endsWith("-symbolic.svg") || iconSource.includes("-symbolic.");
    }

    function trigger(): void {
        if (enabled && action) {
            action.trigger();
        }
    }

    Layout.fillWidth: true
    activeFocusOnTab: true
    palette.base: Kirigami.Theme.backgroundColor
    palette.button: Kirigami.Theme.backgroundColor
    palette.light: Kirigami.Theme.backgroundColor
    palette.midlight: Kirigami.Theme.backgroundColor
    palette.window: Kirigami.Theme.backgroundColor

    background: Rectangle {
        color: item.backgroundColor
    }
    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Primitives.Icon {
            readonly property int size: Kirigami.Units.iconSizes.smallMedium

            Layout.maximumHeight: size
            Layout.maximumWidth: size
            Layout.minimumHeight: size
            Layout.minimumWidth: size
            color: item.iconIsSymbolic ? item.foregroundColor : item.icon.color
            isMask: item.iconIsSymbolic
            selected: item.active
            source: item.icon.name || item.icon.source
            visible: item.hasIcon
        }
        KD.TitleSubtitle {
            Layout.fillWidth: true
            font: item.font
            selected: item.active
            title: item.text
        }
    }

    Accessible.onPressAction: trigger()
    Keys.onEnterPressed: trigger()
    Keys.onReturnPressed: trigger()
}
