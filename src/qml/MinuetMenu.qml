import QtQuick 2.4
import QtQuick.Controls 1.3

StackView {
    id: stackView

    property Item selectedMenuItem

    signal backspacePressed
    signal itemChanged(var model)

    function itemClicked(delegateRect, index) {
        var model = delegateRect.ListView.view.model[index].options
        if (model != undefined) {
            exerciseController.setExerciseOptions(model)
            stackView.itemChanged(model)
        }
    }

    focus: true

    Component {
        id: categoryDelegate

        Rectangle {
            id: delegateRect

            width: parent.width; height: 50
            color: (selectedMenuItem == delegateRect) ? "#8393A0":"#475057"

            Text {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                text: modelData.name; color: "white"
            }
            Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: "#181B1E" }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!delegateRect.ListView.view.model[index].children) {
                        itemClicked(delegateRect, index)
                        selectedMenuItem = delegateRect
                    }
                }
            }
            Image {
                visible: delegateRect.ListView.view.model[index].children != undefined
                width: 24; height: 24
                anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 10 }
                source: "qrc:/images/navigate-next.png"
                z: 2
                MouseArea {
                    anchors.fill: parent
                    onClicked: stackView.push(categoryMenu.createObject(stackView, {model: delegateRect.ListView.view.model[index].children}))
                }
            }
        }
    }
    Component {
        id: categoryMenu
        Rectangle {
            width: menuBarWidth; height: parent.height
            color: "#475057"
            property alias model: listView.model
            ListView {
                id: listView
                anchors.fill: parent
                delegate: categoryDelegate
            }
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Backspace && stackView.depth > 0) {
            sequencer.allNotesOff()
            stackView.backspacePressed()
            selectedMenuItem = null
            stackView.pop()
        }
    }

    Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: exerciseCategories})) }
}
