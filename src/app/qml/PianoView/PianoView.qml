// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

Flickable {
    id: flickable

    implicitHeight: Math.round(3.4 * 16) + octaveLabelHeight + keyboardBottomMargin
    contentWidth: piano.width + sidePadding * 2
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    readonly property int octaveLabelHeight: 18
    readonly property int keyboardBottomMargin: 5
    property int keyHeight: Math.max(1, height - octaveLabelHeight - keyboardBottomMargin)
    property int keyWidth: Math.max(1, Math.round(keyHeight / 3.4))
    readonly property int markerHeight: 2
    readonly property int octaveLabelTextHeight: Math.max(1, octaveLabelHeight - markerHeight)
    readonly property bool canScrollHorizontally: piano.width > width
    readonly property real sidePadding: canScrollHorizontally ? width / 2 : 0

    onWidthChanged: Qt.callLater(scrollToMarkedKeys)
    onContentWidthChanged: Qt.callLater(scrollToMarkedKeys)

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
        Qt.callLater(scrollToMarkedKeys)
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
    function scrollToMarkedKeys(): void {
        var left = Number.POSITIVE_INFINITY
        var right = Number.NEGATIVE_INFINITY
        for (var pitch = 21; pitch <= 108; ++pitch) {
            const noteItem = itemForPitch(pitch)
            if (noteItem === undefined || noteItem === null || !noteItem.marked) {
                continue
            }

            const notePosition = noteItem.mapToItem(piano, 0, 0)
            left = Math.min(left, notePosition.x)
            right = Math.max(right, notePosition.x + noteItem.width)
        }

        if (left === Number.POSITIVE_INFINITY) {
            scrollToX(flickable.sidePadding, false)
            return
        }

        scrollToX(piano.x + (left + right) / 2 - flickable.width / 2, true)
    }
    function scrollToX(targetX: real, animated: bool): void {
        const clampedTargetX = Math.max(0, Math.min(targetX, Math.max(0, flickable.contentWidth - flickable.width)))
        if (!animated || Math.abs(flickable.contentX - clampedTargetX) < 1) {
            scrollAnimation.stop()
            flickable.contentX = clampedTargetX
            return
        }

        scrollAnimation.stop()
        scrollAnimation.from = flickable.contentX
        scrollAnimation.to = clampedTargetX
        scrollAnimation.start()
    }
    function highlightKey(pitch: int, color: color): void {
        itemForPitch(pitch).color = color
    }
    function itemForPitch(pitch: int): Item {
        const keyItem = keyboard.children[Core.pianoKeyboardController.keyboardChildIndex(pitch)]
        const octaveChildIndex = Core.pianoKeyboardController.octaveChildIndex(pitch)
        return octaveChildIndex >= 0 ? keyItem.children[octaveChildIndex] : keyItem
    }

    NumberAnimation {
        id: scrollAnimation

        target: flickable
        property: "contentX"
        duration: 180
        easing.type: Easing.InOutQuad
    }

    Rectangle {
        id: piano

        width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth); height: parent.height
        x: flickable.sidePadding
        radius: 5
        color: "#141414"

        Row {
            id: octaveNumber
            width: parent.width; height: flickable.octaveLabelHeight
            anchors {
                left: parent.left
                leftMargin: 2 * flickable.keyWidth
            }

            Repeater {
                model: 7

                Label {
                    required property int modelData

                    text: i18nc("technical term, do you have a musician friend?", "Octave %1", 1 + modelData)
                    width: 7 * flickable.keyWidth
                    color: "white"
                    height: flickable.octaveLabelTextHeight
                    anchors.top: parent.top
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Item {
            id: keyboard

            anchors { top: octaveNumber.bottom; horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: flickable.keyboardBottomMargin }
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
                width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth); height: flickable.markerHeight
                anchors { left: whiteKeyA.left; bottom: whiteKeyA.top }
                color: "#A40E09"
            }
        }
    }
    ScrollIndicator.horizontal: ScrollIndicator {
        id: pianoScrollIndicator

        active: flickable.canScrollHorizontally
        visible: flickable.canScrollHorizontally

        contentItem: Rectangle {
            implicitWidth: 2
            implicitHeight: 2
            color: pianoScrollIndicator.palette.mid
            opacity: 0.75
            visible: pianoScrollIndicator.visible && pianoScrollIndicator.size < 1.0
        }
    }
}
