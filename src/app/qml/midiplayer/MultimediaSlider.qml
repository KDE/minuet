/****************************************************************************
**
** Copyright (C) 2016 by Sandro S. Andrade <sandroandrade@kde.org>
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

import QtQuick 2.7
import QtQuick.Controls 2.0

Item {
    property alias source: sliderImage.source
    property alias minimumValue: slider.from
    property alias maximumValue: slider.to
    property alias value: slider.value
    property string tooltipText

    width: sliderImage.width; height: parent.height

    Slider {
        id: slider
        
        height: parent.height - sliderImage.height - 5
        orientation: Qt.Vertical
        stepSize: 1
        hoverEnabled: true
        ToolTip.visible: hovered
        ToolTip.text: tooltipText
        handle: Rectangle {
            x: slider.leftPadding + (horizontal ? slider.visualPosition * (slider.availableWidth - width) : (slider.availableWidth - width) / 2)
            y: slider.topPadding + (horizontal ? (slider.availableHeight - height) / 2 : slider.visualPosition * (slider.availableHeight - height))
            implicitWidth: 16
            implicitHeight: 16
            radius: width / 2
            color: slider.enabled ? (slider.pressed ? (slider.visualFocus ? "#cce0ff" : "#f6f6f6") : (slider.visualFocus ? "#f0f6ff" : "#ffffff")) : "#fdfdfd"
            border.width: slider.visualFocus ? 2 : 1
            border.color: slider.enabled ? (slider.visualFocus ? "#0066ff" : (slider.pressed ? "#808080" : "#909090")) : "#d6d6d6"

            readonly property bool horizontal: slider.orientation === Qt.Horizontal
        }
    }
    Image {
        id: sliderImage

        width: 15; height: 15
        anchors { top: slider.bottom; topMargin: 5; horizontalCenter: slider.horizontalCenter }
    }
}
