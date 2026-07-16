// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

Flickable {
    id: flickable

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
        scheduleScrollToMarkedKeys();
    }
    function noteOff(chan: int, pitch: int, vel: int): void {
        highlightKey(pitch, Core.pianoKeyboardController.isBlackKey(pitch) ? "black" : "white");
    }
    function scheduleScrollToMarkedKeys(): void {
        if (!internal.destroying) {
            scrollUpdateTimer.restart();
        }
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
            scrollToX(internal.sidePadding, false);
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
    contentWidth: piano.width + internal.sidePadding * 2
    implicitHeight: Math.round(3.4 * 16) + internal.octaveLabelHeight + internal.keyboardBottomMargin

    ScrollIndicator.horizontal: ScrollIndicator {
        id: pianoScrollIndicator

        active: internal.canScrollHorizontally
        visible: internal.canScrollHorizontally

        contentItem: Rectangle {
            color: pianoScrollIndicator.palette.mid
            implicitHeight: 2
            implicitWidth: 2
            opacity: 0.75
            visible: pianoScrollIndicator.visible && pianoScrollIndicator.size < 1.0
        }
    }

    Component.onDestruction: {
        internal.destroying = true;
        scrollUpdateTimer.stop();
    }
    onContentWidthChanged: scheduleScrollToMarkedKeys()
    onWidthChanged: scheduleScrollToMarkedKeys()

    QtObject {
        id: internal

        readonly property bool canScrollHorizontally: piano.width > flickable.width
        property bool destroying: false
        readonly property int keyHeight: Math.max(1, flickable.height - internal.octaveLabelHeight - internal.keyboardBottomMargin)
        readonly property int keyWidth: Math.max(1, Math.round(internal.keyHeight / 3.4))
        readonly property int keyboardBottomMargin: 5
        readonly property int markerHeight: 2
        readonly property int octaveLabelHeight: 18
        readonly property real sidePadding: internal.canScrollHorizontally ? flickable.width / 2 : 0
    }
    Timer {
        id: scrollUpdateTimer

        onTriggered: flickable.scrollToMarkedKeys()
    }
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
        width: 3 * internal.keyWidth + 7 * (7 * internal.keyWidth)
        x: internal.sidePadding

        Row {
            id: octaveNumber

            height: internal.octaveLabelHeight
            width: parent.width

            anchors {
                left: parent.left
                leftMargin: 2 * internal.keyWidth
            }
            Repeater {
                model: 7

                Label {
                    required property int modelData

                    anchors.top: parent.top
                    color: "white"
                    height: Math.max(1, internal.octaveLabelHeight - internal.markerHeight)
                    horizontalAlignment: Text.AlignHCenter
                    text: i18nc("technical term, do you have a musician friend?", "Octave %1", 1 + modelData)
                    verticalAlignment: Text.AlignVCenter
                    width: 7 * internal.keyWidth
                }
            }
        }
        Item {
            id: keyboard

            height: internal.keyHeight - octaveNumber.height
            width: 3 * internal.keyWidth + 7 * (7 * internal.keyWidth)

            anchors {
                bottom: parent.bottom
                bottomMargin: internal.keyboardBottomMargin
                horizontalCenter: parent.horizontalCenter
                top: octaveNumber.bottom
            }
            WhiteKey {
                id: whiteKeyA

                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            BlackKey {
                anchor: whiteKeyA
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            WhiteKey {
                id: whiteKeyB

                anchor: whiteKeyA
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Octave {
                id: octave1

                initialAnchor: whiteKeyB
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Octave {
                id: octave2

                initialAnchor: octave1
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Octave {
                id: octave3

                initialAnchor: octave2
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Octave {
                id: octave4

                initialAnchor: octave3
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Octave {
                id: octave5

                initialAnchor: octave4
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Octave {
                id: octave6

                initialAnchor: octave5
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Octave {
                id: octave7

                initialAnchor: octave6
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            WhiteKey {
                id: whiteKeyC

                anchor: octave7
                keyHeight: internal.keyHeight
                keyWidth: internal.keyWidth
            }
            Rectangle {
                color: "#A40E09"
                height: internal.markerHeight
                width: 3 * internal.keyWidth + 7 * (7 * internal.keyWidth)

                anchors {
                    bottom: whiteKeyA.top
                    left: whiteKeyA.left
                }
            }
        }
    }
}
