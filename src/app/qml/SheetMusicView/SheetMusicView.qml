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

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var model: []
    property bool spaced: true
    readonly property int staffStep: Math.max(4, Math.min(7, Math.round(height / 24)))
    readonly property real staffLineWidth: Math.max(1, Math.round(staffStep / 6))
    readonly property real staffPixelOffset: staffLineWidth % 2 === 1 ? 0.5 : 0
    readonly property real middleCY: Math.round(height / 2)
    readonly property real ledgerLineWidth: staffStep * 5
    readonly property real clefWidth: staffStep * 9
    readonly property real noteSpacing: Kirigami.Units.gridUnit * (spaced ? 2.1 : 0.7)
    readonly property real noteStartX: Math.round(clefWidth + Kirigami.Units.largeSpacing)
    readonly property real accidentalCenterOffset: -staffStep * 2.6
    readonly property real accidentalColumnSpacing: staffStep * 1.8
    readonly property real noteheadCollisionOffset: staffStep * 1.35
    readonly property color staffColor: Kirigami.Theme.textColor
    property alias activeClef: trebleClef

    implicitHeight: Kirigami.Units.gridUnit * 9
    clip: true

    function clearAllMarks(): void {
        model = []
    }

    function noteNumber(pitch: int): int {
        return pitch % 12
    }

    function noteOctave(pitch: int): int {
        const number = noteNumber(pitch)
        return (((pitch - 24) - number) / 12) + 1
    }

    function diatonicOffset(number: int): int {
        return [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6][number]
    }

    function accident(number: int): int {
        return [0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0][number]
    }

    function diatonicIndex(pitch: int): int {
        return noteOctave(pitch) * 7 + diatonicOffset(noteNumber(pitch))
    }

    function yForDiatonicIndex(index: int): real {
        return Math.round(middleCY - (index - 28) * staffStep) + staffPixelOffset
    }

    function noteX(position: int): real {
        return Math.round(noteStartX + position * noteSpacing)
    }

    function accidentalPrefix(pitch: int): string {
        return accidentalSymbol(accident(noteNumber(pitch)))
    }

    function accidentalSymbol(accidentValue: int): string {
        if (accidentValue === -2) {
            return "\ue264"
        }
        if (accidentValue === -1) {
            return "\ue260"
        }
        if (accidentValue === 1) {
            return "\ue262"
        }
        if (accidentValue === 2) {
            return "\ue263"
        }
        return ""
    }

    function ledgerLinesForPitch(pitch: int): var {
        const index = diatonicIndex(pitch)
        const treble = pitch >= 60
        var lines = []
        var lineIndex
        if (treble ? index > 38 : index > 26) {
            for (lineIndex = treble ? 40 : 28; lineIndex <= index; lineIndex += 2) {
                lines.push(lineIndex)
            }
        } else if (treble ? index < 30 : index < 18) {
            for (lineIndex = treble ? 28 : 16; lineIndex >= index; lineIndex -= 2) {
                lines.push(lineIndex)
            }
        }
        return lines
    }

    function displayNotes(): var {
        var notes = []
        for (var i = 0; i < model.length; ++i) {
            notes.push({
                "pitch": model[i],
                "position": spaced ? i : 0,
                "noteIndex": diatonicIndex(model[i]),
                "noteheadOffset": 0,
                "accidentalColumn": 0
            })
        }

        for (var position = 0; position < notes.length; ++position) {
            var group = []
            for (var groupIndex = 0; groupIndex < notes.length; ++groupIndex) {
                if (notes[groupIndex].position === position) {
                    group.push(notes[groupIndex])
                }
            }
            if (group.length === 0) {
                continue
            }

            group.sort(function(first: var, second: var): int {
                return first.noteIndex - second.noteIndex
            })

            for (var noteIndex = 1; noteIndex < group.length; ++noteIndex) {
                const previousNote = group[noteIndex - 1]
                const currentNote = group[noteIndex]
                if (currentNote.noteIndex - previousNote.noteIndex === 1) {
                    currentNote.noteheadOffset = previousNote.noteheadOffset === 0 ? noteheadCollisionOffset : 0
                }
            }

            var accidentalColumns = []
            for (var accidentalIndex = 0; accidentalIndex < group.length; ++accidentalIndex) {
                const accidentalNote = group[accidentalIndex]
                if (root.accident(accidentalNote.pitch % 12) === 0) {
                    continue
                }
                var column = 0
                while (column < accidentalColumns.length && Math.abs(accidentalNote.noteIndex - accidentalColumns[column]) < 4) {
                    ++column
                }
                accidentalNote.accidentalColumn = column
                accidentalColumns[column] = accidentalNote.noteIndex
            }
        }
        return notes
    }

    Repeater {
        model: [38, 36, 34, 32, 30, 26, 24, 22, 20, 18]

        Rectangle {
            required property int modelData

            x: 0
            y: root.yForDiatonicIndex(modelData) - height / 2
            width: root.width
            height: root.staffLineWidth
            color: root.staffColor
        }
    }

    BravuraText {
        id: trebleClef

        property int clefType: 0

        x: 0
        y: root.yForDiatonicIndex(32) - height / 2
        text: "\ue050"
        font.pixelSize: root.staffStep * 8
    }

    BravuraText {
        x: 0
        y: root.yForDiatonicIndex(24) - height / 2
        text: "\ue062"
        font.pixelSize: root.staffStep * 8
    }

    Repeater {
        model: root.displayNotes()

        Item {
            id: noteItem

            required property var modelData
            readonly property int pitch: modelData.pitch
            readonly property int noteIndex: modelData.noteIndex
            readonly property real noteheadOffset: modelData.noteheadOffset

            x: root.noteX(modelData.position)
            y: 0
            width: root.ledgerLineWidth + Math.abs(noteheadOffset)
            height: root.height

            Repeater {
                model: root.ledgerLinesForPitch(noteItem.pitch)

                Rectangle {
                    required property int modelData

                    x: Math.min(0, noteItem.noteheadOffset)
                    y: root.yForDiatonicIndex(modelData) - noteItem.y - height / 2
                    width: noteItem.width
                    height: root.staffLineWidth
                    color: root.staffColor
                }
            }

            BravuraText {
                readonly property string symbol: root.accidentalPrefix(noteItem.pitch)

                x: root.ledgerLineWidth / 2 + root.accidentalCenterOffset - modelData.accidentalColumn * root.accidentalColumnSpacing - width / 2
                y: root.yForDiatonicIndex(noteItem.noteIndex) - noteItem.y - height / 2
                visible: symbol.length > 0
                text: symbol
                font.pixelSize: root.staffStep * 5
            }

            BravuraText {
                x: root.ledgerLineWidth / 2 + noteItem.noteheadOffset - width / 2
                y: root.yForDiatonicIndex(noteItem.noteIndex) - noteItem.y - height / 2
                text: "\ue1d5"
                font.pixelSize: root.staffStep * 6
            }
        }
    }
}
