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
    id: minuetMenu

    readonly property alias currentExercise: stackView.currentExercise

    signal backPressed

    Button {
        id: breadcrumb

        width: (stackView.depth > 1) ? 24:0; height: parent.height
        text: "<"
        onClicked: {
            stackView.currentExerciseMenuItem = null
            core.exerciseController.currentExercise = {}
            stackView.pop()
            backPressed()
        }
    }
    StackView {
        id: stackView

        property var currentExercise
        property Item currentExerciseMenuItem

        width: parent.width - breadcrumb.width; height: parent.height
        anchors.left: breadcrumb.right
        clip: true
        focus: true

        Component {
            id: categoryDelegate

            Button {
                id: delegateRect

                width: parent.width; height: 55
                text: i18nc("technical term, do you have a musician friend?", modelData.name)
                checkable: (!delegateRect.ListView.view.model[index].children) ? true:false
                onClicked: {
                    var children = delegateRect.ListView.view.model[index].children
                    if (!children) {
                        if (stackView.currentExerciseMenuItem != undefined) stackView.currentExerciseMenuItem.checked = false
                        stackView.currentExercise = delegateRect.ListView.view.model[index]
                        stackView.currentExerciseMenuItem = delegateRect
                    }
                    else {
                        stackView.push(categoryMenu.createObject(stackView, {model: children}))
                    }
                }
            }
        }
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
                    delegate: categoryDelegate
                }
            }
        }

        Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: core.exerciseController.exercises})) }
    }
}
