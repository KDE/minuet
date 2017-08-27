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
    id: fretBoard
    height: (string_E1.height + string_E1.anchors.topMargin) * 6 + string_E1.anchors.topMargin
    color: "#4b3020"
    property var mark_color: "black"
    property double string_size: 3
    property string string_color: "#FFF2E6"
    property bool show_fret_marker: false
    property bool show_two_markers: false
    property bool is_nut: false
    property bool is_end: false
    property var press: [false, false, false, false, false, false]
    property var ids: [string_E1, string_B, string_G, string_D, string_A, string_E2]
    property var noteMarks: [noteMark0, noteMark1, noteMark2, noteMark3, noteMark4, noteMark5]
    property int startBar: -1
    property int endBar: -1

    Rectangle {
        id: fret_marker1
        height: 6.5 * string_size; width: height
        radius: width * 0.5
        visible: show_fret_marker
        opacity: 0.7
        anchors {
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset:  - string_size / 2
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: show_two_markers ? -(parent.height - (string_E1.y - parent.y)) / 4 : 0
        }
        color: "#E2E2E2"
        border.width: string_size / 2
        border.color: "#535353"
    }

    Rectangle {
        id: fret_marker2
        height: fret_marker1.height; width: height
        radius: width * 0.5
        visible: show_two_markers
        opacity: fret_marker1.opacity
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: show_two_markers ? (parent.height - (string_E1.y - parent.y)) / 4 : 0
        }
        color: "#E2E2E2"
        border.width: string_size / 2
        border.color: "#535353"
    }

    String { id: string_E1; anchors.top: parent.top }
    String { id: string_B;  anchors.top: string_E1.bottom }
    String { id: string_G;  anchors.top: string_B.bottom }
    String { id: string_D;  anchors.top: string_G.bottom }
    String { id: string_A;  anchors.top: string_D.bottom }
    String { id: string_E2; anchors.top: string_A.bottom }

    NoteMark { id: noteMark0; index: 0}
    NoteMark { id: noteMark1; index: 1}
    NoteMark { id: noteMark2; index: 2}
    NoteMark { id: noteMark3; index: 3}
    NoteMark { id: noteMark4; index: 4}
    NoteMark { id: noteMark5; index: 5}

    Rectangle {
        id: bar
        width: 5 * string_size
        radius: width * 0.5
        visible: is_nut==false && (endBar - startBar) > 0
        color: fretBoard.mark_color
        border.width: 1
        border.color: "black"
        anchors {   top: fretBoard.ids[startBar] ? fretBoard.ids[startBar].top : parent.top
                    bottom: fretBoard.ids[endBar] ? fretBoard.ids[endBar].bottom : parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    topMargin: - width / 2
                    bottomMargin: - width / 2 }
    }

    Rectangle {
        id: rightBar
        width: is_nut ? string_size * 4 : string_size; height: parent.height
        anchors {right: parent.right; top: parent.top; bottom: parent.bottom}
        visible: is_end ? false : true
        color: "#D9D9D9"
    }

}
