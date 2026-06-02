// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: window

    visible: true
    width: Screen.width; height: Screen.height
    visibility: Window.Maximized

    property string titleText: i18n("Home")
    property var currentExercise
    property var currentExerciseSelection
    property int previousPageStackIndex: 0
    readonly property var currentPage: pageStack.depth > 0 ? pageStack.get(pageStack.currentIndex) : null

    title: currentPage?.title ?? titleText

    function stopExerciseActivity(): void {
        if (Core.soundController !== null) {
            Core.soundController.stop()
        }
        if (Core.exerciseSessionController.isTest) {
            Core.exerciseSessionController.stopTest()
        }
    }

    function openHome(): void {
        stopExerciseActivity()
        currentExercise = undefined
        currentExerciseSelection = null
        pageStack.clear()
        pageStack.push(createHomePage())
    }

    function openExerciseFilter(exerciseModel: var, title: string, inheritedIconName: string, selectionKind: string): void {
        stopExerciseActivity()
        currentExercise = undefined
        if (selectionKind === "all") {
            currentExerciseSelection = { kind: "all" }
        } else if (selectionKind === "category" && Array.isArray(exerciseModel) && exerciseModel.length === 1) {
            currentExerciseSelection = {
                kind: "category",
                exercise: exerciseModel[0],
            }
        } else {
            currentExerciseSelection = null
        }
        pageStack.clear()
        const page = exerciseMenuPageComponent.createObject(pageStack, {
            exerciseModel: exerciseModel,
            inheritedIconName: inheritedIconName,
            pathText: title,
        })
        pageStack.push(page)
    }

    function openAbout(): void {
        stopExerciseActivity()
        currentExercise = undefined
        currentExerciseSelection = { kind: "about" }
        pageStack.clear()
        pageStack.push(createAboutPage())
    }

    function openSettings(): void {
        stopExerciseActivity()
        currentExercise = undefined
        currentExerciseSelection = { kind: "settings" }
        pageStack.clear()
        pageStack.push(createSettingsPage())
    }

    pageStack {
        columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
        globalToolBar {
            style: Kirigami.ApplicationHeaderStyle.ToolBar
            showNavigationButtons: pageStack.currentIndex > 0 ? Kirigami.ApplicationHeaderStyle.ShowBackButton : Kirigami.ApplicationHeaderStyle.None
        }
    }

    Connections {
        target: pageStack

        function onCurrentIndexChanged(): void {
            if (pageStack.currentIndex < window.previousPageStackIndex) {
                window.stopExerciseActivity()
            }
            window.previousPageStackIndex = pageStack.currentIndex
        }
    }

    globalDrawer: MinuetDrawer {
        exerciseModel: Core.exerciseCatalogController.exercises
        currentExerciseSelection: window.currentExerciseSelection
        onExerciseFilterSelected: function(exerciseModel, title, inheritedIconName, selectionKind) {
            window.openExerciseFilter(exerciseModel, title, inheritedIconName, selectionKind)
        }
        onHomeRequested: window.openHome()
        onAboutRequested: window.openAbout()
        onSettingsRequested: window.openSettings()
    }

    Component.onCompleted: pageStack.push(createHomePage())

    function createHomePage(): Kirigami.Page {
        return homePageComponent.createObject(pageStack)
    }

    function createAboutPage(): Kirigami.Page {
        return aboutPageComponent.createObject(pageStack)
    }

    function createSettingsPage(): Kirigami.Page {
        return settingsPageComponent.createObject(pageStack)
    }

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

    Component {
        id: exerciseMenuPageComponent

        ExerciseMenuPage {}
    }

    Component {
        id: aboutPageComponent

        AboutPage {}
    }

    Component {
        id: settingsPageComponent

        SettingsPage {}
    }

    Binding {
        target: Core.exerciseSessionController
        property: "activeExercise"
        value: window.currentExercise
    }
    
    Binding {
        target: Core.soundController
        property: "playMode"
        value: (window.currentExercise !== undefined) ? window.currentExercise["playMode"] : ""
    }
    
    Shortcut {
        sequences: [StandardKey.Quit]
        onActivated: Qt.quit()
    }
}
