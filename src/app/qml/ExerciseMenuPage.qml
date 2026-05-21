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

Kirigami.Page {
    id: page

    padding: 0

    property var exerciseModel: []
    property string inheritedIconName: ""
    property string pathText: title
    readonly property var exerciseList: collectExercises(exerciseModel, inheritedIconName)

    title: exerciseList.length > 0 ? i18np("%2 - %1 item", "%2 - %1 items", exerciseList.length, pathText) : pathText

    function iconNameForExercise(exercise: var, inheritedIconName: string): string {
        const iconName = exercise._icon ? exercise._icon : inheritedIconName
        if (iconName === "") {
            return "view-list-details"
        }
        return iconName.startsWith("qrc:/") ? iconName : "qrc:/icons/22-actions-" + iconName
    }

    function collectExercises(exercises: var, inheritedIconName: string): var {
        const collectedExercises = []
        for (const exercise of exercises) {
            collectExercise(exercise, inheritedIconName, collectedExercises)
        }
        return collectedExercises
    }

    function collectExercise(exercise: var, inheritedIconName: string, collectedExercises: var): void {
        const iconName = iconNameForExercise(exercise, inheritedIconName)
        if (exercise.children !== undefined) {
            for (const childExercise of exercise.children) {
                collectExercise(childExercise, iconName, collectedExercises)
            }
            return
        }
        collectedExercises.push({
            exercise: exercise,
            iconName: iconName,
        })
    }

    function exerciseDescription(exercise: var): string {
        if (exercise.userMessage !== undefined && exercise.userMessage !== "") {
            return exercise.userMessage
        }

        let description = i18n("Practice identifying this exercise by ear.")
        if (exercise.playMode === "rhythm") {
            description = i18n("Practice rhythm recognition.")
        } else if (exercise.playMode === "scale") {
            description = i18n("Identify the scale by ear.")
        } else if (exercise.playMode === "chord") {
            description = i18n("Identify the chord or interval by ear.")
        }

        if (exercise.options !== undefined && exercise.options.length > 0) {
            return i18n("%1 Includes %2 possible answers.", description, exercise.options.length)
        }
        return description
    }

    function openExercise(exercise: var, iconName: string): void {
        const exerciseTitle = i18nc("technical term, do you have a musician friend?", exercise.name)
        applicationWindow().currentExercise = exercise
        applicationWindow().pageStack.push(Qt.resolvedUrl("ExercisePage.qml"), {
            title: exerciseTitle,
            currentExercise: exercise,
            pathText: page.pathText + " / " + exerciseTitle,
        })
    }

    ColumnLayout {
        id: pageContent

        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: exerciseListLayout.height
            clip: true

            ColumnLayout {
                id: exerciseListLayout

                width: parent.width
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: page.exerciseList

                    Kirigami.AbstractCard {
                        id: exerciseCard

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.minimumHeight: Kirigami.Units.gridUnit * 5

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing

                            Kirigami.Icon {
                                source: exerciseCard.modelData.iconName
                                visible: exerciseCard.modelData.iconName !== ""
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Heading {
                                    text: i18nc("technical term, do you have a musician friend?", exerciseCard.modelData.exercise.name)
                                    level: 3
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }

                                QQC2.Label {
                                    text: page.exerciseDescription(exerciseCard.modelData.exercise)
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: Kirigami.Theme.disabledTextColor
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        onClicked: page.openExercise(modelData.exercise, modelData.iconName)
                    }
                }
            }

            QQC2.ScrollIndicator.vertical: QQC2.ScrollIndicator { active: true }
        }
    }
}
