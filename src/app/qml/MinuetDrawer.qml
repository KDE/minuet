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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.GlobalDrawer {
    id: drawer

    property var exerciseModel: []
    property bool wideScreen: false
    property string currentSearchText: ""
    readonly property int defaultPreferredSize: Kirigami.Units.gridUnit * 24

    signal exerciseFilterSelected(var exerciseModel, string title, string inheritedIconName)
    signal homeRequested()
    signal aboutRequested()

    interactiveResizeEnabled: true
    modal: !wideScreen
    drawerOpen: wideScreen
    resetMenuOnTriggered: false
    actions: createDrawerActions(currentSearchText)
    preferredSize: defaultPreferredSize

    onCurrentSearchTextChanged: resetMenu()

    function createDrawerActions(searchText) {
        const normalizedSearchText = normalizedText(searchText)
        const exerciseActions = createExerciseActions(exerciseModel, normalizedSearchText)
        if (normalizedSearchText === "" || actionMatches(i18n("All exercises"), normalizedSearchText)) {
            return [
                allExercisesActionComponent.createObject(drawer),
            ].concat(exerciseActions)
        }
        return exerciseActions
    }

    function createExerciseActions(exercises, searchText) {
        const exerciseActions = []
        for (const exercise of exercises) {
            const exerciseTitle = i18nc("technical term, do you have a musician friend?", exercise.name)
            const exerciseChildren = exercise.children !== undefined ? createExerciseActions(exercise.children, searchText) : []
            if (searchText !== "" && !actionMatches(exerciseTitle, searchText) && exerciseChildren.length === 0) {
                continue
            }

            const actionIconName = resolvedIconName(exercise)
            const exerciseAction = exerciseActionComponent.createObject(drawer, {
                exercise: exercise,
                actionIconName: actionIconName,
            })
            if (exerciseChildren.length > 0) {
                exerciseAction.children = exerciseChildren
            }
            exerciseActions.push(exerciseAction)
        }
        return exerciseActions
    }

    function normalizedText(text) {
        return text.trim().toLocaleLowerCase()
    }

    function actionMatches(actionText, searchText) {
        return normalizedText(actionText).includes(searchText)
    }

    function resolvedIconName(exercise) {
        const iconName = exercise._icon ? exercise._icon : ""
        if (iconName === "") {
            return ""
        }
        return iconName.startsWith("qrc:/") ? iconName : "qrc:/icons/22-actions-" + iconName
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
                enabled: false
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

    Component {
        id: allExercisesActionComponent

        Kirigami.Action {
            text: i18n("All exercises")
            icon.name: "view-list-details"
            onTriggered: {
                drawer.exerciseFilterSelected(drawer.exerciseModel, text, "")
                if (drawer.modal) {
                    drawer.close()
                }
            }
        }
    }

    Component {
        id: exerciseActionComponent

        Kirigami.Action {
            property var exercise
            property string actionIconName: ""

            text: exercise ? i18nc("technical term, do you have a musician friend?", exercise.name) : ""
            icon.name: actionIconName
            onTriggered: {
                drawer.exerciseFilterSelected([exercise], text, actionIconName)
                if (drawer.modal && exercise.children === undefined) {
                    drawer.close()
                }
            }
        }
    }
}
