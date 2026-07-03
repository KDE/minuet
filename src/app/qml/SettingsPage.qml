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

    property bool advancedExpanded: false
    readonly property var groupsModel: Core.instrumentCatalogController.instrumentGroups(instrumentGroupsJson)
    readonly property string hideAdvancedSettingsText: i18n("Hide advanced settings")
    readonly property string instrumentGroupsJson: Core.soundController ? Core.soundController.instrumentGroupsJson || "[]" : "[]"
    readonly property var instrumentsForGroupModel: Core.instrumentCatalogController.melodicInstrumentsForGroup(instrumentsModel, selectedMelodicGroup)
    readonly property string instrumentsJson: Core.soundController ? Core.soundController.instrumentsJson || "[]" : "[]"
    readonly property var instrumentsModel: Core.instrumentCatalogController.melodicInstruments(instrumentsJson)
    readonly property var microphoneOnsetMethods: ["complex", "hfc", "energy", "specflux", "phase", "specdiff", "kl", "mkl"]
    readonly property var microphonePitchMethods: ["yinfft", "yin", "yinfast", "mcomb", "schmitt", "specacf", "fcomb"]
    readonly property string rhythmInstrumentsJson: Core.soundController ? Core.soundController.rhythmInstrumentsJson || "[]" : "[]"
    readonly property var rhythmInstrumentsModel: Core.instrumentCatalogController.rhythmInstruments(rhythmInstrumentsJson)
    readonly property var scoringModes: [i18n("Pitch primary"), i18n("Pitch + timing")]
    property int selectedMelodicGroup: -1
    readonly property int settingLabelWidth: Kirigami.Units.gridUnit * 10
    readonly property string showAdvancedSettingsText: i18n("Show advanced settings")
    readonly property var voiceClasses: [i18n("Soprano"), i18n("Alto"), i18n("Tenor"), i18n("Bass")]

    function syncSelectionFromController(): void {
        if (!Core.soundController) {
            root.selectedMelodicGroup = -1;
            return;
        }

        root.selectedMelodicGroup = Core.instrumentCatalogController.melodicGroupIndex(groupsModel, Core.settingsController.instrumentGroup) >= 0 ? Core.settingsController.instrumentGroup : Core.instrumentCatalogController.melodicGroupForInstrument(groupsModel, instrumentsModel, Core.settingsController.instrument);
        if (root.selectedMelodicGroup !== Core.settingsController.instrumentGroup) {
            Core.settingsController.instrumentGroup = root.selectedMelodicGroup;
        }
        groupSelector.currentIndex = Core.instrumentCatalogController.melodicGroupIndex(groupsModel, root.selectedMelodicGroup);
        melodicInstrumentSelector.currentIndex = Core.instrumentCatalogController.melodicInstrumentIndex(instrumentsForGroupModel, Core.settingsController.instrument);
        rhythmInstrumentSelector.currentIndex = Core.instrumentCatalogController.rhythmInstrumentIndex(rhythmInstrumentsModel, Core.settingsController.rhythmInstrument);
    }

    title: i18n("Settings")

    Component.onCompleted: root.syncSelectionFromController()

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
            visible: groupsModel.length === 0
        }
        FormCard.FormTextDelegate {
            description: i18n("Used for scales, intervals, and chords.")
            text: i18n("Melodic Exercises")
            visible: groupsModel.length > 0
        }
        FormCard.FormComboBoxDelegate {
            id: groupSelector

            model: groupsModel
            text: i18n("Instrument group:")
            textRole: "name"
            valueRole: "id"
            visible: groupsModel.length > 0

            onActivated: {
                root.selectedMelodicGroup = currentValue;
                Core.settingsController.instrumentGroup = currentValue;
                melodicInstrumentSelector.currentIndex = instrumentsForGroupModel.length > 0 ? 0 : -1;
                if (melodicInstrumentSelector.currentIndex >= 0) {
                    Core.settingsController.instrument = instrumentsForGroupModel[melodicInstrumentSelector.currentIndex].program;
                }
            }
        }
        FormCard.FormComboBoxDelegate {
            id: melodicInstrumentSelector

            model: instrumentsForGroupModel
            text: i18n("Instrument:")
            textRole: "displayName"
            valueRole: "program"
            visible: groupsModel.length > 0

            onActivated: {
                Core.settingsController.instrumentGroup = root.selectedMelodicGroup;
                Core.settingsController.instrument = currentValue;
            }
        }
        FormCard.FormDelegateSeparator {
            visible: groupsModel.length > 0 && rhythmInstrumentsModel.length > 0
        }
        FormCard.FormTextDelegate {
            description: i18n("Used for rhythm figures. The count-in keeps its own sound.")
            text: i18n("Rhythmic Exercises")
            visible: rhythmInstrumentsModel.length > 0
        }
        FormCard.FormComboBoxDelegate {
            id: rhythmInstrumentSelector

            model: rhythmInstrumentsModel
            text: i18n("Percussion sound:")
            textRole: "displayName"
            valueRole: "key"
            visible: rhythmInstrumentsModel.length > 0

            onActivated: {
                Core.settingsController.rhythmInstrument = currentValue;
            }
        }
    }
    FormCard.FormHeader {
        title: i18n("Microphone")
    }
    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: SettingsComboBox {
                currentIndex: Core.settingsController.singingVoiceClass
                label: i18n("Voice class")
                model: root.voiceClasses

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
                        text: root.showAdvancedSettingsText
                        visible: false
                    }
                    QQC2.Button {
                        id: hideAdvancedSettingsButtonMetrics

                        icon.name: "go-up-symbolic"
                        text: root.hideAdvancedSettingsText
                        visible: false
                    }
                    QQC2.Button {
                        id: advancedToggleButton

                        Layout.alignment: Qt.AlignLeft
                        Layout.preferredWidth: Math.max(showAdvancedSettingsButtonMetrics.implicitWidth, hideAdvancedSettingsButtonMetrics.implicitWidth)
                        icon.name: root.advancedExpanded ? "go-up-symbolic" : "go-down-symbolic"
                        text: root.advancedExpanded ? root.hideAdvancedSettingsText : root.showAdvancedSettingsText

                        onClicked: root.advancedExpanded = !root.advancedExpanded
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
                    Layout.maximumHeight: root.advancedExpanded ? implicitHeight : 0
                    Layout.minimumHeight: root.advancedExpanded ? implicitHeight : 0
                    Layout.preferredHeight: root.advancedExpanded ? implicitHeight : 0
                    active: root.advancedExpanded
                    sourceComponent: advancedSettingsComponent
                    visible: root.advancedExpanded
                }
            }
        }
    }
    Component {
        id: advancedSettingsComponent

        ColumnLayout {
            width: advancedLoader.width

            SettingsSectionLabel {
                text: i18n("Clapping detection")
            }
            SettingsComboBox {
                currentIndex: Core.settingsController.clappingOnsetMethod
                label: i18n("Onset method")
                model: root.microphoneOnsetMethods

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.clappingOnsetMethod = currentIndex;
                }
            }
            SettingsSlider {
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
            SettingsSlider {
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
            SettingsSlider {
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
            SettingsSlider {
                from: -90
                label: i18n("Aubio silence")
                suffix: i18n("dB")
                to: -20
                value: Core.settingsController.clappingPitchSilenceDb

                onMoved: function (value) {
                    Core.settingsController.clappingPitchSilenceDb = value;
                }
            }
            SettingsSectionLabel {
                text: i18n("Singing detection")
            }
            SettingsComboBox {
                currentIndex: Core.settingsController.singingPitchMethod
                label: i18n("Pitch method")
                model: root.microphonePitchMethods

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.singingPitchMethod = currentIndex;
                }
            }
            SettingsComboBox {
                currentIndex: Core.settingsController.singingOnsetMethod
                label: i18n("Onset method")
                model: root.microphoneOnsetMethods

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.singingOnsetMethod = currentIndex;
                }
            }
            SettingsComboBox {
                currentIndex: Core.settingsController.singingScoringMode
                label: i18n("Scoring mode")
                model: root.scoringModes

                onActivated: function (currentValue, currentIndex) {
                    Core.settingsController.singingScoringMode = currentIndex;
                }
            }
            QQC2.CheckBox {
                Layout.fillWidth: true
                checked: Core.settingsController.singingDisregardOctaveDifference
                text: i18n("Disregard octave difference")

                onToggled: Core.settingsController.singingDisregardOctaveDifference = checked
            }
            SettingsSlider {
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
            SettingsSlider {
                from: 1
                label: i18n("Stable pitch frames")
                to: 10
                value: Core.settingsController.singingRequiredStablePitchFrames

                onMoved: function (value) {
                    Core.settingsController.singingRequiredStablePitchFrames = value;
                }
            }
            SettingsSlider {
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
            SettingsSlider {
                from: -90
                label: i18n("Aubio silence")
                suffix: i18n("dB")
                to: -20
                value: Core.settingsController.singingPitchSilenceDb

                onMoved: function (value) {
                    Core.settingsController.singingPitchSilenceDb = value;
                }
            }
            SettingsSlider {
                decimals: 2
                from: 0.01
                label: i18n("Onset threshold")
                stepSize: 0.01
                to: 1
                value: Core.settingsController.singingOnsetThreshold

                onMoved: function (value) {
                    Core.settingsController.singingOnsetThreshold = value;
                }
            }
            SettingsSlider {
                decimals: 3
                from: 0
                label: i18n("Minimum onset strength")
                stepSize: 0.001
                to: 1
                value: Core.settingsController.singingMinimumOnsetStrength

                onMoved: function (value) {
                    Core.settingsController.singingMinimumOnsetStrength = value;
                }
            }
            QQC2.Button {
                Layout.alignment: Qt.AlignRight
                icon.name: "edit-reset-symbolic"
                text: i18n("Reset to Defaults")

                onClicked: Core.settingsController.resetAdvancedSettingsToDefaults()
            }
        }
    }

    component SettingsComboBox: ColumnLayout {
        id: comboRow

        property int currentIndex: -1
        property string description: ""
        property string label: ""
        property var model: []
        property string textRole: ""
        property string valueRole: ""

        signal activated(var currentValue, int currentIndex)

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            QQC2.Label {
                Layout.preferredWidth: root.settingLabelWidth
                elide: Text.ElideRight
                text: comboRow.label
            }
            QQC2.ComboBox {
                id: comboBox

                Layout.fillWidth: true
                currentIndex: comboRow.currentIndex
                model: comboRow.model
                textRole: comboRow.textRole
                valueRole: comboRow.valueRole

                onActivated: comboRow.activated(currentValue, currentIndex)
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: root.settingLabelWidth + Kirigami.Units.smallSpacing
            color: Kirigami.Theme.disabledTextColor
            text: comboRow.description
            visible: comboRow.description.length > 0
            wrapMode: Text.WordWrap
        }
    }
    component SettingsSectionLabel: QQC2.Label {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.disabledTextColor
        font.bold: true
    }
    component SettingsSlider: ColumnLayout {
        id: sliderRow

        property int decimals: 0
        property string description: ""
        property real from: 0
        property string label: ""
        property real stepSize: 1
        property string suffix: ""
        property real to: 100
        property real value: 0

        signal moved(real value)

        function formattedValue(): string {
            const numericValue = decimals === 0 ? Math.round(slider.value).toString() : slider.value.toFixed(decimals);
            return suffix.length > 0 ? i18n("%1 %2", numericValue, suffix) : numericValue;
        }

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            QQC2.Label {
                Layout.preferredWidth: root.settingLabelWidth
                elide: Text.ElideRight
                text: sliderRow.label
            }
            QQC2.Slider {
                id: slider

                Layout.fillWidth: true
                from: sliderRow.from
                snapMode: QQC2.Slider.NoSnap
                stepSize: sliderRow.stepSize
                to: sliderRow.to
                value: sliderRow.value

                onMoved: {
                    const adjustedValue = sliderRow.decimals === 0 ? Math.round(value) : Number(value.toFixed(sliderRow.decimals));
                    sliderRow.moved(adjustedValue);
                }
            }
            QQC2.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 4
                color: Kirigami.Theme.disabledTextColor
                horizontalAlignment: Text.AlignRight
                text: sliderRow.formattedValue()
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: root.settingLabelWidth + Kirigami.Units.smallSpacing
            color: Kirigami.Theme.disabledTextColor
            text: sliderRow.description
            visible: sliderRow.description.length > 0
            wrapMode: Text.WordWrap
        }
    }
}
