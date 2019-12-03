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

Popup {
    id: aboutDialog

    modal: true
    focus: true
    x: (applicationWindow.width - width) / 2
    y: applicationWindow.height / 6
    width: Math.min(applicationWindow.width, applicationWindow.height) * 0.9
    contentHeight: aboutColumn.height

    Column {
        id: aboutColumn

        spacing: 15

        Image {
            id: icon

            source: "qrc:/minuet.png"
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize { width: 60; height: 60 }
            width: 60; height: 60

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.openUrlExternally("https://www.kde.org/applications/education/minuet/")
            }
            Label {
                anchors { horizontalCenter: parent.horizontalCenter; top: icon.bottom }
                text: "Minuet v0.3.70"
            }
        }

        Item { width: aboutDialog.availableWidth; height: 20 }
        
        Component {
            id: aboutLabel
            
            Label {
                id: label
                width: aboutDialog.availableWidth
                wrapMode: Label.WordWrap
                onLinkActivated: Qt.openUrlExternally(link)
                font.pixelSize: 13
            }
        }

        Loader {
            sourceComponent: aboutLabel
            onLoaded: item.text = "Minuet is a <a href='https://kde.org'>KDE</a> application for music education."
        }

        Loader {
            sourceComponent: aboutLabel
            onLoaded: item.text = "In case you want to learn more about Minuet, you can find more information " +
                                  "<a href='https://www.kde.org/applications/education/minuet/'>in the official site</a>.<br>" +
                                  "<br>Please use <a href='https://bugs.kde.org'>our bug tracker</a> to report bugs."
        }

        Loader {
            sourceComponent: aboutLabel
            onLoaded: item.text = "Developers:<br>Sandro Andrade &lt;<a href='mailto:sandroandrade@kde.org'>sandroandrade@kde.org</a>&gt;"+
                                  "<br>Ayush Shah &lt;<a href='mailto:1595ayush@gmail.com'>1595ayush@gmail.com</a>&gt;"
        }

        Loader {
            sourceComponent: aboutLabel
            onLoaded: item.text = "Icon Designer:<br>Alessandro Longo &lt;<a href='mailto:alessandro.longo@kdemail.net'>alessandro.longo@kdemail.net</a>&gt;"
        }
    }
}
