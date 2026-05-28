/****************************************************************************
**
** Copyright (C) 2026 by Sandro S. Andrade <sandroandrade@kde.org>
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
    Q_INVOKABLE QVariantList displayNotes(const QVariantList &model,
                                          bool spaced,
                                          double normalNoteheadX,
                                          double noteheadStemUpSEX,
                                          int accidentalColumnCount) const;
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
