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

    function melodicGroupForInstrument(instrument) {
        for (let i = 0; i < instrumentsModel.count; ++i) {
            const entry = instrumentsModel.get(i)
            if (entry.program === instrument) {
                return entry.group
            }
        }
        return groupsModel.count > 0 ? groupsModel.get(0).id : -1
    }

    function melodicGroupIndex(group) {
        for (let i = 0; i < groupsModel.count; ++i) {
            if (groupsModel.get(i).id === group) {
                return i
            }
        }
        return -1
    }

    function melodicInstrumentIndex(instrument) {
        for (let i = 0; i < instrumentsForGroupModel.count; ++i) {
            if (instrumentsForGroupModel.get(i).program === instrument) {
                return i
            }
        }
        return -1
    }

    function rhythmInstrumentIndex(instrument) {
        for (let i = 0; i < rhythmInstrumentsModel.count; ++i) {
            if (rhythmInstrumentsModel.get(i).key === instrument) {
                return i
            }
        }
        return -1
    }

    function rebuildModels() {
        groupsModel.clear()
        instrumentsModel.clear()
        rhythmInstrumentsModel.clear()

        if (!core.soundController) {
            root.selectedMelodicGroup = -1
            instrumentsForGroupModel.clear()
            return
        }

        const instrumentGroups = JSON.parse(core.soundController.instrumentGroupsJson || "[]")
        const instruments = JSON.parse(core.soundController.instrumentsJson || "[]")
        const rhythmInstruments = JSON.parse(core.soundController.rhythmInstrumentsJson || "[]")

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

    function rebuildInstrumentsForGroup() {
        instrumentsForGroupModel.clear()
        for (let i = 0; i < instrumentsModel.count; ++i) {
            const instrument = instrumentsModel.get(i)
            if (instrument.group === root.selectedMelodicGroup) {
                instrumentsForGroupModel.append(instrument)
            }
        }
    }

    function syncSelectionFromController() {
        if (!core.soundController) {
            return
        }

        root.selectedMelodicGroup = melodicGroupForInstrument(core.soundController.instrument)
        groupSelector.currentIndex = melodicGroupIndex(root.selectedMelodicGroup)
        rebuildInstrumentsForGroup()
        melodicInstrumentSelector.currentIndex = melodicInstrumentIndex(core.soundController.instrument)
        rhythmInstrumentSelector.currentIndex = rhythmInstrumentIndex(core.soundController.rhythmInstrument)
    }

    function selectFirstInstrumentInCurrentGroup() {
        if (instrumentsForGroupModel.count > 0 && core.soundController) {
            core.soundController.instrument = instrumentsForGroupModel.get(0).program
        }
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
        target: core.soundController

        function onInstrumentGroupsChanged() {
            root.rebuildModels()
        }

        function onInstrumentsChanged() {
            root.rebuildModels()
        }

        function onRhythmInstrumentsChanged() {
            root.rebuildModels()
        }

        function onInstrumentChanged() {
            root.syncSelectionFromController()
        }

        function onRhythmInstrumentChanged() {
            root.syncSelectionFromController()
        }
    }

    FormCard.FormHeader {
        title: i18n("Player")
    }

    FormCard.FormCard {
        FormCard.AbstractFormDelegate {
            enabled: core.soundController !== null
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
                    value: core.soundController ? core.soundController.volume : 0
                    onMoved: {
                        if (core.soundController) {
                            core.soundController.volume = Math.round(value)
                        }
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
                root.rebuildInstrumentsForGroup()
                root.selectFirstInstrumentInCurrentGroup()
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
                if (core.soundController) {
                    core.soundController.instrument = currentValue
                }
            }
        }

        FormCard.FormDelegateSeparator {
            visible: groupsModel.count > 0 && rhythmInstrumentsModel.count > 0
        }

        FormCard.FormTextDelegate {
            text: i18n("Rhythm Exercises")
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
                if (core.soundController) {
                    core.soundController.rhythmInstrument = currentValue
                }
            }
        }
    }

    Component.onCompleted: root.rebuildModels()
}
