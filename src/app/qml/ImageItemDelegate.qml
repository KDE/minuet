/****************************************************************************
**
** Copyright (C) 2016 by Sandro S. Andrade <sandroandrade@kde.org>
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation; either version 2 of
** the License or (at your option) version 3 or any later version
** accepted by the membership of KDE e.V. (or its successor approved
** by the membership of KDE e.V.), which shall act as a proxy
** defined in Section 14 of version 3 of the license.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

import QtQuick 2.7
import QtQuick.Templates 2.0 as T

T.ItemDelegate {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             Math.max(contentItem.implicitHeight,
                                      indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 12
    spacing: 12

    //! [contentItem]
    contentItem: Row {
        spacing: 5
        Image {
            width: 22; height: 22
            source: (modelData._icon != undefined) ? modelData._icon:""
            visible: modelData._icon != undefined
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            leftPadding: control.mirrored ? (control.indicator ? control.indicator.width : 0) + control.spacing : 0
            rightPadding: !control.mirrored ? (control.indicator ? control.indicator.width : 0) + control.spacing : 0

            text: control.text
            font: control.font
            color: control.enabled ? "#26282a" : "#bdbebf"
            width: parent.width
            wrapMode: Text.WordWrap
            anchors.verticalCenter: parent.verticalCenter
            visible: control.text
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
    }
    //! [contentItem]

    //! [background]
    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 40
        visible: control.down || control.highlighted || control.visualFocus
        color: control.visualFocus ? (control.pressed ? "#cce0ff" : "#e5efff") : (control.down ? "#bdbebf" : "#eeeeee")
    }
    //! [background]
}
