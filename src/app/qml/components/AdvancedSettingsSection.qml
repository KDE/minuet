// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormTextDelegate {
    id: root

    Layout.fillWidth: true
    bottomPadding: Kirigami.Units.smallSpacing
    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.smallSpacing

    descriptionItem {
        horizontalAlignment: Text.AlignLeft
    }
    textItem {
        horizontalAlignment: Text.AlignLeft
    }
}
