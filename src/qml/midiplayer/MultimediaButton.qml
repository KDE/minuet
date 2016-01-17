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

import QtQuick 2.4

Item {
    id: item

    property alias source: buttonImage.source
    property alias text: buttonText.text

    signal activated

    width: playbackTime.contentWidth / 3; height: childrenRect.height

    Image {
        id: buttonImage

        width: 24; height: 24
        anchors.horizontalCenter: parent.horizontalCenter
        MouseArea { anchors.fill: parent; onClicked: item.activated() }
    }
    Text {
        id: buttonText

        width: parent.width
        anchors.top: buttonImage.bottom
        font.pointSize: 8
        horizontalAlignment: Text.AlignHCenter
        color: "white"
    }
}
