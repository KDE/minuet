// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

Text {
    id: root

    FontLoader {
        id: bravura

        source: "Bravura.otf"
    }

    font {
        family: bravura.name
        pixelSize: 40
    }
    lineHeightMode: Text.FixedHeight
    lineHeight: font.pixelSize
    color: Kirigami.Theme.textColor
}
