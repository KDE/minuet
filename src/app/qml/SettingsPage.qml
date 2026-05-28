// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormCardPage {
    id: root

    title: i18n("Settings")

    property int selectedMelodicGroup: -1
    readonly property string instrumentGroupsJson: Core.soundController ? Core.soundController.instrumentGroupsJson || "[]" : "[]"
    readonly property string instrumentsJson: Core.soundController ? Core.soundController.instrumentsJson || "[]" : "[]"
    readonly property string rhythmInstrumentsJson: Core.soundController ? Core.soundController.rhythmInstrumentsJson || "[]" : "[]"
    readonly property var groupsModel: Core.instrumentCatalogController.instrumentGroups(instrumentGroupsJson)
    readonly property var instrumentsModel: Core.instrumentCatalogController.melodicInstruments(instrumentsJson)
    readonly property var rhythmInstrumentsModel: Core.instrumentCatalogController.rhythmInstruments(rhythmInstrumentsJson)
    readonly property var instrumentsForGroupModel: Core.instrumentCatalogController.melodicInstrumentsForGroup(instrumentsModel, selectedMelodicGroup)

    function syncSelectionFromController(): void {
        if (!Core.soundController) {
            root.selectedMelodicGroup = -1
            return
        }

        root.selectedMelodicGroup = Core.instrumentCatalogController.melodicGroupIndex(groupsModel, Core.settingsController.instrumentGroup) >= 0
            ? Core.settingsController.instrumentGroup
            : Core.instrumentCatalogController.melodicGroupForInstrument(groupsModel, instrumentsModel, Core.settingsController.instrument)
        if (root.selectedMelodicGroup !== Core.settingsController.instrumentGroup) {
            Core.settingsController.instrumentGroup = root.selectedMelodicGroup
        }
        groupSelector.currentIndex = Core.instrumentCatalogController.melodicGroupIndex(groupsModel, root.selectedMelodicGroup)
        melodicInstrumentSelector.currentIndex = Core.instrumentCatalogController.melodicInstrumentIndex(instrumentsForGroupModel, Core.settingsController.instrument)
        rhythmInstrumentSelector.currentIndex = Core.instrumentCatalogController.rhythmInstrumentIndex(rhythmInstrumentsModel, Core.settingsController.rhythmInstrument)
    }

    Connections {
        target: Core.soundController

        function onInstrumentGroupsChanged(): void {
            Qt.callLater(root.syncSelectionFromController)
        }

        function onInstrumentsChanged(): void {
            Qt.callLater(root.syncSelectionFromController)
        }

        function onRhythmInstrumentsChanged(): void {
            Qt.callLater(root.syncSelectionFromController)
        }

        function onInstrumentChanged(): void {
            root.syncSelectionFromController()
        }

        function onRhythmInstrumentChanged(): void {
            root.syncSelectionFromController()
        }
    }

    Connections {
        target: Core.settingsController

        function onInstrumentGroupChanged(): void {
            root.syncSelectionFromController()
        }

        function onInstrumentChanged(): void {
            root.syncSelectionFromController()
        }

        function onRhythmInstrumentChanged(): void {
            root.syncSelectionFromController()
        }
    }

    FormCard.FormHeader {
        title: i18n("Player")
    }

    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            enabled: Core.soundController !== null
            background: null

            contentItem: ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("Volume")
                        elide: Text.ElideRight
                    }

                    QQC2.Label {
                        text: i18n("%1%", Math.round(volumeSlider.value))
                        color: Kirigami.Theme.disabledTextColor
                    }
                }

                QQC2.Slider {
                    id: volumeSlider

                    Layout.fillWidth: true
                    from: 0
                    to: 200
                    stepSize: 1
                    snapMode: QQC2.Slider.SnapAlways
                    value: Core.settingsController.volume
                    onMoved: {
                        Core.settingsController.volume = Math.round(value)
                    }
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("SoundFont")
    }

    FormCard.FormCard {
        FormCard.FormTextDelegate {
            text: i18n("No melodic instruments available")
            description: i18n("The active sound controller did not report any General MIDI bank 0 instruments.")
            icon.name: "dialog-warning-symbolic"
            visible: groupsModel.length === 0
        }

        FormCard.FormTextDelegate {
            text: i18n("Melodic Exercises")
            description: i18n("Used for scales, intervals, and chords.")
            visible: groupsModel.length > 0
        }

        FormCard.FormComboBoxDelegate {
            id: groupSelector

            text: i18n("Instrument group:")
            textRole: "name"
            valueRole: "id"
            model: groupsModel
            visible: groupsModel.length > 0
            onActivated: {
                root.selectedMelodicGroup = currentValue
                Core.settingsController.instrumentGroup = currentValue
                melodicInstrumentSelector.currentIndex = instrumentsForGroupModel.length > 0 ? 0 : -1
                if (melodicInstrumentSelector.currentIndex >= 0) {
                    Core.settingsController.instrument = instrumentsForGroupModel[melodicInstrumentSelector.currentIndex].program
                }
            }
        }

        FormCard.FormComboBoxDelegate {
            id: melodicInstrumentSelector

            text: i18n("Instrument:")
            textRole: "displayName"
            valueRole: "program"
            model: instrumentsForGroupModel
            visible: groupsModel.length > 0
            onActivated: {
                Core.settingsController.instrumentGroup = root.selectedMelodicGroup
                Core.settingsController.instrument = currentValue
            }
        }

        FormCard.FormDelegateSeparator {
            visible: groupsModel.length > 0 && rhythmInstrumentsModel.length > 0
        }

        FormCard.FormTextDelegate {
            text: i18n("Rhythmic Exercises")
            description: i18n("Used for rhythm figures. The count-in keeps its own sound.")
            visible: rhythmInstrumentsModel.length > 0
        }

        FormCard.FormComboBoxDelegate {
            id: rhythmInstrumentSelector

            text: i18n("Percussion sound:")
            textRole: "displayName"
            valueRole: "key"
            model: rhythmInstrumentsModel
            visible: rhythmInstrumentsModel.length > 0
            onActivated: {
                Core.settingsController.rhythmInstrument = currentValue
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Rhythm Exercises")
    }

    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Number of rhythm patterns")
                    elide: Text.ElideRight
                }

                QQC2.SpinBox {
                    from: 4
                    to: 16
                    value: Core.settingsController.rhythmPatternCount
                    onValueModified: Core.settingsController.rhythmPatternCount = value
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Tests")
    }

    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Number of exercises")
                    elide: Text.ElideRight
                }

                QQC2.SpinBox {
                    from: 5
                    to: 20
                    value: Core.settingsController.testExerciseCount
                    onValueModified: Core.settingsController.testExerciseCount = value
                }
            }
        }
    }

    Component.onCompleted: root.syncSelectionFromController()
}
