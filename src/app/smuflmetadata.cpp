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

#include "smuflmetadata.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QDebug>

using namespace Qt::StringLiterals;

namespace Minuet
{
SmuflMetadata::SmuflMetadata(QObject *parent)
    : QObject(parent)
{
    QFile metadataFile(u":/qt/qml/org/kde/minuet/qml/SheetMusicView/bravura_metadata.json"_s);
    if (!metadataFile.open(QIODevice::ReadOnly)) {
        qWarning() << "Unable to load Bravura metadata:" << metadataFile.errorString();
        return;
    }

    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(metadataFile.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        qWarning() << "Unable to parse Bravura metadata:" << error.errorString();
        return;
    }

    m_data = document.object();
    if (!hasRequiredData()) {
        m_data = QJsonObject();
        qWarning() << "Bravura metadata is missing required SheetMusicView anchors";
        return;
    }

    m_ready = true;
}

bool SmuflMetadata::ready() const
{
    return m_ready;
}

QVariantList SmuflMetadata::anchor(const QString &glyphName, const QString &anchorName) const
{
    if (!m_ready) {
        return {0.0, 0.0};
    }

    const QJsonValue anchorValue = m_data[u"glyphsWithAnchors"_s].toObject()
        .value(glyphName)
        .toObject()
        .value(anchorName);
    const QJsonArray anchorArray = anchorValue.toArray();
    if (anchorArray.size() != 2) {
        qWarning() << "Bravura metadata is missing anchor" << glyphName << anchorName;
        return {0.0, 0.0};
    }

    return {anchorArray.at(0).toDouble(), anchorArray.at(1).toDouble()};
}

double SmuflMetadata::engravingDefault(const QString &name) const
{
    if (!m_ready) {
        return 0.0;
    }

    const QJsonValue defaultValue = m_data[u"engravingDefaults"_s].toObject().value(name);
    if (!defaultValue.isDouble()) {
        qWarning() << "Bravura metadata is missing engraving default" << name;
        return 0.0;
    }

    return defaultValue.toDouble();
}

double SmuflMetadata::glyphBBoxValue(const QString &glyphName, const QString &cornerName, int axis) const
{
    if (!m_ready) {
        return 0.0;
    }
    if (axis < 0 || axis > 1) {
        qWarning() << "Invalid Bravura bounding box axis" << axis;
        return 0.0;
    }

    const QJsonValue cornerValue = m_data[u"glyphBBoxes"_s].toObject()
        .value(glyphName)
        .toObject()
        .value(cornerName);
    const QJsonArray cornerArray = cornerValue.toArray();
    if (cornerArray.size() != 2) {
        qWarning() << "Bravura metadata is missing bounding box corner" << glyphName << cornerName;
        return 0.0;
    }

    return cornerArray.at(axis).toDouble();
}

bool SmuflMetadata::hasRequiredData() const
{
    const QJsonObject glyphsWithAnchors = m_data[u"glyphsWithAnchors"_s].toObject();
    const QJsonObject noteheadBlack = glyphsWithAnchors[u"noteheadBlack"_s].toObject();
    const QJsonObject engravingDefaults = m_data[u"engravingDefaults"_s].toObject();
    const QJsonObject glyphBBoxes = m_data[u"glyphBBoxes"_s].toObject();
    const QJsonObject noteheadBlackBBox = glyphBBoxes[u"noteheadBlack"_s].toObject();
    const QJsonObject metNoteQuarterUpBBox = glyphBBoxes[u"metNoteQuarterUp"_s].toObject();

    return noteheadBlack[u"stemUpSE"_s].isArray()
        && noteheadBlack[u"stemDownNW"_s].isArray()
        && engravingDefaults[u"staffLineThickness"_s].isDouble()
        && engravingDefaults[u"legerLineThickness"_s].isDouble()
        && engravingDefaults[u"legerLineExtension"_s].isDouble()
        && engravingDefaults[u"stemThickness"_s].isDouble()
        && noteheadBlackBBox[u"bBoxNE"_s].isArray()
        && noteheadBlackBBox[u"bBoxSW"_s].isArray()
        && metNoteQuarterUpBBox[u"bBoxNE"_s].isArray();
}
}
