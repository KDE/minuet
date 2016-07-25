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

import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: minuetMenu

    property var currentExercise: undefined
    signal backPressed

    Button {
        id: breadcrumb

        width: (stackView.depth > 1) ? 24:0; height: parent.height
        text: "<"
        onClicked: {
            currentExercise = undefined
            stackView.pop()
            backPressed()
        }
    }
    StackView {
        id: stackView

        width: parent.width - breadcrumb.width; height: parent.height
        anchors.left: breadcrumb.right
        clip: true
        focus: true

        Component {
            id: categoryMenu

            Rectangle {
                property alias model: listView.model

                width: stackView.width; height: parent.height
                color: theme.viewBackgroundColor

                ListView {
                    id: listView
                    anchors.fill: parent
                    spacing: -2
                    delegate: ItemDelegate {
                        id: control
                        text: i18nc("technical term, do you have a musician friend?", modelData.name)
                        width: parent.width
                        onClicked: {
                            var children = modelData.children
                            if (!children)
                                minuetMenu.currentExercise = modelData
                            else
                                stackView.push(categoryMenu.createObject(stackView, {model: children}))
                        }
                        contentItem: Row {
                            spacing: 5
                            PlasmaCore.IconItem {
                                source: modelData._icon
                                visible: modelData._icon != undefined
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                            }
                            Text {
                                leftPadding: control.mirrored ? (control.indicator ? control.indicator.width : 0) + control.spacing : 0
                                rightPadding: !control.mirrored ? (control.indicator ? control.indicator.width : 0) + control.spacing : 0

                                text: control.text
                                font: control.font
                                color: control.enabled ? "#26282a" : "#bdbebf"
                                wrapMode: Text.WordWrap
                                anchors.verticalCenter: parent.verticalCenter
                                visible: control.text
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }

        Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: core.exerciseController.exercises})) }
    }
}
