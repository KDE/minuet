import QtQuick 2.4
import QtQuick.Controls 1.3

import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: minuetMenu

    property Item selectedMenuItem

    signal backspacePressed
    signal itemChanged(var model)

    function itemClicked(delegateRect, index) {
        var model = delegateRect.ListView.view.model[index].options
        if (model != undefined) {
            exerciseController.setExerciseOptions(model)
            minuetMenu.itemChanged(model)
        }
    }

    Button {
        id: breadcrumb
        width: (stackView.depth > 1) ? 24:0; height: parent.height;
        iconName: "go-previous"
        onClicked: {
            sequencer.allNotesOff()
            minuetMenu.backspacePressed()
            selectedMenuItem = null
            stackView.pop()
        }
    }
    StackView {
        id: stackView

        width: parent.width - breadcrumb.width; height: parent.height
        anchors.left: breadcrumb.right
        clip: true
        focus: true

        Component {
            id: categoryDelegate

            Button {
                id: delegateRect
                width: parent.width; height: 50

                text: modelData.name
                checkable: (!delegateRect.ListView.view.model[index].children) ? true:false
                onClicked: {
                    if (!delegateRect.ListView.view.model[index].children) {
                        if (selectedMenuItem != undefined) selectedMenuItem.checked = false
                        itemClicked(delegateRect, index)
                        selectedMenuItem = delegateRect
                    }
                    else {
                        stackView.push(categoryMenu.createObject(stackView, {model: delegateRect.ListView.view.model[index].children}))
                        var root = delegateRect.ListView.view.model[index].root
                        if (root != undefined) {
                            exerciseController.setMinRootNote(root.split('.')[0])
                            exerciseController.setMaxRootNote(root.split('.')[2])
                        }
                        var playMode = delegateRect.ListView.view.model[index].playMode
                        if (playMode != undefined) {
                            if (playMode == "scale" ) exerciseController.setPlayMode(0) // ScalePlayMode
                            if (playMode == "chord" ) exerciseController.setPlayMode(1) // ChordPlayMode
                        }
                    }
                }
            }
        }
        Component {
            id: categoryMenu
            Rectangle {
                width: stackView.width; height: parent.height
                color: theme.viewBackgroundColor
                property alias model: listView.model
                ListView {
                    id: listView
                    anchors.fill: parent
                    spacing: -2
                    delegate: categoryDelegate
                }
            }
        }

        Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: exerciseCategories})) }
    }
}
