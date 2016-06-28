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
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.1

import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: minuetMenu

    property Item selectedMenuItem
    property string message

    signal breadcrumbPressed
    signal itemChanged(var model)
    signal userMessageChanged(string message)

    function itemClicked(delegateRect, index) {
        var model = delegateRect.ListView.view.model[index].options
        if (model != undefined) {
            exerciseController.currentExercise = model
            minuetMenu.itemChanged(model)
        }
    }

    Button {
        id: breadcrumb

        width: (stackView.depth > 1) ? 24:0; height: parent.height
        iconName: "go-previous"
        onClicked: {
            sequencer.allNotesOff()
            sequencer.clearSong()
            minuetMenu.breadcrumbPressed()
            selectedMenuItem = null
            stackView.pop()
            userMessageChanged("exercise")
            if (stackView.depth == 1)
                message = "exercise"
        }
    }
    StackView {
        id: stackView

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
                    var userMessage = delegateRect.ListView.view.model[index].userMessage
                    if (userMessage != undefined)
                        message = userMessage
                    var children = delegateRect.ListView.view.model[index].children
                    if (!children) {
                        if (selectedMenuItem != undefined) selectedMenuItem.checked = false
                        userMessageChanged(message)
                        itemClicked(delegateRect, index)
                        selectedMenuItem = delegateRect
                    }
                    else {
                        stackView.push(categoryMenu.createObject(stackView, {model: children}))
                        var root = delegateRect.ListView.view.model[index].root
                        if (root != undefined) {
                            exerciseController.minRootNote = parseInt(root.split('.')[0])
                            exerciseController.maxRootNote = parseInt(root.split('.')[2])
                        }
                        var playMode = delegateRect.ListView.view.model[index].playMode
                        if (playMode != undefined) {
                            if (playMode == "scale") exerciseController.setPlayMode(0) // ScalePlayMode
                            if (playMode == "chord") exerciseController.setPlayMode(1) // ChordPlayMode
                            exerciseController.answerLength = 1
                            if (playMode == "rhythm") {
                                exerciseController.setPlayMode(2) // RhythmPlayMode
                                exerciseController.answerLength = 4
                            }
                        }
                    }
                }
                style: MinuetButtonStyle {}
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

        Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: exerciseCategories})) }
    }
}
