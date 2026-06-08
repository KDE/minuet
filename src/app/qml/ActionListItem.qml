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

    readonly property bool useIOSDarkDrawerStyle: Qt.platform.os === "ios" && Qt.styleHints.colorScheme === Qt.Dark

    function trigger(): void {
        if (enabled && action) {
            action.trigger();
        }
    }

    Layout.fillWidth: true
    activeFocusOnTab: true
    icon.color: useIOSDarkDrawerStyle ? Kirigami.Theme.textColor : Qt.rgba(0, 0, 0, 0)
    palette.light: Kirigami.Theme.backgroundColor

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Primitives.Icon {
            readonly property int size: Kirigami.Units.iconSizes.smallMedium

            Layout.maximumHeight: size
            Layout.maximumWidth: size
            Layout.minimumHeight: size
            Layout.minimumWidth: size
            color: item.icon.color
            isMask: item.useIOSDarkDrawerStyle
            selected: item.useIOSDarkDrawerStyle || item.highlighted || item.pressed
            source: item.icon.name || item.icon.source
            visible: source !== undefined && source.toString().length > 0
        }
        KD.TitleSubtitle {
            Layout.fillWidth: true
            font: item.font
            selected: item.useIOSDarkDrawerStyle || item.highlighted || item.pressed
            title: item.text
        }
    }

    Accessible.onPressAction: trigger()
    Keys.onEnterPressed: trigger()
    Keys.onReturnPressed: trigger()

    Binding {
        property: "color"
        restoreMode: Binding.RestoreBindingOrValue
        target: item.background
        value: Kirigami.Theme.backgroundColor
        when: item.useIOSDarkDrawerStyle && item.background
    }
    Binding {
        property: "visible"
        restoreMode: Binding.RestoreBindingOrValue
        target: item.background && item.background.children.length > 0 ? item.background.children[0] : null
        value: false
        when: item.useIOSDarkDrawerStyle && item.background && item.background.children.length > 0
    }
}
