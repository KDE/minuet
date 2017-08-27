/****************************************************************************
**
** Copyright (C) 2017 by Stefan Toncu <stefan.toncu29@gmail.com>
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

Rectangle {
    property int index: -1
    height: 5 * string_size; width: height; radius: width * 0.5
    color: fretBoard.mark_color
    visible: is_end || is_nut ? false : fretBoard.press[index]
    border.width: 1; border.color: "black"
    anchors.centerIn: fretBoard.ids[index]
}
