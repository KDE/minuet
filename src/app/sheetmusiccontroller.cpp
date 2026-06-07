// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "sheetmusiccontroller.h"

#include "smuflmetadata.h"

#include <QVariantMap>

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace Minuet
{
namespace
{
constexpr int referenceMiddleCIndex = 28;

int positionForModelIndex(int index, bool spaced)
{
    return spaced ? index : 0;
}
}

SheetMusicController::SheetMusicController(QObject *parent)
    : QObject(parent)
    , m_metadata(new SmuflMetadata(this))
{
}

SmuflMetadata *SheetMusicController::metadata() const
{
    return m_metadata;
}

int SheetMusicController::noteNumber(int pitch) const
{
    const int number = pitch % 12;
    return number < 0 ? number + 12 : number;
}

int SheetMusicController::noteOctave(int pitch) const
{
    const int number = noteNumber(pitch);
    return (((pitch - 24) - number) / 12) + 1;
}

int SheetMusicController::diatonicOffset(int noteNumber) const
{
    static constexpr int offsets[] = {0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6};
    return offsets[this->noteNumber(noteNumber)];
}

int SheetMusicController::accident(int noteNumber) const
{
    static constexpr int accidentals[] = {0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0};
    return accidentals[this->noteNumber(noteNumber)];
}

int SheetMusicController::diatonicIndex(int pitch) const
{
    return noteOctave(pitch) * 7 + diatonicOffset(noteNumber(pitch));
}

double SheetMusicController::yForDiatonicIndex(int index, double middleCY, double staffStep, double staffPixelOffset) const
{
    return std::round(middleCY - (index - referenceMiddleCIndex) * staffStep) + staffPixelOffset;
}

double SheetMusicController::noteX(int position, double noteStartX, double noteSpacing) const
{
    return std::round(noteStartX + position * noteSpacing);
}

QString SheetMusicController::accidentalPrefix(int pitch) const
{
    return accidentalSymbol(accident(noteNumber(pitch)));
}

QString SheetMusicController::accidentalSymbol(int accidentValue) const
{
    switch (accidentValue) {
    case -2:
        return QStringLiteral("\ue264");
    case -1:
        return QStringLiteral("\ue260");
    case 1:
        return QStringLiteral("\ue262");
    case 2:
        return QStringLiteral("\ue263");
    default:
        return QString();
    }
}

QVariantList SheetMusicController::ledgerLinesForPitch(int pitch) const
{
    const int index = diatonicIndex(pitch);
    const bool treble = pitch >= 60;
    QVariantList lines;

    if (treble ? index > 38 : index > 26) {
        for (int lineIndex = treble ? 40 : 28; lineIndex <= index; lineIndex += 2) {
            lines.push_back(lineIndex);
        }
    } else if (treble ? index < 30 : index < 18) {
        for (int lineIndex = treble ? 28 : 16; lineIndex >= index; lineIndex -= 2) {
            lines.push_back(lineIndex);
        }
    }

    return lines;
}

QVariantList
SheetMusicController::displayNotes(const QVariantList &model, bool spaced, double normalNoteheadX, double noteheadStemUpSEX, int accidentalColumnCount) const
{
    QVariantList notes;
    notes.reserve(model.size());

    for (int i = 0; i < model.size(); ++i) {
        const int pitch = model.at(i).toInt();
        QVariantMap note;
        note[QStringLiteral("pitch")] = pitch;
        note[QStringLiteral("position")] = positionForModelIndex(i, spaced);
        note[QStringLiteral("noteIndex")] = diatonicIndex(pitch);
        note[QStringLiteral("noteheadX")] = normalNoteheadX;
        note[QStringLiteral("groupLeftX")] = 0.0;
        note[QStringLiteral("accidentalColumn")] = 0;
        notes.push_back(note);
    }

    std::vector<int> positions;
    positions.reserve(notes.size());
    for (const QVariant &noteValue : std::as_const(notes)) {
        const int position = noteValue.toMap().value(QStringLiteral("position")).toInt();
        if (std::find(positions.cbegin(), positions.cend(), position) == positions.cend()) {
            positions.push_back(position);
        }
    }

    for (const int position : positions) {
        std::vector<int> group;
        for (int i = 0; i < notes.size(); ++i) {
            if (notes.at(i).toMap().value(QStringLiteral("position")).toInt() == position) {
                group.push_back(i);
            }
        }

        std::sort(group.begin(), group.end(), [&notes](int first, int second) {
            return notes.at(first).toMap().value(QStringLiteral("noteIndex")).toInt() < notes.at(second).toMap().value(QStringLiteral("noteIndex")).toInt();
        });

        for (size_t i = 1; i < group.size(); ++i) {
            QVariantMap previousNote = notes.at(group.at(i - 1)).toMap();
            QVariantMap currentNote = notes.at(group.at(i)).toMap();
            if (currentNote.value(QStringLiteral("noteIndex")).toInt() - previousNote.value(QStringLiteral("noteIndex")).toInt() == 1) {
                currentNote[QStringLiteral("noteheadX")] = qFuzzyCompare(previousNote.value(QStringLiteral("noteheadX")).toDouble(), normalNoteheadX)
                    ? normalNoteheadX + noteheadStemUpSEX
                    : normalNoteheadX;
                notes[group.at(i)] = currentNote;
            }
        }

        double groupLeftX = std::numeric_limits<double>::max();
        for (const int groupNoteIndex : group) {
            groupLeftX = std::min(groupLeftX, notes.at(groupNoteIndex).toMap().value(QStringLiteral("noteheadX")).toDouble());
        }
        for (const int groupNoteIndex : group) {
            QVariantMap note = notes.at(groupNoteIndex).toMap();
            note[QStringLiteral("groupLeftX")] = groupLeftX;
            notes[groupNoteIndex] = note;
        }

        int accidentalColumn = 0;
        for (auto it = group.crbegin(); it != group.crend(); ++it) {
            QVariantMap note = notes.at(*it).toMap();
            if (accident(note.value(QStringLiteral("pitch")).toInt() % 12) == 0) {
                continue;
            }
            note[QStringLiteral("accidentalColumn")] = accidentalColumnCount > 0 ? accidentalColumn % accidentalColumnCount : 0;
            notes[*it] = note;
            ++accidentalColumn;
        }
    }

    return notes;
}

QVariantList SheetMusicController::displayStems(const QVariantList &model,
                                                bool spaced,
                                                double staffStep,
                                                double stemExtension,
                                                double noteheadStemUpSEY,
                                                double middleCY,
                                                double staffPixelOffset) const
{
    std::vector<int> positions;
    positions.reserve(model.size());
    for (int i = 0; i < model.size(); ++i) {
        const int position = positionForModelIndex(i, spaced);
        if (std::find(positions.cbegin(), positions.cend(), position) == positions.cend()) {
            positions.push_back(position);
        }
    }

    QVariantList stems;
    stems.reserve(static_cast<int>(positions.size()));
    for (const int position : positions) {
        int minNoteIndex = std::numeric_limits<int>::max();
        int maxNoteIndex = std::numeric_limits<int>::min();

        for (int modelIndex = 0; modelIndex < model.size(); ++modelIndex) {
            if (positionForModelIndex(modelIndex, spaced) != position) {
                continue;
            }
            const int currentNoteIndex = diatonicIndex(model.at(modelIndex).toInt());
            minNoteIndex = std::min(minNoteIndex, currentNoteIndex);
            maxNoteIndex = std::max(maxNoteIndex, currentNoteIndex);
        }

        const double topY = yForDiatonicIndex(maxNoteIndex, middleCY, staffStep, staffPixelOffset) - stemExtension;
        const double bottomY = yForDiatonicIndex(minNoteIndex, middleCY, staffStep, staffPixelOffset) - noteheadStemUpSEY;

        QVariantMap stem;
        stem[QStringLiteral("position")] = position;
        stem[QStringLiteral("topY")] = topY;
        stem[QStringLiteral("height")] = std::max(staffStep, bottomY - topY);
        stems.push_back(stem);
    }

    return stems;
}
}
