/****************************************************************************
**
** Copyright (C) 2016 by Stefan Toncu <stefan.toncu29@gmail.com>
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
import QtQuick.Controls 2.2
import QtQuick 2.7

Item {
    property alias pluginMainPageLoader2: pluginMainPageLoader2

    function noteOn(chan, pitch, vel) {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.noteOn(chan, pitch, vel)
    }
    function noteOff(chan, pitch, vel) {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.noteOff(chan, pitch, vel)
    }
    function noteMark(chan, pitch, vel, color) {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.noteMark(chan, pitch, vel, color)
    }
    function noteUnmark(chan, pitch, vel, color) {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.noteUnmark(chan, pitch, vel, color)
    }
    function clearAllMarks() {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.clearAllMarks()
    }
    function scrollToNote(pitch) {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.scrollToNote(pitch)
    }
    function highlightKey(pitch, color) {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.highlightKey(pitch, color)
    }
    function itemForPitch(pitch) {
        if (pluginMainPageLoader2.item)
            pluginMainPageLoader2.item.itemForPitch(pitch)
    }

    TabBar {
        id: tabBar
        anchors.top: parent.top
        Repeater {
            id: tabBar_repeater
            model: contents
            TabButton {
                id: button
                text: qsTr(modelData.menuName)
                onClicked: {
                    console.log(modelData.pluginName + "/" + modelData.mainPage)
                    pluginMainPageLoader2.source = "file://" + modelData.pluginName + "/" + modelData.mainPage
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: parent.height - tabBar.height
        anchors.bottom: parent.bottom
        color: "grey"
        Loader {
            anchors.fill: parent
            id: pluginMainPageLoader2
        }
    }

    Component.onCompleted: {
        //load the first available plugin instrument
        if (!contents[0])
            console.log("No plugin available!")
        else
            pluginMainPageLoader2.source = "file://" + contents[0].pluginName + "/" + contents[0].mainPage
    }
}
