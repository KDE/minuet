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
import org.kde.kirigami.layouts as KirigamiLayouts

Kirigami.Page {
    id: page

    padding: 0

    property var exerciseModel: []
    property string inheritedIconName: ""
    property string pathText: title
    readonly property bool isRootMenuPage: pathText === title
    readonly property bool isLeftPanelPage: KirigamiLayouts.ColumnView.view !== null
        && applicationWindow().pageStack.columnView.columnResizeMode !== KirigamiLayouts.ColumnView.SingleColumn
        && KirigamiLayouts.ColumnView.index < applicationWindow().pageStack.currentIndex

    function resolvedIconName(exercise) {
        const iconName = exercise._icon ? exercise._icon : inheritedIconName
        if (iconName === "") {
            return ""
        }
        return iconName.startsWith("qrc:/") ? iconName : "qrc:/icons/22-actions-" + iconName
    }

    function openExercise(exercise, iconName) {
        const exerciseTitle = i18nc("technical term, do you have a musician friend?", exercise.name)
        if (exercise.children !== undefined) {
            applicationWindow().pageStack.push(Qt.resolvedUrl("ExerciseMenuPage.qml"), {
                title: exerciseTitle,
                exerciseModel: exercise.children,
                inheritedIconName: iconName,
                pathText: page.pathText + " / " + exerciseTitle,
            })
            return
        }

        applicationWindow().currentExercise = exercise
        applicationWindow().pageStack.push(exercisePageComponent, {
            title: exerciseTitle,
            currentExercise: exercise,
            pathText: page.pathText + " / " + exerciseTitle,
        })
    }

    ColumnLayout {
        id: pageContent

        anchors.fill: parent
        anchors.margins: page.isLeftPanelPage ? 0 : Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Image {
            id: drawerImage

            readonly property real targetWidth: page.isLeftPanelPage ? pageContent.width : Math.min(pageContent.width, Kirigami.Units.gridUnit * 16)
            readonly property real aspectRatio: implicitWidth > 0 ? implicitHeight / implicitWidth : 0.35

            source: "qrc:/qml/images/minuet-drawer.png"
            fillMode: Image.PreserveAspectFit
            visible: page.isLeftPanelPage || page.isRootMenuPage
            sourceSize.width: targetWidth
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: page.isLeftPanelPage
            Layout.preferredWidth: targetWidth
            Layout.preferredHeight: visible ? targetWidth * aspectRatio : 0
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.ToolButton {
                text: i18n("Back")
                icon.name: "go-previous"
                display: QQC2.AbstractButton.IconOnly
                visible: applicationWindow().pageStack.depth > 1
                enabled: visible
                onClicked: applicationWindow().pageStack.pop()
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
            }

            Kirigami.Heading {
                text: page.pathText
                level: 2
                elide: Text.ElideLeft
                maximumLineCount: 1
                Layout.fillWidth: true
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: cardsLayout.height
            clip: true

            Kirigami.CardsLayout {
                id: cardsLayout

                width: parent.width
                rowSpacing: Kirigami.Units.largeSpacing
                columnSpacing: Kirigami.Units.largeSpacing
                minimumColumnWidth: Kirigami.Units.gridUnit * 11
                maximumColumns: Math.max(1, Math.floor(width / (minimumColumnWidth + columnSpacing)))

                Repeater {
                    model: page.exerciseModel

                    Kirigami.AbstractCard {
                        id: exerciseCard

                        required property var modelData

                        readonly property string iconName: page.resolvedIconName(modelData)

                        Layout.fillWidth: true
                        Layout.minimumWidth: cardsLayout.minimumColumnWidth
                        Layout.minimumHeight: Kirigami.Units.gridUnit * 7

                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: exerciseCard.iconName
                                visible: exerciseCard.iconName !== ""
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                            }

                            Kirigami.Heading {
                                text: i18nc("technical term, do you have a musician friend?", exerciseCard.modelData.name)
                                level: 3
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: page.openExercise(modelData, iconName)
                    }
                }
            }

            QQC2.ScrollIndicator.vertical: QQC2.ScrollIndicator { active: true }
        }
    }

    Component {
        id: exercisePageComponent

        Kirigami.Page {
            id: exercisePage

            property var currentExercise
            property string pathText: title

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.ToolButton {
                        text: i18n("Back")
                        icon.name: "go-previous"
                        display: QQC2.AbstractButton.IconOnly
                        enabled: applicationWindow().pageStack.depth > 1
                        onClicked: applicationWindow().pageStack.pop()
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                    }

                    Kirigami.Heading {
                        text: exercisePage.pathText
                        level: 2
                        elide: Text.ElideLeft
                        maximumLineCount: 1
                        Layout.fillWidth: true
                    }
                }

                ExerciseView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentExercise: exercisePage.currentExercise
                }
            }
        }
    }
}
