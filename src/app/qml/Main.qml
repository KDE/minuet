// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: window

    property var currentExercise
    property var currentExerciseSelection
    readonly property var currentPage: pageStack.depth > 0 ? pageStack.get(pageStack.currentIndex) : null
    property int previousPageStackIndex: 0
    property string titleText: i18n("Home")

    function createAboutPage(): Kirigami.Page {
        return aboutPageComponent.createObject(pageStack);
    }
    function createHomePage(): Kirigami.Page {
        return homePageComponent.createObject(pageStack);
    }
    function createSettingsPage(): Kirigami.Page {
        return settingsPageComponent.createObject(pageStack);
    }
    function openAbout(): void {
        stopExerciseActivity();
        currentExercise = undefined;
        currentExerciseSelection = {
            kind: "about"
        };
        pageStack.clear();
        pageStack.push(createAboutPage());
    }
    function openExerciseFilter(exerciseModel: var, title: string, inheritedIconName: string, selectionKind: string): void {
        stopExerciseActivity();
        currentExercise = undefined;
        if (selectionKind === "all") {
            currentExerciseSelection = {
                kind: "all"
            };
        } else if (selectionKind === "category" && Array.isArray(exerciseModel) && exerciseModel.length === 1) {
            currentExerciseSelection = {
                kind: "category",
                exercise: exerciseModel[0]
            };
        } else {
            currentExerciseSelection = null;
        }
        pageStack.clear();
        const page = exerciseMenuPageComponent.createObject(pageStack, {
            exerciseModel: exerciseModel,
            inheritedIconName: inheritedIconName,
            pathText: title
        });
        pageStack.push(page);
    }
    function openHome(): void {
        stopExerciseActivity();
        currentExercise = undefined;
        currentExerciseSelection = null;
        pageStack.clear();
        pageStack.push(createHomePage());
    }
    function openSettings(): void {
        stopExerciseActivity();
        currentExercise = undefined;
        currentExerciseSelection = {
            kind: "settings"
        };
        pageStack.clear();
        pageStack.push(createSettingsPage());
    }
    function stopExerciseActivity(): void {
        if (Core.soundController !== null) {
            Core.soundController.stop();
        }
        if (Core.exerciseSessionController.isTest) {
            Core.exerciseSessionController.stopTest();
        }
    }

    height: Screen.height
    title: currentPage?.title ?? titleText
    visibility: Window.Maximized
    visible: true
    width: Screen.width

    globalDrawer: MinuetDrawer {
        currentExerciseSelection: window.currentExerciseSelection
        exerciseModel: Core.exerciseCatalogController.exercises

        onAboutRequested: window.openAbout()
        onExerciseFilterSelected: function (exerciseModel, title, inheritedIconName, selectionKind) {
            window.openExerciseFilter(exerciseModel, title, inheritedIconName, selectionKind);
        }
        onHomeRequested: window.openHome()
        onSettingsRequested: window.openSettings()
    }

    Component.onCompleted: pageStack.push(createHomePage())

    pageStack {
        columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn

        globalToolBar {
            showNavigationButtons: pageStack.currentIndex > 0 ? Kirigami.ApplicationHeaderStyle.ShowBackButton : Kirigami.ApplicationHeaderStyle.None
            style: Kirigami.ApplicationHeaderStyle.ToolBar
        }
    }
    Connections {
        function onCurrentIndexChanged(): void {
            if (pageStack.currentIndex < window.previousPageStackIndex) {
                window.stopExerciseActivity();
            }
            window.previousPageStackIndex = pageStack.currentIndex;
        }

        target: pageStack
    }
    Component {
        id: homePageComponent

        Kirigami.Page {
            title: window.titleText

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                explanation: i18n("Start with a topic, then pick the specific training level.")
                icon.name: "qrc:/icons/64-apps-minuet.png"
                text: i18n("Choose an exercise")
                width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 28)
            }
        }
    }
    Component {
        id: exerciseMenuPageComponent

        ExerciseMenuPage {
        }
    }
    Component {
        id: aboutPageComponent

        AboutPage {
        }
    }
    Component {
        id: settingsPageComponent

        SettingsPage {
        }
    }
    Binding {
        property: "activeExercise"
        target: Core.exerciseSessionController
        value: window.currentExercise
    }
    Binding {
        property: "playMode"
        target: Core.soundController
        value: (window.currentExercise !== undefined) ? window.currentExercise["playMode"] : ""
    }
    Shortcut {
        sequences: [StandardKey.Quit]

        onActivated: Qt.quit()
    }
}
