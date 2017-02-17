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
import QtQuick.Layouts 1.3

Item {
    anchors.fill: parent
    //spacing: 0

    property var currentExercise: undefined
    
    signal backPressed

    QtObject {
        id: internal
        property variant exercisePath: []
    }

    Image {
        id: image

        source: "qrc:/qml/images/minuet-drawer.png"
        width: parent.width; height: 0.53125 * width
        fillMode: Image.PreserveAspectFit
    }

    Item {
        id: breadcrumb

        width: parent.width; height: (stackView.depth > 1) ? 50:0
        anchors.top: image.bottom
        clip: true
        RowLayout {
            anchors.fill: parent
            Image {
                id: backButton

                fillMode: Image.Pad
                width: 24; height: 24
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: "qrc:/keyboard_arrow_left.png"
            }

            Label {
                id: currentExerciseParent
                text: ""
                elide: Label.ElideRight
                font { weight: Font.Bold; pixelSize: 12 }
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                /*
                frame.visible = true
                stackView.currentExerciseMenuItem = null
                */
                currentExercise = undefined
                stackView.pop()
                internal.exercisePath.pop()
                currentExerciseParent.text = i18nc("technical term, do you have a musician friend?", internal.exercisePath.toString())
                backPressed()
                /*
                titleText = "Minuet"
                */
            }
        }
    }
    
    StackView {
        id: stackView

        width: parent.width; height: parent.height - image.height - breadcrumb.height
        anchors.top: breadcrumb.bottom
        clip: true
        focus: true

        Component {
            id: categoryMenu

            ListView {
                delegate: ImageItemDelegate {
                    id: control
                    width: parent.width; height: 50
                    text: i18nc("technical term, do you have a musician friend?", modelData.name)
                    onClicked: {
                        exerciseView.resetTest()
                        var children = modelData.children
                        if (!children) {
                            currentExercise = modelData
                        }
                        else {
                            internal.exercisePath.push(modelData.name)
                            stackView.push(categoryMenu.createObject(stackView, {model: children}))
                            currentExerciseParent.text = i18nc("technical term, do you have a musician friend?", modelData.name)
                        }
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator { }
            }
        }

        Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: core.exerciseController.exercises})) }
    }
}
