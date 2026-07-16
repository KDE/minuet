// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page

    property var exerciseModel: []
    property string inheritedIconName: ""
    property string pathText: title

    function openExercise(exercise: var, iconName: string): void {
        const practiceMode = Core.exerciseCatalogController.practiceModeForExercise(exercise);
        if (practiceMode.length > 0) {
            openPracticeModePage(exercise, iconName, practiceMode);
            return;
        }
        openExercisePage(exercise, iconName);
    }
    function openExercisePage(exercise: var, iconName: string): void {
        const exerciseTitle = i18nc("technical term, do you have a musician friend?", exercise.name);
        applicationWindow().currentExercise = exercise;
        const exercisePage = exercisePageComponent.createObject(applicationWindow().pageStack, {
            title: exerciseTitle,
            currentExercise: exercise,
            currentExerciseIconName: iconName
        });
        if (exercisePage === null) {
            return;
        }
        applicationWindow().pageStack.push(exercisePage);
    }
    function openPracticeModePage(exercise: var, iconName: string, practiceMode: string): void {
        const exerciseTitle = i18nc("technical term, do you have a musician friend?", exercise.name);
        applicationWindow().currentExercise = undefined;
        const practicePage = practiceModePageComponent.createObject(applicationWindow().pageStack, {
            title: exerciseTitle,
            currentExercise: exercise,
            currentExerciseIconName: iconName,
            practiceMode: practiceMode
        });
        if (practicePage === null) {
            return;
        }
        practicePage.practiceSelected.connect(function (selectedExercise, selectedIconName) {
            page.openExercisePage(selectedExercise, selectedIconName);
        });
        applicationWindow().pageStack.push(practicePage);
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    title: internal.exerciseList.length > 0 ? i18np("%2 - %1 item", "%2 - %1 items", internal.exerciseList.length, pathText) : pathText

    QtObject {
        id: internal

        readonly property var exerciseList: Core.exerciseCatalogController.collectExercises(page.exerciseModel, page.inheritedIconName)
    }
    Component {
        id: exercisePageComponent

        ExercisePage {
        }
    }
    Component {
        id: practiceModePageComponent

        PracticeModePage {
        }
    }
    Kirigami.CardsListView {
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        model: internal.exerciseList

        delegate: Kirigami.AbstractCard {
            id: exerciseCard

            required property var modelData

            height: Math.max(implicitHeight, Kirigami.Units.gridUnit * 5)
            showClickFeedback: true

            contentItem: RowLayout {
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    source: exerciseCard.modelData.iconName
                    visible: exerciseCard.modelData.iconName !== ""
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        level: 3
                        maximumLineCount: 1
                        text: i18nc("technical term, do you have a musician friend?", exerciseCard.modelData.exercise.name)
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        text: i18nc("technical term, do you have a musician friend?", Core.exerciseCatalogController.exerciseDescription(exerciseCard.modelData.exercise))
                        wrapMode: Text.WordWrap
                    }
                }
            }

            onClicked: page.openExercise(modelData.exercise, modelData.iconName)
        }

        anchors {
            fill: parent
            margins: Kirigami.Units.largeSpacing
        }
    }
}
