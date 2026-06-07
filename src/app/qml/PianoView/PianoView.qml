// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

Flickable {
    id: flickable

    readonly property bool canScrollHorizontally: piano.width > width
    property int keyHeight: Math.max(1, height - octaveLabelHeight - keyboardBottomMargin)
    property int keyWidth: Math.max(1, Math.round(keyHeight / 3.4))
    readonly property int keyboardBottomMargin: 5
    readonly property int markerHeight: 2
    readonly property int octaveLabelHeight: 18
    readonly property int octaveLabelTextHeight: Math.max(1, octaveLabelHeight - markerHeight)
    readonly property real sidePadding: canScrollHorizontally ? width / 2 : 0

    function clearAllMarks(): void {
        for (var index = 21; index <= 108; ++index) {
            noteOff(0, index, 0);
            clearMarksFromKey(itemForPitch(index));
        }
    }
    function clearMarksFromKey(noteItem: Item): void {
        if (noteItem === undefined || noteItem === null) {
            return;
        }

        noteItem.marked = false;
    }
    function highlightKey(pitch: int, color: color): void {
        itemForPitch(pitch).color = color;
    }
    function itemForPitch(pitch: int): Item {
        const keyItem = keyboard.children[Core.pianoKeyboardController.keyboardChildIndex(pitch)];
        const octaveChildIndex = Core.pianoKeyboardController.octaveChildIndex(pitch);
        return octaveChildIndex >= 0 ? keyItem.children[octaveChildIndex] : keyItem;
    }
    function noteMark(chan: int, pitch: int, vel: int, color: color): void {
        const noteItem = itemForPitch(pitch);
        if (noteItem === undefined || noteItem === null) {
            return;
        }
        clearMarksFromKey(noteItem);
        noteItem.markColor = color;
        noteItem.marked = true;
        Qt.callLater(scrollToMarkedKeys);
    }
    function noteOff(chan: int, pitch: int, vel: int): void {
        highlightKey(pitch, Core.pianoKeyboardController.isBlackKey(pitch) ? "black" : "white");
    }
    function scrollToMarkedKeys(): void {
        var left = Number.POSITIVE_INFINITY;
        var right = Number.NEGATIVE_INFINITY;
        for (var pitch = 21; pitch <= 108; ++pitch) {
            const noteItem = itemForPitch(pitch);
            if (noteItem === undefined || noteItem === null || !noteItem.marked) {
                continue;
            }

            const notePosition = noteItem.mapToItem(piano, 0, 0);
            left = Math.min(left, notePosition.x);
            right = Math.max(right, notePosition.x + noteItem.width);
        }

        if (left === Number.POSITIVE_INFINITY) {
            scrollToX(flickable.sidePadding, false);
            return;
        }

        scrollToX(piano.x + (left + right) / 2 - flickable.width / 2, true);
    }
    function scrollToX(targetX: real, animated: bool): void {
        const clampedTargetX = Math.max(0, Math.min(targetX, Math.max(0, flickable.contentWidth - flickable.width)));
        if (!animated || Math.abs(flickable.contentX - clampedTargetX) < 1) {
            scrollAnimation.stop();
            flickable.contentX = clampedTargetX;
            return;
        }

        scrollAnimation.stop();
        scrollAnimation.from = flickable.contentX;
        scrollAnimation.to = clampedTargetX;
        scrollAnimation.start();
    }

    boundsBehavior: Flickable.StopAtBounds
    clip: true
    contentWidth: piano.width + sidePadding * 2
    implicitHeight: Math.round(3.4 * 16) + octaveLabelHeight + keyboardBottomMargin

    ScrollIndicator.horizontal: ScrollIndicator {
        id: pianoScrollIndicator

        active: flickable.canScrollHorizontally
        visible: flickable.canScrollHorizontally

        contentItem: Rectangle {
            color: pianoScrollIndicator.palette.mid
            implicitHeight: 2
            implicitWidth: 2
            opacity: 0.75
            visible: pianoScrollIndicator.visible && pianoScrollIndicator.size < 1.0
        }
    }

    onContentWidthChanged: Qt.callLater(scrollToMarkedKeys)
    onWidthChanged: Qt.callLater(scrollToMarkedKeys)

    NumberAnimation {
        id: scrollAnimation

        duration: 180
        easing.type: Easing.InOutQuad
        property: "contentX"
        target: flickable
    }
    Rectangle {
        id: piano

        color: "#141414"
        height: parent.height
        radius: 5
        width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth)
        x: flickable.sidePadding

        Row {
            id: octaveNumber

            height: flickable.octaveLabelHeight
            width: parent.width

            anchors {
                left: parent.left
                leftMargin: 2 * flickable.keyWidth
            }
            Repeater {
                model: 7

                Label {
                    required property int modelData

                    anchors.top: parent.top
                    color: "white"
                    height: flickable.octaveLabelTextHeight
                    horizontalAlignment: Text.AlignHCenter
                    text: i18nc("technical term, do you have a musician friend?", "Octave %1", 1 + modelData)
                    verticalAlignment: Text.AlignVCenter
                    width: 7 * flickable.keyWidth
                }
            }
        }
        Item {
            id: keyboard

            height: flickable.keyHeight - octaveNumber.height
            width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth)

            anchors {
                bottom: parent.bottom
                bottomMargin: flickable.keyboardBottomMargin
                horizontalCenter: parent.horizontalCenter
                top: octaveNumber.bottom
            }
            WhiteKey {
                id: whiteKeyA

                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            BlackKey {
                anchor: whiteKeyA
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            WhiteKey {
                id: whiteKeyB

                anchor: whiteKeyA
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Octave {
                id: octave1

                initialAnchor: whiteKeyB
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Octave {
                id: octave2

                initialAnchor: octave1
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Octave {
                id: octave3

                initialAnchor: octave2
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Octave {
                id: octave4

                initialAnchor: octave3
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Octave {
                id: octave5

                initialAnchor: octave4
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Octave {
                id: octave6

                initialAnchor: octave5
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Octave {
                id: octave7

                initialAnchor: octave6
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            WhiteKey {
                id: whiteKeyC

                anchor: octave7
                keyHeight: flickable.keyHeight
                keyWidth: flickable.keyWidth
            }
            Rectangle {
                color: "#A40E09"
                height: flickable.markerHeight
                width: 3 * flickable.keyWidth + 7 * (7 * flickable.keyWidth)

                anchors {
                    bottom: whiteKeyA.top
                    left: whiteKeyA.left
                }
            }
        }
    }
}
