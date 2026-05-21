/****************************************************************************
**
** Copyright (C) 2026 by Sandro S. Andrade <sandroandrade@kde.org>
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
import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormCardPage {
    id: root

    title: i18n("Settings")

    property int selectedMelodicGroup: -1

    function melodicGroupForInstrument(instrument: int): int {
        for (let i = 0; i < instrumentsModel.count; ++i) {
            const entry = instrumentsModel.get(i)
            if (entry.program === instrument) {
                return entry.group
            }
        }
        return groupsModel.count > 0 ? groupsModel.get(0).id : -1
    }

    function melodicGroupIndex(group: int): int {
        for (let i = 0; i < groupsModel.count; ++i) {
            if (groupsModel.get(i).id === group) {
                return i
            }
        }
        return -1
    }

    function melodicInstrumentIndex(instrument: int): int {
        for (let i = 0; i < instrumentsForGroupModel.count; ++i) {
            if (instrumentsForGroupModel.get(i).program === instrument) {
                return i
            }
        }
        return -1
    }

    function rhythmInstrumentIndex(instrument: int): int {
        for (let i = 0; i < rhythmInstrumentsModel.count; ++i) {
            if (rhythmInstrumentsModel.get(i).key === instrument) {
                return i
            }
        }
        return -1
    }

    function rebuildModels(): void {
        groupsModel.clear()
        instrumentsModel.clear()
        rhythmInstrumentsModel.clear()

        if (!Core.soundController) {
            root.selectedMelodicGroup = -1
            instrumentsForGroupModel.clear()
            return
        }

        const instrumentGroups = JSON.parse(Core.soundController.instrumentGroupsJson || "[]")
        const instruments = JSON.parse(Core.soundController.instrumentsJson || "[]")
        const rhythmInstruments = JSON.parse(Core.soundController.rhythmInstrumentsJson || "[]")

        for (const group of instrumentGroups) {
            groupsModel.append({
                id: group.id,
                name: group.name,
            })
        }

        for (const instrument of instruments) {
            instrumentsModel.append({
                group: instrument.group,
                bank: instrument.bank,
                program: instrument.program,
                number: instrument.number,
                name: instrument.name,
                displayName: instrument.displayName,
            })
        }

        for (const instrument of rhythmInstruments) {
            rhythmInstrumentsModel.append({
                key: instrument.key,
                number: instrument.number,
                name: instrument.name,
                displayName: instrument.displayName,
            })
        }

        syncSelectionFromController()
    }

    function rebuildInstrumentsForGroup(): void {
        instrumentsForGroupModel.clear()
        for (let i = 0; i < instrumentsModel.count; ++i) {
            const instrument = instrumentsModel.get(i)
            if (instrument.group === root.selectedMelodicGroup) {
                instrumentsForGroupModel.append(instrument)
            }
        }
    }

    function syncSelectionFromController(): void {
        if (!Core.soundController) {
            return
        }

        root.selectedMelodicGroup = melodicGroupIndex(Core.settingsController.instrumentGroup) >= 0
            ? Core.settingsController.instrumentGroup
            : melodicGroupForInstrument(Core.settingsController.instrument)
        if (root.selectedMelodicGroup !== Core.settingsController.instrumentGroup) {
            Core.settingsController.instrumentGroup = root.selectedMelodicGroup
        }
        groupSelector.currentIndex = melodicGroupIndex(root.selectedMelodicGroup)
        rebuildInstrumentsForGroup()
        melodicInstrumentSelector.currentIndex = melodicInstrumentIndex(Core.settingsController.instrument)
        rhythmInstrumentSelector.currentIndex = rhythmInstrumentIndex(Core.settingsController.rhythmInstrument)
    }

    ListModel {
        id: groupsModel
    }

    ListModel {
        id: instrumentsModel
    }

    ListModel {
        id: instrumentsForGroupModel
    }

    ListModel {
        id: rhythmInstrumentsModel
    }

    Connections {
        target: Core.soundController

        function onInstrumentGroupsChanged(): void {
            root.rebuildModels()
        }

        function onInstrumentsChanged(): void {
            root.rebuildModels()
        }

        function onRhythmInstrumentsChanged(): void {
            root.rebuildModels()
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
            visible: groupsModel.count === 0
        }

        FormCard.FormTextDelegate {
            text: i18n("Melodic Exercises")
            description: i18n("Used for scales, intervals, and chords.")
            visible: groupsModel.count > 0
        }

        FormCard.FormComboBoxDelegate {
            id: groupSelector

            text: i18n("Instrument group:")
            textRole: "name"
            valueRole: "id"
            model: groupsModel
            visible: groupsModel.count > 0
            onActivated: {
                root.selectedMelodicGroup = currentValue
                Core.settingsController.instrumentGroup = currentValue
                root.rebuildInstrumentsForGroup()
                melodicInstrumentSelector.currentIndex = root.melodicInstrumentIndex(Core.settingsController.instrument)
            }
        }

        FormCard.FormComboBoxDelegate {
            id: melodicInstrumentSelector

            text: i18n("Instrument:")
            textRole: "displayName"
            valueRole: "program"
            model: instrumentsForGroupModel
            visible: groupsModel.count > 0
            onActivated: {
                Core.settingsController.instrumentGroup = root.selectedMelodicGroup
                Core.settingsController.instrument = currentValue
            }
        }

        FormCard.FormDelegateSeparator {
            visible: groupsModel.count > 0 && rhythmInstrumentsModel.count > 0
        }

        FormCard.FormTextDelegate {
            text: i18n("Rhythmic Exercises")
            description: i18n("Used for rhythm figures. The count-in keeps its own sound.")
            visible: rhythmInstrumentsModel.count > 0
        }

        FormCard.FormComboBoxDelegate {
            id: rhythmInstrumentSelector

            text: i18n("Percussion sound:")
            textRole: "displayName"
            valueRole: "key"
            model: rhythmInstrumentsModel
            visible: rhythmInstrumentsModel.count > 0
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

    Component.onCompleted: root.rebuildModels()
}
