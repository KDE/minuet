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

import QtQuick 2.4
import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle {
    function timeLabelChanged(timeLabel) { playbackTime.text = timeLabel }
    function volumeChanged(value) { volumeLabel.text = i18n("Volume: %1\%").arg(value) }
    function tempoChanged(value) { tempoLabel.text = i18n("Tempo: %1 bpm").arg(value) }
    function pitchChanged(value) { pitchLabel.text = i18n("Pitch: %1").arg(value) }

    height: childrenRect.height + 15
    anchors { left: parent.left; bottom: parent.bottom }
    color: "black"

    Rectangle {
        id: labels

        width: parent.width; height: 20
        anchors.top: parent.top
        color: theme.viewTextColor
        Row {
            width: parent.width
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 15 }
            Text {
                id: tempoLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: theme.viewBackgroundColor
                text: i18n("Tempo:")
            }
            Text {
                id: volumeLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: theme.viewBackgroundColor
                text: i18n("Volume: 100%")
            }
            Text {
                id: pitchLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: theme.viewBackgroundColor
                text: i18n("Pitch: 0")
            }
        }
    }    
    Item {
        id: item1

        width: parent.width / 2 - 8; height: childrenRect.height
        anchors { left: parent.left; leftMargin: 8; top: labels.bottom; topMargin: 10 }

        Text {
            id: playbackTime

            width: item1.width
            horizontalAlignment: Text.AlignHCenter
            text: "00:00.00"
            font.pointSize: 24
            color: "#008000"
        }
        MultimediaButton {
            id: item12

            anchors { top: playbackTime.bottom; horizontalCenter: playbackTime.horizontalCenter }
            source: "qrc:/images/multimedia-pause.png"
            text: i18n("Pause")
            onActivated: sequencer.pause()
        }
        MultimediaButton {
            anchors { top: playbackTime.bottom; right: item12.left; rightMargin: -2 }
            source: "qrc:/images/multimedia-play.png"
            text: i18n("Play")
            onActivated: sequencer.play()
        }
        MultimediaButton {
            anchors { top: playbackTime.bottom; left: item12.right; leftMargin: -2 }
            source: "qrc:/images/multimedia-stop.png"
            text: i18n("Stop")
            onActivated: sequencer.stop()
        }
    }
    Item {
        id: item2

        width: parent.width / 2 - 15; height: item1.height
        anchors { right: parent.right; rightMargin: 15; verticalCenter: item1.verticalCenter }

        Row {
            height: parent.height
            anchors.right: parent.right
            spacing: 8
            MultimediaSlider {
                source: "qrc:/images/multimedia-pitch.png"
                maximumValue: 12; minimumValue: -12; value: 0
                onValueChanged: sequencer.setPitchShift(value)
            }
            MultimediaSlider {
                source: "qrc:/images/multimedia-speed.png"
                maximumValue: 200; minimumValue: 50; value: 100
                onValueChanged: sequencer.setTempoFactor(value)
            }
            MultimediaSlider {
                source: "qrc:/images/multimedia-volume.png"
                maximumValue: 200; value: 100
                onValueChanged: sequencer.setVolumeFactor(value)
            }
        }
    }
}
