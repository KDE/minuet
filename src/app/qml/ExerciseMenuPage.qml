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

    readonly property var exerciseList: Core.exerciseCatalogController.collectExercises(exerciseModel, inheritedIconName)
    property var exerciseModel: []
    property string inheritedIconName: ""
    property string pathText: title

    function exerciseOptionHasTag(exercise: var, tag: string): bool {
        const options = exercise.options || [];
        for (const option of options) {
            const tags = option.tags || [];
            if (tags.indexOf(tag) >= 0) {
                return true;
            }
        }
        return false;
    }
    function openExercise(exercise: var, iconName: string): void {
        const practiceMode = practiceModeForExercise(exercise);
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
        practicePage.practiceSelected.connect(function (selectedExercise, selectedIconName) {
            page.openExercisePage(selectedExercise, selectedIconName);
        });
        applicationWindow().pageStack.push(practicePage);
    }
    function practiceModeForExercise(exercise: var): string {
        if (exercise.playMode === "rhythm") {
            return "rhythm";
        }
        if (exercise.playMode !== "scale") {
            return "";
        }
        if (exerciseOptionHasTag(exercise, "interval")) {
            return "interval";
        }
        if (exerciseOptionHasTag(exercise, "scale")) {
            return "scale";
        }
        return "";
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    title: exerciseList.length > 0 ? i18np("%2 - %1 item", "%2 - %1 items", exerciseList.length, pathText) : pathText

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
        model: page.exerciseList

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
