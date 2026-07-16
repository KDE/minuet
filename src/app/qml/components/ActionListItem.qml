// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ItemDelegate {
    id: item

    Layout.fillWidth: true
    activeFocusOnTab: true
    highlighted: checked
    icon.color: {
        if (item.action && internal.isSymbolicIcon(item.action.icon.name, item.action.icon.source)) {
            return item.highlighted || item.checked || item.down || item.pressed ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor;
        }
        return "transparent";
    }

    QtObject {
        id: internal

        function isSymbolicIcon(name, source): bool {
            const iconName = name ? name.toString() : "";
            const iconSource = source ? source.toString() : "";
            return iconName.endsWith("-symbolic") || iconName.endsWith("-symbolic.svg") || iconName.includes("-symbolic.") || iconSource.endsWith("-symbolic.svg") || iconSource.includes("-symbolic.");
        }
    }
    palette {
        alternateBase: Kirigami.Theme.backgroundColor
        base: Kirigami.Theme.backgroundColor
        button: Kirigami.Theme.backgroundColor
        buttonText: Kirigami.Theme.textColor
        dark: Kirigami.Theme.backgroundColor
        highlight: Kirigami.Theme.highlightColor
        highlightedText: Kirigami.Theme.highlightedTextColor
        light: Kirigami.Theme.backgroundColor
        mid: Kirigami.Theme.backgroundColor
        midlight: Kirigami.Theme.backgroundColor
        shadow: Kirigami.Theme.backgroundColor
        text: Kirigami.Theme.textColor
        window: Kirigami.Theme.backgroundColor
        windowText: Kirigami.Theme.textColor
    }

    /*
     * Do not override background or contentItem here. Let the current QQC2
     * style draw the delegate so hover, press, checked and highlighted states
     * keep the same behavior, shape and animation as regular action delegates.
     *
     * Only align the palette roles used by styles with Kirigami.Theme, notably
     * for styles that use lower-level palette roles for delegate backgrounds.
     */
}
