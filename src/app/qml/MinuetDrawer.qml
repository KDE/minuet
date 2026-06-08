// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigami.platform as Platform

Kirigami.GlobalDrawer {
    id: drawer

    property var currentExerciseSelection: null
    property string currentSearchText: ""
    readonly property int defaultPreferredSize: Kirigami.Units.gridUnit * 24
    readonly property real drawerActionBottomPadding: homeActionItem.bottomPadding
    readonly property real drawerActionTopPadding: homeActionItem.topPadding
    readonly property real drawerActionVerticalSpacing: drawerActionTopPadding + drawerActionBottomPadding
    property var exerciseModel: []

    signal aboutRequested
    signal exerciseFilterSelected(var exerciseModel, string title, string inheritedIconName, string selectionKind)
    signal homeRequested
    signal settingsRequested

    function createDrawerActions(searchText: string): var {
        const normalizedSearchText = Core.exerciseCatalogController.normalizedText(searchText);
        const exerciseActions = createExerciseActions(exerciseModel, normalizedSearchText, "");
        if (normalizedSearchText === "" || Core.exerciseCatalogController.actionMatches(i18n("All exercises"), normalizedSearchText)) {
            return [allExercisesAction,].concat(exerciseActions);
        }
        return exerciseActions;
    }
    function createExerciseActions(exercises: var, searchText: string, inheritedIconName: string): var {
        const exerciseActions = [];
        for (const exercise of exercises) {
            const actionIconName = Core.exerciseCatalogController.actionIconNameForExercise(exercise, inheritedIconName);
            const hasChildren = exercise.children !== undefined && exercise.children.length > 0;
            const exerciseChildren = hasChildren ? createExerciseActions(exercise.children, searchText, actionIconName) : [];
            if (!hasChildren) {
                continue;
            }
            if (searchText !== "" && !Core.exerciseCatalogController.exerciseMatchesSearch(exercise, searchText, inheritedIconName)) {
                continue;
            }

            exerciseActions.push(exerciseActionComponent.createObject(drawer, {
                actionChildren: exerciseChildren,
                actionIconName: actionIconName,
                exercise: exercise
            }));
        }
        return exerciseActions;
    }

    actions: createDrawerActions(currentSearchText)
    drawerOpen: applicationWindow().wideScreen
    interactiveResizeEnabled: true
    modal: !applicationWindow().wideScreen
    preferredSize: defaultPreferredSize
    resetMenuOnTriggered: false

    header: Kirigami.AbstractApplicationHeader {
        id: appHeader

        maximumHeight: searchField.implicitHeight
        minimumHeight: searchField.implicitHeight

        contentItem: Kirigami.SearchField {
            id: searchField

            focus: applicationWindow().wideScreen && !Kirigami.InputMethod.willShowOnActive
            objectName: "searchField"
            placeholderText: i18n("Search…")

            onTextChanged: drawer.currentSearchText = text

            anchors {
                left: parent.left
                right: parent.right
            }
        }

        Binding {
            property: "preferredHeight"
            restoreMode: Binding.RestoreBindingOrValue
            target: appHeader
            value: searchField.implicitHeight + parent.topPadding + parent.bottomPadding
            when: Qt.platform.os === "android" || Qt.platform.os === "ios"
        }
        Binding {
            property: "topPadding"
            restoreMode: Binding.RestoreBindingOrValue
            target: appHeader
            value: Kirigami.Units.smallSpacing
            when: Qt.platform.os === "android" || Qt.platform.os === "ios"
        }
        Binding {
            property: "bottomPadding"
            restoreMode: Binding.RestoreBindingOrValue
            target: appHeader
            value: Kirigami.Units.smallSpacing
            when: Qt.platform.os === "android" || Qt.platform.os === "ios"
        }
    }
    topContent: [
        Image {
            readonly property real preferredIconSize: Kirigami.Units.gridUnit * 7

            Accessible.ignored: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: preferredIconSize
            Layout.preferredWidth: preferredIconSize
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: "qrc:/qml/images/minuet-icon.png"

            sourceSize {
                height: 128
                width: 128
            }
        },
        Kirigami.Heading {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            horizontalAlignment: Text.AlignHCenter
            level: 1
            text: i18n("Welcome to Minuet")
            wrapMode: Text.WordWrap
        },
        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
            horizontalAlignment: Qt.AlignHCenter
            text: i18n("Practice ear training with exercises for intervals, chords, rhythm, scales, and more.")
            wrapMode: Text.WordWrap
        },
        Kirigami.Separator {
            Layout.bottomMargin: drawer.drawerActionBottomPadding
            Layout.fillWidth: true
            Layout.topMargin: drawer.drawerActionVerticalSpacing
        },
        ActionListItem {
            id: homeActionItem

            action: Kirigami.Action {
                icon.name: "go-home"
                text: i18n("Home")

                onTriggered: {
                    drawer.homeRequested();
                    if (drawer.modal) {
                        drawer.close();
                    }
                }
            }
        },
        ActionListItem {
            action: Kirigami.Action {
                checked: drawer.currentExerciseSelection?.kind === "settings"
                icon.name: "settings-configure"
                text: i18n("Settings")

                onTriggered: {
                    drawer.settingsRequested();
                    if (drawer.modal) {
                        drawer.close();
                    }
                }
            }
        },
        ActionListItem {
            id: aboutActionItem

            action: Kirigami.Action {
                icon.name: "help-about-symbolic"
                text: i18n("About")

                onTriggered: {
                    drawer.aboutRequested();
                    if (drawer.modal) {
                        drawer.close();
                    }
                }
            }
        },
        Kirigami.Separator {
            Layout.bottomMargin: Math.max(0, drawer.drawerActionBottomPadding - Platform.Units.smallSpacing)
            Layout.fillWidth: true
            Layout.topMargin: drawer.drawerActionVerticalSpacing - aboutActionItem.bottomPadding
        },
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: Core.exerciseCatalogController.normalizedText(drawer.currentSearchText) !== "" && drawer.actions.length === 0
        }
    ]

    Kirigami.Action {
        id: allExercisesAction

        checked: drawer.currentExerciseSelection?.kind === "all"
        icon.name: "view-list-details"
        text: i18n("All exercises")

        onTriggered: {
            drawer.exerciseFilterSelected(drawer.exerciseModel, text, "", "all");
            if (drawer.modal) {
                drawer.close();
            }
        }
    }
    Component {
        id: exerciseActionComponent

        Kirigami.Action {
            required property var actionChildren
            property string actionIconName: ""
            required property var exercise

            checked: drawer.currentExerciseSelection?.kind === "category" && drawer.currentExerciseSelection.exercise === exercise
            children: actionChildren
            icon.name: actionIconName
            text: exercise ? i18nc("technical term, do you have a musician friend?", exercise.name) : ""

            onTriggered: {
                drawer.exerciseFilterSelected([exercise], text, actionIconName, "category");
                if (drawer.modal) {
                    drawer.close();
                }
            }
        }
    }
}
