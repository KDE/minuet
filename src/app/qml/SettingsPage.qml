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

    readonly property var groupsModel: Core.instrumentCatalogController.instrumentGroups(instrumentGroupsJson)
    readonly property string instrumentGroupsJson: Core.soundController ? Core.soundController.instrumentGroupsJson || "[]" : "[]"
    readonly property var instrumentsForGroupModel: Core.instrumentCatalogController.melodicInstrumentsForGroup(instrumentsModel, selectedMelodicGroup)
    readonly property string instrumentsJson: Core.soundController ? Core.soundController.instrumentsJson || "[]" : "[]"
    readonly property var instrumentsModel: Core.instrumentCatalogController.melodicInstruments(instrumentsJson)
    readonly property var microphoneOnsetMethods: ["complex", "hfc", "energy", "specflux", "phase", "specdiff", "kl", "mkl"]
    readonly property var microphonePitchMethods: ["yinfft", "yin", "yinfast", "mcomb", "schmitt", "specacf", "fcomb"]
    readonly property string rhythmInstrumentsJson: Core.soundController ? Core.soundController.rhythmInstrumentsJson || "[]" : "[]"
    readonly property var rhythmInstrumentsModel: Core.instrumentCatalogController.rhythmInstruments(rhythmInstrumentsJson)
    readonly property var scoringModes: [i18n("Pitch primary"), i18n("Pitch + timing")]
    readonly property var voiceClasses: [i18n("Soprano"), i18n("Alto"), i18n("Tenor"), i18n("Bass")]
    property int selectedMelodicGroup: -1

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

    component SettingsSlider: RowLayout {
        id: sliderRow

        property int decimals: 0
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

        QQC2.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            elide: Text.ElideRight
            text: sliderRow.label
        }
        QQC2.Slider {
            id: slider

            Layout.fillWidth: true
            from: sliderRow.from
            snapMode: sliderRow.stepSize > 0 ? QQC2.Slider.SnapAlways : QQC2.Slider.NoSnap
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
        title: i18n("Player")
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
    }
    FormCard.FormHeader {
        title: i18n("SoundFont")
    }
    FormCard.FormCard {
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
        title: i18n("Rhythm Exercises")
    }
    FormCard.FormCard {
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
    }
    FormCard.FormHeader {
        title: i18n("Clapping Exercises")
    }
    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        elide: Text.ElideRight
                        text: i18n("Onset method")
                    }
                    QQC2.ComboBox {
                        Layout.fillWidth: true
                        currentIndex: Core.settingsController.clappingOnsetMethod
                        model: root.microphoneOnsetMethods

                        onActivated: Core.settingsController.clappingOnsetMethod = currentIndex
                    }
                }
                SettingsSlider {
                    from: 5
                    label: i18n("Timing tolerance")
                    suffix: "%"
                    to: 100
                    value: Core.settingsController.clappingCorrectnessTolerancePercent

                    onMoved: function (value) {
                        Core.settingsController.clappingCorrectnessTolerancePercent = value;
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
            }
        }
    }
    FormCard.FormHeader {
        title: i18n("Singing Exercises")
    }
    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            background: null

            contentItem: ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        elide: Text.ElideRight
                        text: i18n("Voice class")
                    }
                    QQC2.ComboBox {
                        Layout.fillWidth: true
                        currentIndex: Core.settingsController.singingVoiceClass
                        model: root.voiceClasses

                        onActivated: Core.settingsController.singingVoiceClass = currentIndex
                    }
                }
                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        elide: Text.ElideRight
                        text: i18n("Pitch method")
                    }
                    QQC2.ComboBox {
                        Layout.fillWidth: true
                        currentIndex: Core.settingsController.singingPitchMethod
                        model: root.microphonePitchMethods

                        onActivated: Core.settingsController.singingPitchMethod = currentIndex
                    }
                }
                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        elide: Text.ElideRight
                        text: i18n("Onset method")
                    }
                    QQC2.ComboBox {
                        Layout.fillWidth: true
                        currentIndex: Core.settingsController.singingOnsetMethod
                        model: root.microphoneOnsetMethods

                        onActivated: Core.settingsController.singingOnsetMethod = currentIndex
                    }
                }
                SettingsSlider {
                    from: 10
                    label: i18n("Pitch tolerance")
                    suffix: i18n("cents")
                    to: 100
                    value: Core.settingsController.singingPitchToleranceCents

                    onMoved: function (value) {
                        Core.settingsController.singingPitchToleranceCents = value;
                    }
                }
                RowLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        elide: Text.ElideRight
                        text: i18n("Scoring mode")
                    }
                    QQC2.ComboBox {
                        Layout.fillWidth: true
                        currentIndex: Core.settingsController.singingScoringMode
                        model: root.scoringModes

                        onActivated: Core.settingsController.singingScoringMode = currentIndex
                    }
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
            }
        }
    }
    FormCard.FormHeader {
        title: i18n("Tests")
    }
    FormCard.FormCard {
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
}
