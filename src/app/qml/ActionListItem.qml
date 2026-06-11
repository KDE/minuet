// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ItemDelegate {
    id: item

    readonly property bool active: highlighted || checked || down || pressed
    readonly property color effectiveIconColor: {
        if (iconIsSymbolic) {
            return foregroundColor;
        }

        if (action && action.icon.color.a > 0) {
            return action.icon.color;
        }

        return "transparent";
    }
    readonly property color foregroundColor: active ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
    readonly property bool iconIsSymbolic: isSymbolicIcon(icon.name, icon.source)

    function isSymbolicIcon(name, source) {
        const iconName = name ? name.toString() : "";
        const iconSource = source ? source.toString() : "";

        return iconName.endsWith("-symbolic") || iconName.endsWith("-symbolic.svg") || iconName.includes("-symbolic.") || iconSource.endsWith("-symbolic.svg") || iconSource.includes("-symbolic.");
    }

    Layout.fillWidth: true
    activeFocusOnTab: true
    highlighted: checked
    icon.color: effectiveIconColor
    palette.alternateBase: Kirigami.Theme.backgroundColor
    palette.base: Kirigami.Theme.backgroundColor
    palette.button: Kirigami.Theme.backgroundColor
    palette.buttonText: Kirigami.Theme.textColor
    palette.dark: Kirigami.Theme.backgroundColor
    palette.highlight: Kirigami.Theme.highlightColor
    palette.highlightedText: Kirigami.Theme.highlightedTextColor
    palette.light: Kirigami.Theme.backgroundColor
    palette.mid: Kirigami.Theme.backgroundColor
    palette.midlight: Kirigami.Theme.backgroundColor
    palette.shadow: Kirigami.Theme.backgroundColor
    palette.text: Kirigami.Theme.textColor

    /*
     * Do not override background or contentItem here. Let the current QQC2
     * style draw the delegate so hover, press, checked and highlighted states
     * keep the same behavior, shape and animation as regular action delegates.
     *
     * Only align the palette roles used by styles with Kirigami.Theme, notably
     * for styles that use lower-level palette roles for delegate backgrounds.
     */
    palette.window: Kirigami.Theme.backgroundColor
    palette.windowText: Kirigami.Theme.textColor
}
