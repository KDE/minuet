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

    property int selectedGroup: -1

    function groupForInstrument(instrument) {
        for (let i = 0; i < instrumentsModel.count; ++i) {
            const entry = instrumentsModel.get(i)
            if (entry.program === instrument) {
                return entry.group
            }
        }
        return groupsModel.count > 0 ? groupsModel.get(0).id : -1
    }

    function groupIndex(group) {
        for (let i = 0; i < groupsModel.count; ++i) {
            if (groupsModel.get(i).id === group) {
                return i
            }
        }
        return -1
    }

    function instrumentIndex(instrument) {
        for (let i = 0; i < instrumentsForGroupModel.count; ++i) {
            if (instrumentsForGroupModel.get(i).program === instrument) {
                return i
            }
        }
        return -1
    }

    function rebuildModels() {
        groupsModel.clear()
        instrumentsModel.clear()

        if (!core.soundController) {
            root.selectedGroup = -1
            instrumentsForGroupModel.clear()
            return
        }

        const instrumentGroups = JSON.parse(core.soundController.instrumentGroupsJson || "[]")
        const instruments = JSON.parse(core.soundController.instrumentsJson || "[]")

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

        syncSelectionFromController()
    }

    function rebuildInstrumentsForGroup() {
        instrumentsForGroupModel.clear()
        for (let i = 0; i < instrumentsModel.count; ++i) {
            const instrument = instrumentsModel.get(i)
            if (instrument.group === root.selectedGroup) {
                instrumentsForGroupModel.append(instrument)
            }
        }
    }

    function syncSelectionFromController() {
        if (!core.soundController) {
            return
        }

        root.selectedGroup = groupForInstrument(core.soundController.instrument)
        groupSelector.currentIndex = groupIndex(root.selectedGroup)
        rebuildInstrumentsForGroup()
        instrumentSelector.currentIndex = instrumentIndex(core.soundController.instrument)
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

    Connections {
        target: core.soundController

        function onInstrumentGroupsChanged() {
            root.rebuildModels()
        }

        function onInstrumentsChanged() {
            root.rebuildModels()
        }

        function onInstrumentChanged() {
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
            text: i18n("No SoundFont instruments available")
            description: i18n("The active sound controller did not report any General MIDI bank 0 instruments.")
            icon.name: "dialog-warning-symbolic"
            visible: groupsModel.count === 0
        }

        FormCard.FormComboBoxDelegate {
            id: groupSelector

            text: i18n("Instrument group:")
            textRole: "name"
            valueRole: "id"
            model: groupsModel
            visible: groupsModel.count > 0
            onActivated: {
                root.selectedGroup = currentValue
                root.rebuildInstrumentsForGroup()
                root.selectFirstInstrumentInCurrentGroup()
            }
        }

        FormCard.FormDelegateSeparator {
            visible: groupSelector.visible
        }

        FormCard.FormComboBoxDelegate {
            id: instrumentSelector

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
    }

    Component.onCompleted: root.rebuildModels()
}
