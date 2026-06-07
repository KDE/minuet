// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    readonly property int accidentalColumnCount: 3
    readonly property real accidentalColumnSpacing: accidentalMaxWidth + ledgerLineExtension
    readonly property real accidentalMaxWidth: Math.max(metadata.glyphBBoxValue("accidentalSharp", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalSharp", "bBoxSW", 0), metadata.glyphBBoxValue("accidentalFlat", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalFlat", "bBoxSW", 0), metadata.glyphBBoxValue("accidentalDoubleFlat", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalDoubleFlat", "bBoxSW", 0), metadata.glyphBBoxValue("accidentalDoubleSharp", "bBoxNE", 0) - metadata.glyphBBoxValue("accidentalDoubleSharp", "bBoxSW", 0)) * staffStep
    readonly property real accidentalNoteheadGap: Math.max(1, (metadata.engravingDefault("legerLineThickness") + metadata.engravingDefault("stemThickness")) * staffStep)
    readonly property real accidentalReserveWidth: accidentalNoteheadGap + (accidentalColumnCount - 1) * accidentalColumnSpacing + accidentalMaxWidth + Kirigami.Units.smallSpacing
    property alias activeClef: trebleClef
    readonly property real braceBBoxBottom: metadata.glyphBBoxValue("brace", "bBoxSW", 1)
    readonly property real braceBBoxHeight: metadata.glyphBBoxValue("brace", "bBoxNE", 1) - metadata.glyphBBoxValue("brace", "bBoxSW", 1)
    readonly property real braceFontPixelSize: braceBBoxHeight > 0 ? systemHeight * 4 / braceBBoxHeight : staffStep * 20
    readonly property real clefScale: 2
    readonly property real clefStartX: Math.round(systemStartX + staffStep * 1.4)
    readonly property real clefWidth: Math.max(metadata.glyphBBoxValue("gClef", "bBoxNE", 0) - metadata.glyphBBoxValue("gClef", "bBoxSW", 0), metadata.glyphBBoxValue("fClef", "bBoxNE", 0) - metadata.glyphBBoxValue("fClef", "bBoxSW", 0)) * staffStep * clefScale
    readonly property real fittedSpacedNoteSpacing: notePositionCount > 1 ? Math.max(1, (width - noteStartX - noteTailWidth - noteAreaRightPadding) / (notePositionCount - 1)) : preferredSpacedNoteSpacing
    readonly property real ledgerLineExtension: metadata.engravingDefault("legerLineExtension") * staffStep
    readonly property real ledgerLineThickness: Math.max(1, Math.round(metadata.engravingDefault("legerLineThickness") * staffStep))
    readonly property real ledgerLineWidth: noteheadBBoxWidth + ledgerLineExtension * 2
    readonly property var metadata: Core.sheetMusicController.metadata
    readonly property real middleCY: Math.round(height / 2)
    property var model: []
    readonly property real normalNoteheadX: ledgerLineWidth / 2
    readonly property real noteAreaRightPadding: Kirigami.Units.smallSpacing
    readonly property int notePositionCount: spaced ? Math.max(1, model.length) : 1
    readonly property real noteSpacing: spaced ? Math.min(preferredSpacedNoteSpacing, fittedSpacedNoteSpacing) : Kirigami.Units.gridUnit * 0.7
    readonly property real noteStartX: Math.round(clefStartX + clefWidth + accidentalReserveWidth + Kirigami.Units.smallSpacing)
    readonly property real noteTailWidth: ledgerLineWidth + noteheadStemUpSEX
    readonly property real noteheadBBoxWidth: (metadata.glyphBBoxValue("noteheadBlack", "bBoxNE", 0) - metadata.glyphBBoxValue("noteheadBlack", "bBoxSW", 0)) * staffStep * noteheadScale
    readonly property real noteheadFontPixelSize: staffStep * 6
    readonly property real noteheadScale: noteheadFontPixelSize / (staffStep * 4)
    readonly property real noteheadStemUpSEX: metadata.anchor("noteheadBlack", "stemUpSE")[0] * staffStep * noteheadScale
    readonly property real noteheadStemUpSEY: metadata.anchor("noteheadBlack", "stemUpSE")[1] * staffStep * noteheadScale
    readonly property real noteheadVerticalOffset: staffLineWidth
    readonly property real preferredSpacedNoteSpacing: Kirigami.Units.gridUnit * 1.6
    property bool spaced: true
    readonly property color staffColor: Kirigami.Theme.textColor
    readonly property real staffGroupHeight: systemHeight + staffLineWidth
    readonly property real staffLineWidth: Math.max(1, Math.round(metadata.engravingDefault("staffLineThickness") * staffStep))
    readonly property real staffPixelOffset: staffLineWidth % 2 === 1 ? 0.5 : 0
    readonly property int staffStep: 5
    readonly property real stemExtension: metadata.glyphBBoxValue("metNoteQuarterUp", "bBoxNE", 1) * staffStep
    readonly property real stemThickness: Math.max(1, Math.round(metadata.engravingDefault("stemThickness") * staffStep))
    readonly property real systemBottomY: Core.sheetMusicController.yForDiatonicIndex(18, middleCY, staffStep, staffPixelOffset)
    readonly property real systemHeight: (38 - 18) * staffStep
    readonly property real systemStartX: Math.round(staffStep * 3.2)
    readonly property real systemTopY: Core.sheetMusicController.yForDiatonicIndex(38, middleCY, staffStep, staffPixelOffset)
    readonly property real verticalMargin: staffStep * 10

    function clearAllMarks(): void {
        model = [];
    }

    clip: true
    implicitHeight: staffGroupHeight + verticalMargin * 2

    Repeater {
        model: [38, 36, 34, 32, 30, 26, 24, 22, 20, 18]

        Rectangle {
            required property int modelData

            color: root.staffColor
            height: root.staffLineWidth
            width: root.width - root.systemStartX
            x: root.systemStartX
            y: Core.sheetMusicController.yForDiatonicIndex(modelData, root.middleCY, root.staffStep, root.staffPixelOffset) - height / 2
        }
    }
    BravuraText {
        id: systemBrace

        font.pixelSize: root.braceFontPixelSize
        renderType: Text.CurveRendering
        text: "\ue000"
        x: root.staffStep * 0.55
        y: root.systemBottomY + root.braceBBoxBottom * root.braceFontPixelSize / 4 - baselineOffset
    }
    Rectangle {
        color: root.staffColor
        height: root.systemHeight + root.staffLineWidth
        width: root.staffLineWidth
        x: root.systemStartX - width / 2
        y: root.systemTopY - root.staffLineWidth / 2
    }
    Rectangle {
        color: root.staffColor
        height: root.systemHeight + root.staffLineWidth
        width: root.staffLineWidth
        x: root.width - width
        y: root.systemTopY - root.staffLineWidth / 2
    }
    BravuraText {
        id: trebleClef

        property int clefType: 0

        font.pixelSize: root.staffStep * 8
        text: "\ue050"
        x: root.clefStartX
        y: Core.sheetMusicController.yForDiatonicIndex(32, root.middleCY, root.staffStep, root.staffPixelOffset) - height / 2
    }
    BravuraText {
        font.pixelSize: root.staffStep * 8
        text: "\ue062"
        x: root.clefStartX
        y: Core.sheetMusicController.yForDiatonicIndex(24, root.middleCY, root.staffStep, root.staffPixelOffset) - height / 2
    }
    Repeater {
        model: metadata.ready ? Core.sheetMusicController.displayStems(root.model, root.spaced, root.staffStep, root.stemExtension, root.noteheadStemUpSEY, root.middleCY, root.staffPixelOffset) : []

        Rectangle {
            required property var modelData

            color: root.staffColor
            height: modelData.height
            width: root.stemThickness
            x: Core.sheetMusicController.noteX(modelData.position, root.noteStartX, root.noteSpacing) + root.normalNoteheadX + root.noteheadStemUpSEX - width / 2 - 1
            y: modelData.topY + root.noteheadVerticalOffset
        }
    }
    Repeater {
        model: metadata.ready ? Core.sheetMusicController.displayNotes(root.model, root.spaced, root.normalNoteheadX, root.noteheadStemUpSEX, root.accidentalColumnCount) : []

        Item {
            id: noteItem

            readonly property real groupLeftX: modelData.groupLeftX
            required property var modelData
            readonly property int noteIndex: modelData.noteIndex
            readonly property real noteheadCenterX: noteheadX + root.noteheadStemUpSEX / 2
            readonly property real noteheadX: modelData.noteheadX
            readonly property int pitch: modelData.pitch

            height: root.height
            width: root.ledgerLineWidth + root.noteheadStemUpSEX
            x: Core.sheetMusicController.noteX(modelData.position, root.noteStartX, root.noteSpacing)
            y: 0

            Repeater {
                model: Core.sheetMusicController.ledgerLinesForPitch(noteItem.pitch)

                Rectangle {
                    required property int modelData

                    color: root.staffColor
                    height: root.ledgerLineThickness
                    width: root.ledgerLineWidth
                    x: noteItem.noteheadCenterX - root.ledgerLineWidth / 2
                    y: Core.sheetMusicController.yForDiatonicIndex(modelData, root.middleCY, root.staffStep, root.staffPixelOffset) - noteItem.y - height / 2
                }
            }
            BravuraText {
                readonly property string symbol: Core.sheetMusicController.accidentalPrefix(noteItem.pitch)

                font.pixelSize: root.staffStep * 5
                text: symbol
                visible: symbol.length > 0
                x: root.spaced ? noteItem.noteheadX - width - root.accidentalNoteheadGap : noteItem.groupLeftX - width - root.accidentalNoteheadGap - modelData.accidentalColumn * root.accidentalColumnSpacing
                y: Core.sheetMusicController.yForDiatonicIndex(noteItem.noteIndex, root.middleCY, root.staffStep, root.staffPixelOffset) - noteItem.y - height / 2
            }
            BravuraText {
                font.pixelSize: root.noteheadFontPixelSize
                text: "\ue0a4"
                x: noteItem.noteheadX
                y: Core.sheetMusicController.yForDiatonicIndex(noteItem.noteIndex, root.middleCY, root.staffStep, root.staffPixelOffset) - noteItem.y - baselineOffset + root.noteheadVerticalOffset
            }
        }
    }
}
