// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.onboarding

Kirigami.ApplicationWindow {
    id: window

    property var currentExercise
    readonly property var currentPage: pageStack.depth > 0 ? pageStack.get(pageStack.currentIndex) : null

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
        internal.currentExerciseSelection = {
            kind: "about"
        };
        pageStack.clear();
        pageStack.push(createAboutPage());
    }
    function openExerciseFilter(exerciseModel: var, title: string, inheritedIconName: string, selectionKind: string): void {
        stopExerciseActivity();
        if (selectionKind === "all") {
            internal.currentExerciseSelection = {
                kind: "all"
            };
        } else if (selectionKind === "category" && Array.isArray(exerciseModel) && exerciseModel.length === 1) {
            internal.currentExerciseSelection = {
                kind: "category",
                exercise: exerciseModel[0]
            };
        } else {
            internal.currentExerciseSelection = null;
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
        internal.currentExerciseSelection = {
            kind: "home"
        };
        pageStack.clear();
        pageStack.push(createHomePage());
    }
    function openSettings(): void {
        stopExerciseActivity();
        internal.currentExerciseSelection = {
            kind: "settings"
        };
        pageStack.clear();
        pageStack.push(createSettingsPage());
    }
    function stopExerciseActivity(exercisePage: var): void {
        const page = exercisePage === undefined ? window.currentPage : exercisePage;
        if (page !== null && page !== undefined && typeof page.stopExerciseActivity === "function") {
            page.stopExerciseActivity();
        }
        window.currentExercise = undefined;
        Core.stopExerciseActivity();
    }

    Onboarding.blur: 1
    Onboarding.padding: Kirigami.Units.smallSpacing
    height: Screen.height
    title: currentPage?.title ?? internal.titleText
    visibility: Window.Maximized
    visible: true
    width: Screen.width

    globalDrawer: MinuetDrawer {
        currentExerciseSelection: internal.currentExerciseSelection
        exerciseModel: Core.exerciseCatalogController.exercises

        onAboutRequested: window.openAbout()
        onExerciseFilterSelected: function (exerciseModel, title, inheritedIconName, selectionKind) {
            window.openExerciseFilter(exerciseModel, title, inheritedIconName, selectionKind);
        }
        onHomeRequested: window.openHome()
        onSettingsRequested: window.openSettings()
    }

    Component.onCompleted: pageStack.push(createHomePage())
    Onboarding.onFinished: window.showPassiveNotification(i18n("Run this guide again any time from the Help icon."), "long")

    QtObject {
        id: internal

        property var currentExerciseSelection
        property int previousPageStackIndex: 0
        readonly property string titleText: i18n("Home")
    }
    pageStack {
        columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn

        globalToolBar {
            showNavigationButtons: pageStack.currentIndex > 0 ? Kirigami.ApplicationHeaderStyle.ShowBackButton : Kirigami.ApplicationHeaderStyle.None
            style: Kirigami.ApplicationHeaderStyle.ToolBar
        }
    }
    Connections {
        function onCurrentIndexChanged(): void {
            if (pageStack.currentIndex < internal.previousPageStackIndex) {
                window.stopExerciseActivity(pageStack.get(internal.previousPageStackIndex));
            }
            internal.previousPageStackIndex = pageStack.currentIndex;
        }

        target: pageStack
    }
    Component {
        id: homePageComponent

        Kirigami.Page {
            title: internal.titleText

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                explanation: i18n("Start by selecting an exercise topic from the drawer menu.")
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
