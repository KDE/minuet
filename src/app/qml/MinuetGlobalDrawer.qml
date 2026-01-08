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

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.GlobalDrawer {
    id: drawer

    property bool wideScreen: false
    onWideScreenChanged: drawerOpen = wideScreen

    property var currentExercise

    padding: 0
    topPadding: undefined
    leftPadding: undefined
    rightPadding: undefined
    bottomPadding: undefined
    verticalPadding: undefined
    horizontalPadding: undefined

    modal: !drawer.wideScreen
    interactiveResizeEnabled: true
    resetMenuOnTriggered: false

    Component {
        id: actionComponent

        Kirigami.Action {
            required property var modelData
            required property string iconName

            text: "Sync"
            icon.name: iconName
            onTriggered: {
                if (modelData.children === undefined) {
                    drawer.currentExercise = modelData
                }
            }
        }
    }

    function createActions(actionSet, icon) {
        const ret = []
        for (const action of actionSet) {
            const actionObject = actionComponent.createObject(drawer, { modelData: action, text: action.name, iconName: action._icon ?? icon })
            if (action.children !== undefined) {
                actionObject.children = createActions(action.children, action._icon ?? icon)
            } else {

            }
            ret.push(actionObject)
        }
        return ret;
    }

    actions: createActions(core.exerciseController.exercises)
}
