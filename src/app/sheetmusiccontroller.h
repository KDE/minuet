// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_SHEETMUSICCONTROLLER_H
#define MINUET_SHEETMUSICCONTROLLER_H

#include <QObject>
#include <QVariantList>
#include <qqmlregistration.h>

Q_MOC_INCLUDE("smuflmetadata.h")

namespace Minuet
{
class SmuflMetadata;

class SheetMusicController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("SheetMusicController is provided by Core")
    Q_PROPERTY(Minuet::SmuflMetadata *metadata READ metadata CONSTANT)

public:
    SmuflMetadata *metadata() const;

    Q_INVOKABLE int noteNumber(int pitch) const;
    Q_INVOKABLE int noteOctave(int pitch) const;
    Q_INVOKABLE int diatonicOffset(int noteNumber) const;
    Q_INVOKABLE int accident(int noteNumber) const;
    Q_INVOKABLE int diatonicIndex(int pitch) const;
    Q_INVOKABLE double yForDiatonicIndex(int index, double middleCY, double staffStep, double staffPixelOffset) const;
    Q_INVOKABLE double noteX(int position, double noteStartX, double noteSpacing) const;
    Q_INVOKABLE QString accidentalPrefix(int pitch) const;
    Q_INVOKABLE QString accidentalSymbol(int accidentValue) const;
    Q_INVOKABLE QVariantList ledgerLinesForPitch(int pitch) const;
    Q_INVOKABLE QVariantList
    displayNotes(const QVariantList &model, bool spaced, double normalNoteheadX, double noteheadStemUpSEX, int accidentalColumnCount) const;
    Q_INVOKABLE QVariantList displayStems(const QVariantList &model,
                                          bool spaced,
                                          double staffStep,
                                          double stemExtension,
                                          double noteheadStemUpSEY,
                                          double middleCY,
                                          double staffPixelOffset) const;

private:
    friend class Core;

    explicit SheetMusicController(QObject *parent = nullptr);

    SmuflMetadata *m_metadata;
};
}

#endif
