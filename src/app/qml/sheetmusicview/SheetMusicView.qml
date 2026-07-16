// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var model: []
    property bool spaced: true

    function clearAllMarks(): void {
        model = [];
    }

    clip: true
    implicitHeight: internal.systemHeight + internal.staffLineWidth + internal.staffStep * 20

    QtObject {
        id: internal

        readonly property int accidentalColumnCount: 3
        readonly property real accidentalColumnSpacing: internal.accidentalMaxWidth + internal.ledgerLineExtension
        readonly property real accidentalMaxWidth: Math.max(internal.metadata.glyphBBoxValue("accidentalSharp", "bBoxNE", 0) - internal.metadata.glyphBBoxValue("accidentalSharp", "bBoxSW", 0), internal.metadata.glyphBBoxValue("accidentalFlat", "bBoxNE", 0) - internal.metadata.glyphBBoxValue("accidentalFlat", "bBoxSW", 0), internal.metadata.glyphBBoxValue("accidentalDoubleFlat", "bBoxNE", 0) - internal.metadata.glyphBBoxValue("accidentalDoubleFlat", "bBoxSW", 0), internal.metadata.glyphBBoxValue("accidentalDoubleSharp", "bBoxNE", 0) - internal.metadata.glyphBBoxValue("accidentalDoubleSharp", "bBoxSW", 0)) * internal.staffStep
        readonly property real accidentalNoteheadGap: Math.max(1, (internal.metadata.engravingDefault("legerLineThickness") + internal.metadata.engravingDefault("stemThickness")) * internal.staffStep)
        readonly property real braceBBoxHeight: internal.metadata.glyphBBoxValue("brace", "bBoxNE", 1) - internal.metadata.glyphBBoxValue("brace", "bBoxSW", 1)
        readonly property real braceFontPixelSize: internal.braceBBoxHeight > 0 ? internal.systemHeight * 4 / internal.braceBBoxHeight : internal.staffStep * 20
        readonly property real clefStartX: Math.round(internal.systemStartX + internal.staffStep * 1.4)
        readonly property real ledgerLineExtension: internal.metadata.engravingDefault("legerLineExtension") * internal.staffStep
        readonly property real ledgerLineWidth: {
            const noteheadBBoxWidth = (internal.metadata.glyphBBoxValue("noteheadBlack", "bBoxNE", 0) - internal.metadata.glyphBBoxValue("noteheadBlack", "bBoxSW", 0)) * internal.staffStep * internal.noteheadScale;
            return noteheadBBoxWidth + internal.ledgerLineExtension * 2;
        }
        readonly property var metadata: Core.sheetMusicController.metadata
        readonly property real middleCY: Math.round(root.height / 2)
        readonly property real normalNoteheadX: internal.ledgerLineWidth / 2
        readonly property int notePositionCount: root.spaced ? Math.max(1, root.model.length) : 1
        readonly property real noteSpacing: {
            if (!root.spaced) {
                return Kirigami.Units.gridUnit * 0.7;
            }
            const fittedSpacing = internal.notePositionCount > 1 ? Math.max(1, (root.width - internal.noteStartX - internal.ledgerLineWidth - internal.noteheadStemUpSEX - Kirigami.Units.smallSpacing) / (internal.notePositionCount - 1)) : internal.preferredSpacedNoteSpacing;
            return Math.min(internal.preferredSpacedNoteSpacing, fittedSpacing);
        }
        readonly property real noteStartX: {
            const clefScale = 2;
            const clefWidth = Math.max(internal.metadata.glyphBBoxValue("gClef", "bBoxNE", 0) - internal.metadata.glyphBBoxValue("gClef", "bBoxSW", 0), internal.metadata.glyphBBoxValue("fClef", "bBoxNE", 0) - internal.metadata.glyphBBoxValue("fClef", "bBoxSW", 0)) * internal.staffStep * clefScale;
            const accidentalReserveWidth = internal.accidentalNoteheadGap + (internal.accidentalColumnCount - 1) * internal.accidentalColumnSpacing + internal.accidentalMaxWidth + Kirigami.Units.smallSpacing;
            return Math.round(internal.clefStartX + clefWidth + accidentalReserveWidth + Kirigami.Units.smallSpacing);
        }
        readonly property real noteheadFontPixelSize: internal.staffStep * 6
        readonly property real noteheadScale: internal.noteheadFontPixelSize / (internal.staffStep * 4)
        readonly property real noteheadStemUpSEX: internal.metadata.anchor("noteheadBlack", "stemUpSE")[0] * internal.staffStep * internal.noteheadScale
        readonly property real noteheadVerticalOffset: internal.staffLineWidth
        readonly property real preferredSpacedNoteSpacing: Kirigami.Units.gridUnit * 1.6
        readonly property color staffColor: Kirigami.Theme.textColor
        readonly property real staffLineWidth: Math.max(1, Math.round(internal.metadata.engravingDefault("staffLineThickness") * internal.staffStep))
        readonly property real staffPixelOffset: internal.staffLineWidth % 2 === 1 ? 0.5 : 0
        readonly property int staffStep: 5
        readonly property real systemHeight: (38 - 18) * internal.staffStep
        readonly property real systemStartX: Math.round(internal.staffStep * 3.2)
        readonly property real systemTopY: Core.sheetMusicController.yForDiatonicIndex(38, internal.middleCY, internal.staffStep, internal.staffPixelOffset)
    }
    Repeater {
        model: [38, 36, 34, 32, 30, 26, 24, 22, 20, 18]

        Rectangle {
            required property int modelData

            color: internal.staffColor
            height: internal.staffLineWidth
            width: root.width - internal.systemStartX
            x: internal.systemStartX
            y: Core.sheetMusicController.yForDiatonicIndex(modelData, internal.middleCY, internal.staffStep, internal.staffPixelOffset) - height / 2
        }
    }
    BravuraText {
        id: systemBrace

        font.pixelSize: internal.braceFontPixelSize
        renderType: Text.CurveRendering
        text: "\ue000"
        x: internal.staffStep * 0.55
        y: Core.sheetMusicController.yForDiatonicIndex(18, internal.middleCY, internal.staffStep, internal.staffPixelOffset) + internal.metadata.glyphBBoxValue("brace", "bBoxSW", 1) * internal.braceFontPixelSize / 4 - baselineOffset
    }
    Rectangle {
        color: internal.staffColor
        height: internal.systemHeight + internal.staffLineWidth
        width: internal.staffLineWidth
        x: internal.systemStartX - width / 2
        y: internal.systemTopY - internal.staffLineWidth / 2
    }
    Rectangle {
        color: internal.staffColor
        height: internal.systemHeight + internal.staffLineWidth
        width: internal.staffLineWidth
        x: root.width - width
        y: internal.systemTopY - internal.staffLineWidth / 2
    }
    BravuraText {
        id: trebleClef

        font.pixelSize: internal.staffStep * 8
        text: "\ue050"
        x: internal.clefStartX
        y: Core.sheetMusicController.yForDiatonicIndex(32, internal.middleCY, internal.staffStep, internal.staffPixelOffset) - height / 2
    }
    BravuraText {
        font.pixelSize: internal.staffStep * 8
        text: "\ue062"
        x: internal.clefStartX
        y: Core.sheetMusicController.yForDiatonicIndex(24, internal.middleCY, internal.staffStep, internal.staffPixelOffset) - height / 2
    }
    Repeater {
        model: internal.metadata.ready ? Core.sheetMusicController.displayStems(root.model, root.spaced, internal.staffStep, internal.metadata.glyphBBoxValue("metNoteQuarterUp", "bBoxNE", 1) * internal.staffStep, internal.metadata.anchor("noteheadBlack", "stemUpSE")[1] * internal.staffStep * internal.noteheadScale, internal.middleCY, internal.staffPixelOffset) : []

        Rectangle {
            required property var modelData

            color: internal.staffColor
            height: modelData.height
            width: Math.max(1, Math.round(internal.metadata.engravingDefault("stemThickness") * internal.staffStep))
            x: Core.sheetMusicController.noteX(modelData.position, internal.noteStartX, internal.noteSpacing) + internal.normalNoteheadX + internal.noteheadStemUpSEX - width / 2 - 1
            y: modelData.topY + internal.noteheadVerticalOffset
        }
    }
    Repeater {
        model: internal.metadata.ready ? Core.sheetMusicController.displayNotes(root.model, root.spaced, internal.normalNoteheadX, internal.noteheadStemUpSEX, internal.accidentalColumnCount) : []

        Item {
            id: noteItem

            readonly property real groupLeftX: modelData.groupLeftX
            required property var modelData
            readonly property int noteIndex: modelData.noteIndex
            readonly property real noteheadX: modelData.noteheadX
            readonly property int pitch: modelData.pitch

            height: root.height
            width: internal.ledgerLineWidth + internal.noteheadStemUpSEX
            x: Core.sheetMusicController.noteX(modelData.position, internal.noteStartX, internal.noteSpacing)
            y: 0

            Repeater {
                model: Core.sheetMusicController.ledgerLinesForPitch(noteItem.pitch)

                Rectangle {
                    required property int modelData

                    color: internal.staffColor
                    height: Math.max(1, Math.round(internal.metadata.engravingDefault("legerLineThickness") * internal.staffStep))
                    width: internal.ledgerLineWidth
                    x: noteItem.noteheadX + internal.noteheadStemUpSEX / 2 - internal.ledgerLineWidth / 2
                    y: Core.sheetMusicController.yForDiatonicIndex(modelData, internal.middleCY, internal.staffStep, internal.staffPixelOffset) - noteItem.y - height / 2
                }
            }
            BravuraText {
                readonly property string symbol: Core.sheetMusicController.accidentalPrefix(noteItem.pitch)

                font.pixelSize: internal.staffStep * 5
                text: symbol
                visible: symbol.length > 0
                x: root.spaced ? noteItem.noteheadX - width - internal.accidentalNoteheadGap : noteItem.groupLeftX - width - internal.accidentalNoteheadGap - modelData.accidentalColumn * internal.accidentalColumnSpacing
                y: Core.sheetMusicController.yForDiatonicIndex(noteItem.noteIndex, internal.middleCY, internal.staffStep, internal.staffPixelOffset) - noteItem.y - height / 2
            }
            BravuraText {
                font.pixelSize: internal.noteheadFontPixelSize
                text: "\ue0a4"
                x: noteItem.noteheadX
                y: Core.sheetMusicController.yForDiatonicIndex(noteItem.noteIndex, internal.middleCY, internal.staffStep, internal.staffPixelOffset) - noteItem.y - baselineOffset + internal.noteheadVerticalOffset
            }
        }
    }
}
