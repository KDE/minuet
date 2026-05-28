// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.GlobalDrawer {
    id: drawer

    property var exerciseModel: []
    property var currentExerciseSelection: null
    property bool wideScreen: false
    property string currentSearchText: ""
    readonly property int defaultPreferredSize: Kirigami.Units.gridUnit * 24

    signal exerciseFilterSelected(var exerciseModel, string title, string inheritedIconName, string selectionKind)
    signal homeRequested()
    signal settingsRequested()
    signal aboutRequested()

    interactiveResizeEnabled: true
    modal: !wideScreen
    drawerOpen: wideScreen
    resetMenuOnTriggered: false
    actions: createDrawerActions(currentSearchText)
    preferredSize: defaultPreferredSize

    onCurrentSearchTextChanged: resetMenu()

    function createDrawerActions(searchText: string): var {
        const normalizedSearchText = Core.exerciseCatalogController.normalizedText(searchText)
        const exerciseActions = createExerciseActions(exerciseModel, normalizedSearchText, "")
        if (normalizedSearchText === "" || Core.exerciseCatalogController.actionMatches(i18n("All exercises"), normalizedSearchText)) {
            return [
                allExercisesAction,
            ].concat(exerciseActions)
        }
        return exerciseActions
    }

    function createExerciseActions(exercises: var, searchText: string, inheritedIconName: string): var {
        const exerciseActions = []
        for (const exercise of exercises) {
            const actionIconName = Core.exerciseCatalogController.actionIconNameForExercise(exercise, inheritedIconName)
            const hasChildren = exercise.children !== undefined && exercise.children.length > 0
            const exerciseChildren = hasChildren ? createExerciseActions(exercise.children, searchText, actionIconName) : []
            if (!hasChildren) {
                continue
            }
            if (searchText !== "" && !Core.exerciseCatalogController.exerciseMatchesSearch(exercise, searchText, inheritedIconName)) {
                continue
            }

            exerciseActions.push(exerciseActionComponent.createObject(drawer, {
                actionChildren: exerciseChildren,
                actionIconName: actionIconName,
                exercise: exercise,
            }))
        }
        return exerciseActions
    }

    header: Kirigami.AbstractApplicationHeader {
        contentItem: Kirigami.SearchField {
            id: searchField

            anchors {
                left: parent.left
                right: parent.right
            }

            objectName: "searchField"
            focus: drawer.wideScreen && !Kirigami.InputMethod.willShowOnActive
            placeholderText: i18n("Search…")
            onTextChanged: drawer.currentSearchText = text
        }
    }

    topContent: [
        Image {
            readonly property real preferredIconSize: Kirigami.Units.gridUnit * 7

            source: "qrc:/qml/images/minuet-icon.png"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            sourceSize.width: 128
            sourceSize.height: 128
            Accessible.ignored: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: preferredIconSize
            Layout.preferredHeight: preferredIconSize
        },

        Kirigami.Heading {
            text: i18n("Welcome to Minuet")
            level: 1
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
        },

        QQC2.Label {
            text: i18n("Practice ear training with exercises for intervals, chords, rhythm, scales, and more.")
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            horizontalAlignment: Qt.AlignHCenter
        },

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.topMargin: 2 * Kirigami.Units.largeSpacing
        },

        ActionListItem {
            action: Kirigami.Action {
                text: i18n("Home")
                icon.name: "go-home"
                onTriggered: {
                    drawer.homeRequested()
                    if (drawer.modal) {
                        drawer.close()
                    }
                }
            }
        },

        ActionListItem {
            action: Kirigami.Action {
                text: i18n("Settings")
                icon.name: "settings-configure"
                checked: drawer.currentExerciseSelection?.kind === "settings"
                onTriggered: {
                    drawer.settingsRequested()
                    if (drawer.modal) {
                        drawer.close()
                    }
                }
            }
        },

        ActionListItem {
            action: Kirigami.Action {
                text: i18n("About")
                icon.name: "help-about-symbolic"
                onTriggered: {
                    drawer.aboutRequested()
                    if (drawer.modal) {
                        drawer.close()
                    }
                }
            }
        },

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.topMargin: 2 * Kirigami.Units.largeSpacing
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
        }
    ]

    Kirigami.Action {
        id: allExercisesAction

        checked: drawer.currentExerciseSelection?.kind === "all"
        text: i18n("All exercises")
        icon.name: "view-list-details"
        onTriggered: {
            drawer.exerciseFilterSelected(drawer.exerciseModel, text, "", "all")
            if (drawer.modal) {
                drawer.close()
            }
        }
    }

    Component {
        id: exerciseActionComponent

        Kirigami.Action {
            required property var exercise
            required property var actionChildren
            property string actionIconName: ""

            children: actionChildren
            checked: drawer.currentExerciseSelection?.kind === "category"
                && drawer.currentExerciseSelection.exercise === exercise
            text: exercise ? i18nc("technical term, do you have a musician friend?", exercise.name) : ""
            icon.name: actionIconName
            onTriggered: {
                drawer.exerciseFilterSelected([exercise], text, actionIconName, "category")
                if (drawer.modal) {
                    drawer.close()
                }
            }
        }
    }
}
