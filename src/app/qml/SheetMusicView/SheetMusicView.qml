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
    readonly property var metadata: Core.sheetMusicController.metadata
    readonly property int staffStep: Math.max(4, Math.min(7, Math.round(height / 24)))
    readonly property real staffLineWidth: Math.max(1, Math.round(metadata.engravingDefault("staffLineThickness") * staffStep))
    readonly property real ledgerLineThickness: Math.max(1, Math.round(metadata.engravingDefault("legerLineThickness") * staffStep))
    readonly property real staffPixelOffset: staffLineWidth % 2 === 1 ? 0.5 : 0
    readonly property real middleCY: Math.round(height / 2)
    readonly property real ledgerLineExtension: metadata.engravingDefault("legerLineExtension") * staffStep
    readonly property real noteheadBBoxWidth: (metadata.glyphBBoxValue("noteheadBlack", "bBoxNE", 0) - metadata.glyphBBoxValue("noteheadBlack", "bBoxSW", 0)) * staffStep * noteheadScale
    readonly property real ledgerLineWidth: noteheadBBoxWidth + ledgerLineExtension * 2
    readonly property real systemTopY: Core.sheetMusicController.yForDiatonicIndex(38, middleCY, staffStep, staffPixelOffset)
    readonly property real systemBottomY: Core.sheetMusicController.yForDiatonicIndex(18, middleCY, staffStep, staffPixelOffset)
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

    Repeater {
        model: [38, 36, 34, 32, 30, 26, 24, 22, 20, 18]

        Rectangle {
            required property int modelData

            x: root.systemStartX
            y: Core.sheetMusicController.yForDiatonicIndex(modelData, root.middleCY, root.staffStep, root.staffPixelOffset) - height / 2
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
        renderType: Text.CurveRendering
    }

    Rectangle {
        x: root.systemStartX - width / 2
        y: root.systemTopY - root.staffLineWidth / 2
        width: root.staffLineWidth
        height: root.systemHeight + root.staffLineWidth
        color: root.staffColor
    }

    Rectangle {
        x: root.width - width
        y: root.systemTopY - root.staffLineWidth / 2
        width: root.staffLineWidth
        height: root.systemHeight + root.staffLineWidth
        color: root.staffColor
    }

    BravuraText {
        id: trebleClef

        property int clefType: 0

        x: root.clefStartX
        y: Core.sheetMusicController.yForDiatonicIndex(32, root.middleCY, root.staffStep, root.staffPixelOffset) - height / 2
        text: "\ue050"
        font.pixelSize: root.staffStep * 8
    }

    BravuraText {
        x: root.clefStartX
        y: Core.sheetMusicController.yForDiatonicIndex(24, root.middleCY, root.staffStep, root.staffPixelOffset) - height / 2
        text: "\ue062"
        font.pixelSize: root.staffStep * 8
    }

    Repeater {
        model: metadata.ready
            ? Core.sheetMusicController.displayStems(root.model, root.spaced, root.staffStep, root.stemExtension, root.noteheadStemUpSEY, root.middleCY, root.staffPixelOffset)
            : []

        Rectangle {
            required property var modelData

            x: Core.sheetMusicController.noteX(modelData.position, root.noteStartX, root.noteSpacing) + root.normalNoteheadX + root.noteheadStemUpSEX - width / 2
            y: modelData.topY
            width: root.stemThickness
            height: modelData.height
            color: root.staffColor
        }
    }

    Repeater {
        model: metadata.ready
            ? Core.sheetMusicController.displayNotes(root.model, root.spaced, root.normalNoteheadX, root.noteheadStemUpSEX, root.accidentalColumnCount)
            : []

        Item {
            id: noteItem

            required property var modelData
            readonly property int pitch: modelData.pitch
            readonly property int noteIndex: modelData.noteIndex
            readonly property real noteheadX: modelData.noteheadX
            readonly property real noteheadCenterX: noteheadX + root.noteheadStemUpSEX / 2
            readonly property real groupLeftX: modelData.groupLeftX

            x: Core.sheetMusicController.noteX(modelData.position, root.noteStartX, root.noteSpacing)
            y: 0
            width: root.ledgerLineWidth + root.noteheadStemUpSEX
            height: root.height

            Repeater {
                model: Core.sheetMusicController.ledgerLinesForPitch(noteItem.pitch)

                Rectangle {
                    required property int modelData

                    x: noteItem.noteheadCenterX - root.ledgerLineWidth / 2
                    y: Core.sheetMusicController.yForDiatonicIndex(modelData, root.middleCY, root.staffStep, root.staffPixelOffset) - noteItem.y - height / 2
                    width: root.ledgerLineWidth
                    height: root.ledgerLineThickness
                    color: root.staffColor
                }
            }

            BravuraText {
                readonly property string symbol: Core.sheetMusicController.accidentalPrefix(noteItem.pitch)

                x: root.spaced
                    ? noteItem.noteheadX - width - root.accidentalNoteheadGap
                    : noteItem.groupLeftX - width - root.accidentalNoteheadGap - modelData.accidentalColumn * root.accidentalColumnSpacing
                y: Core.sheetMusicController.yForDiatonicIndex(noteItem.noteIndex, root.middleCY, root.staffStep, root.staffPixelOffset) - noteItem.y - height / 2
                visible: symbol.length > 0
                text: symbol
                font.pixelSize: root.staffStep * 5
            }

            BravuraText {
                x: noteItem.noteheadX
                y: Core.sheetMusicController.yForDiatonicIndex(noteItem.noteIndex, root.middleCY, root.staffStep, root.staffPixelOffset) - noteItem.y - height / 2
                text: "\ue0a4"
                font.pixelSize: root.noteheadFontPixelSize
            }
        }
    }
}
