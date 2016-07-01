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

import org.kde.minuet 1.0

Rectangle {
    property alias pitch: pitchSlider.value
    property alias volume: volumeSlider.value
    property alias tempo: tempoSlider.value
    property alias playbackLabel: playbackLabelText.text
    property int sequencerState

    signal playActivated
    signal pauseActivated
    signal stopActivated

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
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: theme.viewBackgroundColor
                text: i18n("Tempo: %1 bpm").arg(Math.round(tempo))
            }
            Text {
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: theme.viewBackgroundColor
                text: i18n("Volume: %1%").arg(Math.round(volume))
            }
            Text {
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: theme.viewBackgroundColor
                text: i18n("Pitch: %1").arg(Math.round(pitch))
            }
        }
    }    
    Item {
        id: item1

        width: parent.width / 2 - 8; height: childrenRect.height
        anchors { left: parent.left; leftMargin: 8; top: labels.bottom; topMargin: 10 }

        Text {
            id: playbackLabelText

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 24
            color: "#008000"
        }
        MultimediaButton {
            width: playbackLabelText.contentWidth / 2
            anchors.horizontalCenterOffset: -30
            anchors { top: playbackLabelText.bottom; horizontalCenter: playbackLabelText.horizontalCenter }
            text: (sequencerState != ISoundBackend.PlayingState) ? i18n("Play"):i18n("Pause")
            source: (sequencerState != ISoundBackend.PlayingState) ? "../images/multimedia-play.png":"../images/multimedia-pause.png"
            onActivated: {
                if (sequencerState == ISoundBackend.StoppedState || sequencerState == ISoundBackend.PausedState)
                    playActivated()
                else
                    pauseActivated()
            }
        }
        MultimediaButton {
            width: playbackLabelText.contentWidth / 2
            anchors.horizontalCenterOffset: +30
            anchors { top: playbackLabelText.bottom; horizontalCenter: playbackLabelText.horizontalCenter }
            source: "../images/multimedia-stop.png"
            text: i18n("Stop")
            onActivated: stopActivated()
        }
    }
    Item {
        width: parent.width / 2 - 15; height: item1.height
        anchors { right: parent.right; rightMargin: 15; verticalCenter: item1.verticalCenter }

        Row {
            height: parent.height
            anchors.right: parent.right
            spacing: 8
            MultimediaSlider {
                id: pitchSlider

                source: "../images/multimedia-pitch.png"
                maximumValue: 12; minimumValue: -12; value: 0
            }
            MultimediaSlider {
                id: tempoSlider

                source: "../images/multimedia-speed.png"
                maximumValue: 200; minimumValue: 50; value: 100
            }
            MultimediaSlider {
                id: volumeSlider

                source: "../images/multimedia-volume.png"
                maximumValue: 200; value: 100
            }
        }
    }
}
