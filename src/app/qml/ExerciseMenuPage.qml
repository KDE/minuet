// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

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
    readonly property var exerciseList: Core.exerciseCatalogController.collectExercises(exerciseModel, inheritedIconName)

    title: exerciseList.length > 0 ? i18np("%2 - %1 item", "%2 - %1 items", exerciseList.length, pathText) : pathText

    function openExercise(exercise: var, iconName: string): void {
        const exerciseTitle = i18nc("technical term, do you have a musician friend?", exercise.name)
        applicationWindow().currentExercise = exercise
        const exercisePage = exercisePageComponent.createObject(applicationWindow().pageStack, {
            title: exerciseTitle,
            currentExercise: exercise,
            pathText: page.pathText + " / " + exerciseTitle,
        })
        applicationWindow().pageStack.push(exercisePage)
    }

    Component {
        id: exercisePageComponent

        ExercisePage {}
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
                                    text: i18nc("technical term, do you have a musician friend?", Core.exerciseCatalogController.exerciseDescription(exerciseCard.modelData.exercise))
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
