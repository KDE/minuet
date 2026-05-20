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

import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: window

    visible: true
    width: Screen.width; height: Screen.height
    visibility: Window.Maximized

    property string titleText: "Home"
    property var currentExercise
    readonly property Item currentPage: pageStack.depth > 0 ? pageStack.get(pageStack.currentIndex) : null

    title: currentPage?.title ?? titleText

    function openHome() {
        currentExercise = undefined
        pageStack.clear()
        pageStack.push(homePageComponent)
    }

    function openExerciseFilter(exerciseModel, title, inheritedIconName) {
        currentExercise = undefined
        pageStack.clear()
        pageStack.push(Qt.resolvedUrl("ExerciseMenuPage.qml"), {
            exerciseModel: exerciseModel,
            inheritedIconName: inheritedIconName,
            pathText: title,
        })
    }

    pageStack {
        columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
        globalToolBar {
            style: Kirigami.ApplicationHeaderStyle.ToolBar
            showNavigationButtons: pageStack.currentIndex > 0 ? Kirigami.ApplicationHeaderStyle.ShowBackButton : Kirigami.ApplicationHeaderStyle.None
        }
    }

    globalDrawer: MinuetDrawer {
        exerciseModel: core.exerciseController.exercises
        wideScreen: window.wideScreen
        onExerciseFilterSelected: (exerciseModel, title, inheritedIconName) => window.openExerciseFilter(exerciseModel, title, inheritedIconName)
        onHomeRequested: window.openHome()
        onAboutRequested: aboutDialog.open()
    }

    pageStack.initialPage: homePageComponent

    Component {
        id: homePageComponent

        Kirigami.Page {
            title: window.titleText

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 28)
                icon.name: "qrc:/icons/64-apps-minuet.png"
                text: i18n("Choose an exercise")
                explanation: i18n("Start with a topic, then pick the specific training level.")
            }
        }
    }

    AboutDialog {
        id: aboutDialog
    }
    
    Binding {
        target: core.exerciseController
        property: "currentExercise"
        value: window.currentExercise
    }
    
    Binding {
        target: core.soundController
        property: "playMode"
        value: (window.currentExercise != undefined) ? window.currentExercise["playMode"] : ""
    }
    
    Shortcut {
        sequence: StandardKey.Quit
        onActivated: Qt.quit()
    }
}
