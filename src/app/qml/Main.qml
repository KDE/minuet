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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.0
import QtQuick.Controls.Material 2.0

ApplicationWindow {
    id: applicationWindow
    visible: true
    width: Screen.desktopAvailableWidth; height: Screen.desktopAvailableHeight

    property string titleText: "Minuet"

    Component {
        id: androidToolBar
        ToolBar {
            Material.primary: "#181818"
            Material.foreground: "white"
            RowLayout {
                spacing: 20
                anchors.fill: parent
                height: parent.height / 5

                ToolButton {
                    contentItem: Image {
                        fillMode: Image.Pad
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter
                        source: "qrc:/menu.png"
                    }
                    onClicked: drawer.open()
                }

                Label {
                    text: titleText
                    elide: Label.ElideRight
                    font { weight: Font.Bold; pixelSize: 16 }
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }

                ToolButton {
                    contentItem: Image {
                        fillMode: Image.Pad
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter
                        source: "qrc:/more_vert.png"
                    }
                    onClicked: optionsMenu.open()

                    Menu {
                        id: optionsMenu
                        x: parent.width - width
                        transformOrigin: Menu.TopRight
                        MenuItem {
                            text: "About"
                            onTriggered: aboutDialog.open()
                        }
                    }
                }
            }
        }
    }

    Item {
        id: mainContainer
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; left: (Qt.platform.os == "android") ? parent.left:drawer.right; margins: Screen.width >= 1024 ? 20:5 }

        Image {
            source: "qrc:/qml/images/minuet-background.png"
            anchors.fill: parent
            fillMode: Image.Tile
        }
        ExerciseView {
            id: exerciseView
            anchors.fill: parent

            currentExercise: minuetMenu.currentExercise
        }
/*      THIS IS THE DASHBOARD
        Frame {
            id: frame
            anchors { fill: parent; margins: 15 }
            Label {
                id: greetings
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "Hi, what kind of ear training exercise do you want to practice today?"
                font { family: "Roboto" }
            }
            Grid {
                rows: 2
                columns: 2
                anchors.centerIn: parent
                spacing: 40
                Repeater {
                    model: [
                        { icon: "qrc:/minuet-chords.svg", title: "Chords" },
                        { icon: "qrc:/minuet-intervals.svg", title: "Intervals" },
                        { icon: "qrc:/minuet-rhythms.svg", title: "Rhythms" },
                        { icon: "qrc:/minuet-scales.svg", title: "Scales" }
                    ]
                    Column {
                        Image {
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: frame.width/4;
                            width: frame.width/4; height: width
                            anchors.horizontalCenter: parent.horizontalCenter
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    frame.visible = true
                                    stackView.currentExerciseMenuItem = null
                                    exerciseController.currentExercise ={}
                                    titleText = "Minuet"
                                    
                                    while (stackView.depth > 1) {
                                        stackView.pop()
                                        minuetMenu.exerciseArray.pop()
                                        currentExerciseParent.text = minuetMenu.exerciseArray.toString()
                                        minuetMenu.backPressed()
                                    }
                                    
                                    for (var i = 0; i < exerciseController.exercises.length; ++i) {
                                        if (exerciseController.exercises[i].name == modelData.title) {
                                            frame.visible = true
                                            stackView.push(categoryMenu.createObject(stackView, {model: exerciseController.exercises[i].children}))
                                            currentExerciseParent.text = exerciseController.exercises[i].name
                                            minuetMenu.exerciseArray.push(exerciseController.exercises[i].name)
                                            break
                                        }
                                    }
                                    drawer.open()
                                }
                            }
                        }
                        Label {
                            width: frame.width/4
                            wrapMode: Text.WordWrap
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.title
                            font { family: "Roboto" }
                        }
                    }
                }
            }
        }
*/
    }

    MinuetMenuContainer {
        id: drawer

        MinuetMenu {
            id: minuetMenu
            onBackPressed: {
                instrumentView.resetTest()
                core.soundController.reset()
            }
            onCurrentExerciseChanged: if (Qt.platform.os == "android" && currentExercise != undefined) drawer.close()
        }
    }

    AboutDialog {
        id: aboutDialog
    }
    
    Binding {
        target: core.exerciseController
        property: "currentExercise"
        value: minuetMenu.currentExercise
    }
    
    Binding {
        target: core.soundController
        property: "playMode"
        value: (minuetMenu.currentExercise != undefined) ? minuetMenu.currentExercise["playMode"]:""
    }
    
    Component.onCompleted: if (Qt.platform.os == "android") header = androidToolBar.createObject(applicationWindow)
}
