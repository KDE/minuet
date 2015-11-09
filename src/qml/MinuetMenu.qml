import QtQuick 2.5
import QtQuick.Controls 1.4

StackView {
    id: stackView

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
            color: "#475057"

            Text {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                text: modelData.name; color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: itemClicked(delegateRect, index)
                }
            }
            Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: "#181B1E" }
            Image {
                visible: delegateRect.ListView.view.model[index].children != undefined
                width: 24; height: 24
                anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 10 }
                source: "qrc:/images/navigate-next.png"
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
            stackView.backspacePressed()
            stackView.pop()
        }
    }

    Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: exerciseCategories})); }
}