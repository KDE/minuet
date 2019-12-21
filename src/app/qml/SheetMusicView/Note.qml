/****************************************************************************
**
** Copyright (C) 2017 by Sandro S. Andrade <sandroandrade@kde.org>
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

BravuraText {
    id: note

    property int number;
    property int octave;
    property int midiKey;
    property int rhythm: 4;
    property int accident: 0 // [-2 double flat, -1 flat, 1 sharp, 2 double sharp]
    property bool spaced: true
    
    objectName: "symbol"

    onNumberChanged: {
        if (!internal.updating) {
            internal.updating = true;
            midiKey = 24 + (12*(octave-1))+number+accident;
            internal.updating = false
        }
    }
    onOctaveChanged: {
        if (!internal.updating) {
            internal.updating = true;
            midiKey = 24 + (12*(octave-1))+number+accident;
            internal.updating = false
        }
    }
    onAccidentChanged: {
        if (!internal.updating) {
            internal.updating = true;
            midiKey = 24 + (12*(octave-1))+number+accident;
            internal.updating = false
        }
    }
    onMidiKeyChanged: {
        if (!internal.updating) {
            internal.updating = true;
            number = (midiKey % 12);
            octave = (((midiKey-24) - number) / 12) + 1;
            accident = internal.accidentMap[number][1];
            internal.updating = false
        }
    }

    QtObject {
        id: internal

        property bool updating: false;
        property var accidentMap: [
            // [vertical offset, accident]
            [0, 0],
            [0, 1],
            [1, 0],
            [1, 1],
            [2, 0],
            [3, 0],
            [3, 1],
            [4, 0],
            [4, 1],
            [5, 0],
            [5, 1],
            [6, 0],
        ]

        function itemIndex(item) {
            if (item.parent == null)
                return -1
            var siblings = item.parent.children
            for (var i = siblings.length - 1; i >=0 ; i--)
                if (siblings[i] == item)
                    return i
            return -1 // will never happen
        }
        function previousItem(item) {
            if (item.parent == null)
                return null
            var siblings = item.parent.children
            for (var i = itemIndex(item) - 1; i >=0 ; i--)
                if (siblings[i].objectName == "symbol")
                    return item.parent.children[i]
            return null
        }

        property var rhythmTable: { "1": "\ue1d2", "2": "\ue1d3", "4": "\ue1d5", "8": "\ue1d7", "16": "\ue1d9", "32": "\ue1db", "64": "\ue1dd" }
    }

    anchors {
        bottom: parent.children[0].bottom;
        bottomMargin: {
            (parent.clef.type == 0) ?
                ((internal.accidentMap[number][0])*5)+(octave-4)*35
                :
                -10+((internal.accidentMap[number][0])*5)+(octave-2)*35;
        }
        left: spaced ? internal.previousItem(note).right:internal.previousItem(note).left;
        leftMargin: spaced ? parent.spacing:0
    }
    text: ((accident == -1) ? "\ue260":(accident == 1) ? "\ue262":(accident == -2) ? "\ue264":(accident == 2) ? "\ue263":" ") + internal.rhythmTable[rhythm]
    font.pixelSize: 35
}
