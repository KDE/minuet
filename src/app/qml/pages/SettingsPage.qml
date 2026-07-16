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

    function microphoneInputDeviceIndex(deviceId: string): int {
        let defaultIndex = -1;
        for (let i = 0; i < internal.microphoneInputDevicesModel.length; ++i) {
            if (internal.microphoneInputDevicesModel[i].id === deviceId) {
                return i;
            }
            if (internal.microphoneInputDevicesModel[i].isDefault) {
                defaultIndex = i;
            }
        }
        return defaultIndex >= 0 ? defaultIndex : internal.microphoneInputDevicesModel.length > 0 ? 0 : -1;
    }
    function syncSelectionFromController(): void {
        if (!Core.soundController) {
            internal.selectedMelodicGroup = -1;
            return;
        }

        internal.selectedMelodicGroup = Core.instrumentCatalogController.melodicGroupIndex(internal.groupsModel, Core.settingsController.instrumentGroup) >= 0 ? Core.settingsController.instrumentGroup : Core.instrumentCatalogController.melodicGroupForInstrument(internal.groupsModel, internal.instrumentsModel, Core.settingsController.instrument);
        if (internal.selectedMelodicGroup !== Core.settingsController.instrumentGroup) {
            Core.settingsController.instrumentGroup = internal.selectedMelodicGroup;
        }
        groupSelector.currentIndex = Core.instrumentCatalogController.melodicGroupIndex(internal.groupsModel, internal.selectedMelodicGroup);
        melodicInstrumentSelector.currentIndex = Core.instrumentCatalogController.melodicInstrumentIndex(internal.instrumentsForGroupModel, Core.settingsController.instrument);
        rhythmInstrumentSelector.currentIndex = Core.instrumentCatalogController.rhythmInstrumentIndex(internal.rhythmInstrumentsModel, Core.settingsController.rhythmInstrument);
    }

    title: i18n("Settings")

    Component.onCompleted: root.syncSelectionFromController()

    QtObject {
        id: internal

        property bool advancedExpanded: false
        readonly property real formDelegateHorizontalPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
        readonly property var groupsModel: Core.soundController ? Core.soundController.instrumentGroups : []
        readonly property string hideAdvancedSettingsText: i18n("Hide advanced settings")
        readonly property var instrumentsForGroupModel: Core.instrumentCatalogController.melodicInstrumentsForGroup(internal.instrumentsModel, internal.selectedMelodicGroup)
        readonly property var instrumentsModel: Core.soundController ? Core.soundController.instruments : []
        readonly property var microphoneInputDevicesModel: Core.microphoneInputController ? Core.microphoneInputController.inputDevices : []
        readonly property var rhythmInstrumentsModel: Core.soundController ? Core.soundController.rhythmInstruments : []
        property int selectedMelodicGroup: -1
        readonly property string showAdvancedSettingsText: i18n("Show advanced settings")
    }
    Connections {
        function onInstrumentChanged(): void {
            root.syncSelectionFromController();
        }
        function onInstrumentGroupsChanged(): void {
            Qt.callLater(root.syncSelectionFromController);
        }
        function onInstrumentsChanged(): void {
            Qt.callLater(root.syncSelectionFromController);
        }
        function onRhythmInstrumentChanged(): void {
            root.syncSelectionFromController();
        }
        function onRhythmInstrumentsChanged(): void {
            Qt.callLater(root.syncSelectionFromController);
        }

        target: Core.soundController
    }
    Connections {
        function onInstrumentChanged(): void {
            root.syncSelectionFromController();
        }
        function onInstrumentGroupChanged(): void {
            root.syncSelectionFromController();
        }
        function onRhythmInstrumentChanged(): void {
            root.syncSelectionFromController();
        }

        target: Core.settingsController
    }
    FormCard.FormHeader {
        title: i18n("Practice")
    }
    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null
            enabled: Core.soundController !== null

            contentItem: SettingsSlider {
                from: 30
                label: i18n("Exercise speed")
                suffix: i18n("bpm")
                to: 240
                value: Core.settingsController.exerciseSpeed

                onMoved: function (value) {
                    Core.settingsController.exerciseSpeed = value;
                }
            }
        }
        FormCard.AbstractFormDelegate {
            background: null
            enabled: Core.soundController !== null

            contentItem: SettingsSlider {
                from: 30
                label: i18n("Rhythm tempo")
                suffix: i18n("bpm")
                to: 240
                value: Core.settingsController.rhythmTempo

                onMoved: function (value) {
                    Core.settingsController.rhythmTempo = value;
                }
            }
        }
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: SettingsSlider {
                from: 4
                label: i18n("Number of rhythm patterns")
                to: 16
                value: Core.settingsController.rhythmPatternCount

                onMoved: function (value) {
                    Core.settingsController.rhythmPatternCount = value;
                }
            }
        }
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: SettingsSlider {
                from: 5
                label: i18n("Number of exercises")
                to: 20
                value: Core.settingsController.testExerciseCount

                onMoved: function (value) {
                    Core.settingsController.testExerciseCount = value;
                }
            }
        }
    }
    FormCard.FormHeader {
        title: i18n("Sound")
    }
    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null
            enabled: Core.soundController !== null

            contentItem: SettingsSlider {
                from: 0
                label: i18n("Volume")
                suffix: "%"
                to: 200
                value: Core.settingsController.volume

                onMoved: function (value) {
                    Core.settingsController.volume = value;
                }
            }
        }
        FormCard.FormTextDelegate {
            description: i18n("The active sound controller did not report any General MIDI bank 0 instruments.")
            icon.name: "dialog-warning-symbolic"
            text: i18n("No melodic instruments available")
            visible: internal.groupsModel.length === 0
        }
        FormCard.FormTextDelegate {
            description: i18n("Used for scales, intervals, and chords.")
            text: i18n("Melodic Exercises")
            visible: internal.groupsModel.length > 0
        }
        FormCard.AbstractFormDelegate {
            background: null
            visible: internal.groupsModel.length > 0

            contentItem: SettingsComboBox {
                id: groupSelector

                currentIndex: Core.instrumentCatalogController.melodicGroupIndex(internal.groupsModel, internal.selectedMelodicGroup)
                label: i18n("Instrument group:")
                model: internal.groupsModel
                textRole: "name"
                valueRole: "id"

                onActivated: function (currentValue, currentIndex) {
                    internal.selectedMelodicGroup = currentValue;
                    Core.settingsController.instrumentGroup = currentValue;
                    melodicInstrumentSelector.currentIndex = internal.instrumentsForGroupModel.length > 0 ? 0 : -1;
                    if (melodicInstrumentSelector.currentIndex >= 0) {
                        Core.settingsController.instrument = internal.instrumentsForGroupModel[melodicInstrumentSelector.currentIndex].program;
                    }
                }
            }
        }
        FormCard.AbstractFormDelegate {
            background: null
            visible: internal.groupsModel.length > 0

            contentItem: SettingsComboBox {
                id: melodicInstrumentSelector

                currentIndex: Core.instrumentCatalogController.melodicInstrumentIndex(internal.instrumentsForGroupModel, Core.settingsController.instrument)
                label: i18n("Instrument:")
                model: internal.instrumentsForGroupModel
                textRole: "displayName"
                valueRole: "program"

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.instrumentGroup = internal.selectedMelodicGroup;
                    Core.settingsController.instrument = currentValue;
                }
            }
        }
        FormCard.FormDelegateSeparator {
            visible: internal.groupsModel.length > 0 && internal.rhythmInstrumentsModel.length > 0
        }
        FormCard.FormTextDelegate {
            description: i18n("Used for rhythm figures. The count-in keeps its own sound.")
            text: i18n("Rhythmic Exercises")
            visible: internal.rhythmInstrumentsModel.length > 0
        }
        FormCard.AbstractFormDelegate {
            background: null
            visible: internal.rhythmInstrumentsModel.length > 0

            contentItem: SettingsComboBox {
                id: rhythmInstrumentSelector

                currentIndex: Core.instrumentCatalogController.rhythmInstrumentIndex(internal.rhythmInstrumentsModel, Core.settingsController.rhythmInstrument)
                label: i18n("Percussion sound:")
                model: internal.rhythmInstrumentsModel
                textRole: "displayName"
                valueRole: "key"

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.rhythmInstrument = currentValue;
                }
            }
        }
    }
    FormCard.FormHeader {
        title: i18n("Microphone")
    }
    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null
            visible: internal.microphoneInputDevicesModel.length > 1

            contentItem: SettingsComboBox {
                currentIndex: root.microphoneInputDeviceIndex(Core.settingsController.microphoneInputDeviceId)
                label: i18n("Input device")
                model: internal.microphoneInputDevicesModel
                textRole: "displayName"
                valueRole: "id"

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.microphoneInputDeviceId = currentValue;
                }
            }
        }
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: SettingsComboBox {
                currentIndex: Core.settingsController.singingVoiceClass
                label: i18n("Voice class")
                model: [i18n("Soprano"), i18n("Alto"), i18n("Tenor"), i18n("Bass")]

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.singingVoiceClass = currentIndex;
                }
            }
        }
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: SettingsSlider {
                description: i18n("Larger values accept claps farther from the beat; smaller values require tighter timing.")
                from: 5
                label: i18n("Timing tolerance")
                suffix: "%"
                to: 100
                value: Core.settingsController.clappingCorrectnessTolerancePercent

                onMoved: function (value) {
                    Core.settingsController.clappingCorrectnessTolerancePercent = value;
                }
            }
        }
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: SettingsSlider {
                description: i18n("Larger values accept notes farther from the target pitch; smaller values require more accurate singing.")
                from: 10
                label: i18n("Pitch tolerance")
                suffix: i18n("cents")
                to: 49
                value: Core.settingsController.singingPitchToleranceCents

                onMoved: function (value) {
                    Core.settingsController.singingPitchToleranceCents = value;
                }
            }
        }
        FormCard.FormTextDelegate {
            description: i18n("Keep the room quiet while calibrating silence. Recalibrate when the microphone or room noise changes.")
            text: i18n("Calibration")
        }
    }
    FormCard.FormHeader {
        title: i18n("Advanced")
    }
    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Button {
                        id: showAdvancedSettingsButtonMetrics

                        icon.name: "go-down-symbolic"
                        text: internal.showAdvancedSettingsText
                        visible: false
                    }
                    QQC2.Button {
                        id: hideAdvancedSettingsButtonMetrics

                        icon.name: "go-up-symbolic"
                        text: internal.hideAdvancedSettingsText
                        visible: false
                    }
                    QQC2.Button {
                        id: advancedToggleButton

                        Layout.alignment: Qt.AlignLeft
                        Layout.preferredWidth: Math.max(showAdvancedSettingsButtonMetrics.implicitWidth, hideAdvancedSettingsButtonMetrics.implicitWidth)
                        icon.name: internal.advancedExpanded ? "go-up-symbolic" : "go-down-symbolic"
                        text: internal.advancedExpanded ? internal.hideAdvancedSettingsText : internal.showAdvancedSettingsText

                        onClicked: internal.advancedExpanded = !internal.advancedExpanded
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        color: Kirigami.Theme.disabledTextColor
                        text: i18n("Algorithms and detection thresholds for difficult microphones or rooms.")
                        wrapMode: Text.WordWrap
                    }
                }
                Loader {
                    id: advancedLoader

                    Layout.fillWidth: true
                    Layout.maximumHeight: internal.advancedExpanded ? implicitHeight : 0
                    Layout.minimumHeight: internal.advancedExpanded ? implicitHeight : 0
                    Layout.preferredHeight: internal.advancedExpanded ? implicitHeight : 0
                    active: internal.advancedExpanded
                    sourceComponent: advancedSettingsComponent
                    visible: internal.advancedExpanded
                }
            }
        }
    }
    Component {
        id: advancedSettingsComponent

        ColumnLayout {
            spacing: 0
            width: advancedLoader.width

            AdvancedSettingsSection {
                description: i18n("Used for rhythm clapping exercises.")
                text: i18n("Clapping detection")
            }
            AdvancedSettingsComboBox {
                currentIndex: Core.settingsController.clappingOnsetMethod
                label: i18n("Onset method")
                model: ["complex", "hfc", "energy", "specflux", "phase", "specdiff", "kl", "mkl"]

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.clappingOnsetMethod = currentIndex;
                }
            }
            AdvancedSettingsSlider {
                decimals: 2
                from: 0.01
                label: i18n("Onset threshold")
                stepSize: 0.01
                to: 1.0
                value: Core.settingsController.clappingOnsetThreshold

                onMoved: function (value) {
                    Core.settingsController.clappingOnsetThreshold = value;
                }
            }
            AdvancedSettingsSlider {
                decimals: 3
                from: 0
                label: i18n("Input gate")
                stepSize: 0.001
                to: 0.25
                value: Core.settingsController.clappingInputGateLevel

                onMoved: function (value) {
                    Core.settingsController.clappingInputGateLevel = value;
                }
            }
            AdvancedSettingsSlider {
                decimals: 3
                from: 0
                label: i18n("Minimum onset strength")
                stepSize: 0.001
                to: 1
                value: Core.settingsController.clappingMinimumOnsetStrength

                onMoved: function (value) {
                    Core.settingsController.clappingMinimumOnsetStrength = value;
                }
            }
            FormCard.FormDelegateSeparator {
                Layout.bottomMargin: internal.formDelegateHorizontalPadding
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.topMargin: internal.formDelegateHorizontalPadding
            }
            AdvancedSettingsSection {
                description: i18n("Used for pitch analysis and note-entry timing in singing exercises.")
                text: i18n("Singing detection")
            }
            AdvancedSettingsComboBox {
                currentIndex: Core.settingsController.singingPitchMethod
                label: i18n("Pitch method")
                model: ["yinfft", "yin", "yinfast", "mcomb", "schmitt", "specacf", "fcomb"]

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.singingPitchMethod = currentIndex;
                }
            }
            AdvancedSettingsSlider {
                decimals: 2
                from: 0
                label: i18n("Pitch confidence")
                stepSize: 0.01
                to: 0.95
                value: Core.settingsController.singingMinimumPitchConfidence

                onMoved: function (value) {
                    Core.settingsController.singingMinimumPitchConfidence = value;
                }
            }
            AdvancedSettingsSlider {
                decimals: 3
                from: 0
                label: i18n("Input gate")
                stepSize: 0.001
                to: 0.25
                value: Core.settingsController.singingInputGateLevel

                onMoved: function (value) {
                    Core.settingsController.singingInputGateLevel = value;
                }
            }
            AdvancedSettingsSlider {
                from: 1
                label: i18n("Stable pitch frames")
                to: 10
                value: Core.settingsController.singingRequiredStablePitchFrames

                onMoved: function (value) {
                    Core.settingsController.singingRequiredStablePitchFrames = value;
                }
            }
            AdvancedSettingsComboBox {
                currentIndex: Core.settingsController.singingScoringMode
                label: i18n("Scoring mode")
                model: [i18n("Pitch primary"), i18n("Pitch + timing")]

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.singingScoringMode = currentIndex;
                }
            }
            QQC2.CheckBox {
                Layout.bottomMargin: internal.formDelegateHorizontalPadding
                Layout.fillWidth: true
                Layout.topMargin: internal.formDelegateHorizontalPadding
                checked: Core.settingsController.singingDisregardOctaveDifference
                text: i18n("Disregard octave difference")

                onToggled: Core.settingsController.singingDisregardOctaveDifference = checked
            }
            QQC2.Button {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: internal.formDelegateHorizontalPadding
                icon.name: "edit-reset-symbolic"
                text: i18n("Reset to Defaults")

                onClicked: Core.settingsController.resetAdvancedSettingsToDefaults()
            }
        }
    }
}
