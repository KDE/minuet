// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

Text {
    id: root

    color: Kirigami.Theme.textColor
    lineHeight: font.pixelSize
    lineHeightMode: Text.FixedHeight

    FontLoader {
        id: bravura

        source: "Bravura.otf"
    }
    font {
        family: bravura.name
        pixelSize: 40
        pointSize: -1
    }
}
