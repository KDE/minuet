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
    readonly property real staffLineWidth: Math.max(1, Math.round(metadata.engravingDefault("staffLineThickness") * staffStep))
    readonly property real ledgerLineThickness: Math.max(1, Math.round(metadata.engravingDefault("legerLineThickness") * staffStep))
    readonly property real staffPixelOffset: staffLineWidth % 2 === 1 ? 0.5 : 0
    readonly property real middleCY: Math.round(height / 2)
    readonly property real ledgerLineExtension: metadata.engravingDefault("legerLineExtension") * staffStep
    readonly property real noteheadBBoxWidth: (metadata.glyphBBoxValue("noteheadBlack", "bBoxNE", 0) - metadata.glyphBBoxValue("noteheadBlack", "bBoxSW", 0)) * staffStep * noteheadScale
    readonly property real ledgerLineWidth: noteheadBBoxWidth + ledgerLineExtension * 2
    readonly property real systemTopY: yForDiatonicIndex(38)
    readonly property real systemBottomY: yForDiatonicIndex(18)
    readonly property real systemHeight: systemBottomY - systemTopY
    readonly property real braceBBoxHeight: metadata.glyphBBoxValue("brace", "bBoxNE", 1) - metadata.glyphBBoxValue("brace", "bBoxSW", 1)
    readonly property real braceBBoxBottom: metadata.glyphBBoxValue("brace", "bBoxSW", 1)
    readonly property real braceFontPixelSize: braceBBoxHeight > 0 ? systemHeight * 4 / braceBBoxHeight : staffStep * 20
    readonly property real systemStartX: Math.round(staffStep * 3.2)
    readonly property real clefStartX: Math.round(systemStartX + staffStep * 1.4)
    readonly property real clefScale: 2
    readonly property real clefWidth: Math.max(
        metadata.glyphBBoxValue("gClef", "bBoxNE", 0) - metadata.glyphBBoxValue("gClef", "bBoxSW", 0),
        metadata.glyphBBoxValue("fClef", "bBoxNE", 0) - metadata.glyphBBoxValue("fClef", "bBoxSW", 0)
    ) * staffStep * clefScale
    readonly property real noteSpacing: Kirigami.Units.gridUnit * (spaced ? 2.1 : 0.7)
    readonly property real noteStartX: Math.round(clefStartX + clefWidth + accidentalReserveWidth + Kirigami.Units.largeSpacing)
    readonly property real accidentalNoteheadGap: (metadata.engravingDefault("legerLineExtension") + metadata.engravingDefault("legerLineThickness") + metadata.engravingDefault("stemThickness")) * staffStep
    readonly property real accidentalColumnSpacing: accidentalMaxWidth + ledgerLineExtension
    readonly property int accidentalColumnCount: 3
    readonly property real noteheadFontPixelSize: staffStep * 6
    readonly property real noteheadScale: noteheadFontPixelSize / (staffStep * 4)
    readonly property real normalNoteheadX: ledgerLineWidth / 2
    readonly property real noteheadStemUpSEX: metadata.anchor("noteheadBlack", "stemUpSE")[0] * staffStep * noteheadScale
    readonly property real noteheadStemUpSEY: metadata.anchor("noteheadBlack", "stemUpSE")[1] * staffStep * noteheadScale
    readonly property real stemThickness: Math.max(1, Math.round(metadata.engravingDefault("stemThickness") * staffStep))
    readonly property real stemExtension: metadata.glyphBBoxValue("metNoteQuarterUp", "bBoxNE", 1) * staffStep
    readonly property real accidentalMaxWidth: Math.max(
        metadata.glyphBBoxValue("accidentalSharp", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalSharp", "bBoxSW", 0),
        metadata.glyphBBoxValue("accidentalFlat", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalFlat", "bBoxSW", 0),
        metadata.glyphBBoxValue("accidentalDoubleFlat", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalDoubleFlat", "bBoxSW", 0),
        metadata.glyphBBoxValue("accidentalDoubleSharp", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalDoubleSharp", "bBoxSW", 0)
    ) * staffStep
    readonly property real accidentalReserveWidth: accidentalNoteheadGap + (accidentalColumnCount - 1) * accidentalColumnSpacing + accidentalMaxWidth + Kirigami.Units.smallSpacing
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

    SmuflMetadata {
        id: metadata
    }

    function displayNotes(): var {
        if (!metadata.ready) {
            return []
        }

        var notes = []
        for (var i = 0; i < model.length; ++i) {
            notes.push({
                "pitch": model[i],
                "position": spaced ? i : 0,
                "noteIndex": diatonicIndex(model[i]),
                "noteheadX": normalNoteheadX,
                "groupLeftX": 0,
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
                    currentNote.noteheadX = previousNote.noteheadX === normalNoteheadX ? normalNoteheadX + noteheadStemUpSEX : normalNoteheadX
                }
            }

            var groupLeftX = group[0].noteheadX
            for (var groupLeftIndex = 1; groupLeftIndex < group.length; ++groupLeftIndex) {
                groupLeftX = Math.min(groupLeftX, group[groupLeftIndex].noteheadX)
            }
            for (var groupNoteIndex = 0; groupNoteIndex < group.length; ++groupNoteIndex) {
                group[groupNoteIndex].groupLeftX = groupLeftX
            }

            var accidentalColumn = 0
            for (var accidentalIndex = group.length - 1; accidentalIndex >= 0; --accidentalIndex) {
                const accidentalNote = group[accidentalIndex]
                if (root.accident(accidentalNote.pitch % 12) === 0) {
                    continue
                }
                accidentalNote.accidentalColumn = accidentalColumn % accidentalColumnCount
                ++accidentalColumn
            }
        }
        return notes
    }

    function displayStems(): var {
        if (!metadata.ready) {
            return []
        }

        var stems = []
        var positions = []
        var position
        for (var i = 0; i < model.length; ++i) {
            position = spaced ? i : 0
            if (positions.indexOf(position) === -1) {
                positions.push(position)
            }
        }

        for (var positionIndex = 0; positionIndex < positions.length; ++positionIndex) {
            position = positions[positionIndex]
            var minNoteIndex = Number.MAX_VALUE
            var maxNoteIndex = -Number.MAX_VALUE
            for (var modelIndex = 0; modelIndex < model.length; ++modelIndex) {
                if ((spaced ? modelIndex : 0) !== position) {
                    continue
                }
                const currentNoteIndex = diatonicIndex(model[modelIndex])
                minNoteIndex = Math.min(minNoteIndex, currentNoteIndex)
                maxNoteIndex = Math.max(maxNoteIndex, currentNoteIndex)
            }

            const topY = root.yForDiatonicIndex(maxNoteIndex) - stemExtension
            const bottomY = root.yForDiatonicIndex(minNoteIndex) - noteheadStemUpSEY
            stems.push({
                "position": position,
                "topY": topY,
                "height": Math.max(staffStep, bottomY - topY)
            })
        }
        return stems
    }

    Repeater {
        model: [38, 36, 34, 32, 30, 26, 24, 22, 20, 18]

        Rectangle {
            required property int modelData

            x: root.systemStartX
            y: root.yForDiatonicIndex(modelData) - height / 2
            width: root.width - root.systemStartX
            height: root.staffLineWidth
            color: root.staffColor
        }
    }

    BravuraText {
        id: systemBrace

        x: root.staffStep * 0.55
        y: root.systemBottomY + root.braceBBoxBottom * root.braceFontPixelSize / 4 - baselineOffset
        text: "\ue000"
        font.pixelSize: root.braceFontPixelSize
    }

    Rectangle {
        x: root.systemStartX - width / 2
        y: root.systemTopY - root.staffLineWidth / 2
        width: root.staffLineWidth
        height: root.systemHeight + root.staffLineWidth
        color: root.staffColor
    }

    BravuraText {
        id: trebleClef

        property int clefType: 0

        x: root.clefStartX
        y: root.yForDiatonicIndex(32) - height / 2
        text: "\ue050"
        font.pixelSize: root.staffStep * 8
    }

    BravuraText {
        x: root.clefStartX
        y: root.yForDiatonicIndex(24) - height / 2
        text: "\ue062"
        font.pixelSize: root.staffStep * 8
    }

    Repeater {
        model: root.displayStems()

        Rectangle {
            required property var modelData

            x: root.noteX(modelData.position) + root.normalNoteheadX + root.noteheadStemUpSEX - width / 2
            y: modelData.topY
            width: root.stemThickness
            height: modelData.height
            color: root.staffColor
        }
    }

    Repeater {
        model: metadata.ready ? root.displayNotes() : []

        Item {
            id: noteItem

            required property var modelData
            readonly property int pitch: modelData.pitch
            readonly property int noteIndex: modelData.noteIndex
            readonly property real noteheadX: modelData.noteheadX
            readonly property real noteheadCenterX: noteheadX + root.noteheadStemUpSEX / 2
            readonly property real groupLeftX: modelData.groupLeftX

            x: root.noteX(modelData.position)
            y: 0
            width: root.ledgerLineWidth + root.noteheadStemUpSEX
            height: root.height

            Repeater {
                model: root.ledgerLinesForPitch(noteItem.pitch)

                Rectangle {
                    required property int modelData

                    x: noteItem.noteheadCenterX - root.ledgerLineWidth / 2
                    y: root.yForDiatonicIndex(modelData) - noteItem.y - height / 2
                    width: root.ledgerLineWidth
                    height: root.ledgerLineThickness
                    color: root.staffColor
                }
            }

            BravuraText {
                readonly property string symbol: root.accidentalPrefix(noteItem.pitch)

                x: root.spaced
                    ? noteItem.noteheadX - width - root.accidentalNoteheadGap
                    : noteItem.groupLeftX - width - root.accidentalNoteheadGap - modelData.accidentalColumn * root.accidentalColumnSpacing
                y: root.yForDiatonicIndex(noteItem.noteIndex) - noteItem.y - height / 2
                visible: symbol.length > 0
                text: symbol
                font.pixelSize: root.staffStep * 5
            }

            BravuraText {
                x: noteItem.noteheadX
                y: root.yForDiatonicIndex(noteItem.noteIndex) - noteItem.y - height / 2
                text: "\ue0a4"
                font.pixelSize: root.noteheadFontPixelSize
            }
        }
    }
}
