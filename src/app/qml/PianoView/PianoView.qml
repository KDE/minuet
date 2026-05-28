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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

Flickable {
    id: flickable

    implicitHeight: keyHeight + 30
    contentWidth: piano.width
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    property int keyWidth: Math.max(16, (width - 80) / 52)
    property int keyHeight: 3.4 * keyWidth

    function noteOn(chan: int, pitch: int, vel: int): void {
        if (vel > 0)
            highlightKey(pitch, "#778692")
        else
            noteOff(chan, pitch, vel)
    }
    function noteOff(chan: int, pitch: int, vel: int): void {
        highlightKey(pitch, Core.pianoKeyboardController.isBlackKey(pitch) ? "black" : "white")
    }
    function noteMark(chan: int, pitch: int, vel: int, color: color): void {
        const noteItem = itemForPitch(pitch)
        if (noteItem === undefined || noteItem === null) {
            return
        }
        clearMarksFromKey(noteItem)
        noteItem.markColor = color
        noteItem.marked = true
    }
    function noteUnmark(chan: int, pitch: int, vel: int, color: color): void {
        clearMarksFromKey(itemForPitch(pitch))
    }
    function clearAllMarks(): void {
        for (var index = 21; index <= 108; ++index) {
            noteOff(0, index, 0)
            clearMarksFromKey(itemForPitch(index))
        }
    }
    function clearMarksFromKey(noteItem: Item): void {
        if (noteItem === undefined || noteItem === null) {
            return
        }

        noteItem.marked = false
    }
    function scrollToNote(pitch: int): void {
        flickable.contentX = Core.pianoKeyboardController.scrollTargetX(pitch, flickable.contentWidth, flickable.width)
    }
    function highlightKey(pitch: int, color: color): void {
        itemForPitch(pitch).color = color
    }
    function itemForPitch(pitch: int): Item {
        const keyItem = keyboard.children[Core.pianoKeyboardController.keyboardChildIndex(pitch)]
        const octaveChildIndex = Core.pianoKeyboardController.octaveChildIndex(pitch)
        return octaveChildIndex >= 0 ? keyItem.children[octaveChildIndex] : keyItem
    }

    Rectangle {
        id: piano

        width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth); height: parent.height
        x: 0
        radius: 5
        color: "#141414"

        Row {
            id: octaveNumber
            width: parent.width; height: 18
            anchors.left: parent.left
            anchors.leftMargin: 2 * flickable.keyWidth

            Repeater {
                model: 7

                Label {
                    required property int modelData

                    text: i18nc("technical term, do you have a musician friend?", "Octave %1", 1 + modelData)
                    width: 7 * flickable.keyWidth
                    color: "white"
                    height: parent.height
                }
            }
        }

        Item {
            id: keyboard

            anchors { top: octaveNumber.bottom; horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 5 }
            width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth); height: flickable.keyHeight - octaveNumber.height

            WhiteKey { id: whiteKeyA; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            BlackKey { anchor: whiteKeyA; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            WhiteKey { id: whiteKeyB; anchor: whiteKeyA; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Octave { id: octave1; initialAnchor: whiteKeyB; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Octave { id: octave2; initialAnchor: octave1; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Octave { id: octave3; initialAnchor: octave2; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Octave { id: octave4; initialAnchor: octave3; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Octave { id: octave5; initialAnchor: octave4; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Octave { id: octave6; initialAnchor: octave5; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Octave { id: octave7; initialAnchor: octave6; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            WhiteKey { id: whiteKeyC; anchor: octave7; keyWidth: flickable.keyWidth; keyHeight: flickable.keyHeight }
            Rectangle {
                width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth); height: 2
                anchors { left: whiteKeyA.left; bottom: whiteKeyA.top }
                color: "#A40E09"
            }
        }
    }
    ScrollIndicator.horizontal: ScrollIndicator { active: true }
}
