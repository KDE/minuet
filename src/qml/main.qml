import QtQuick 2.5
import QtQuick.Controls 1.4

Item {
    property int menuBarWidth: 280

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
                    onClicked:  {
                        var colors = ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f"];
                        if (delegateRect.ListView.view.model[index].options != undefined) {
                            exerciseItem.visible = false;
                            for (var i = 0; i < answerGrid.children.length; ++i) {
                                answerGrid.children[i].destroy();
                            }
                            var length = delegateRect.ListView.view.model[index].options.length
                            exerciseController.setExerciseOptions(delegateRect.ListView.view.model[index].options);
                            console.log(exerciseController.randomlyChooseExercise());
                            answerGrid.columns = Math.min(4, length)
                            answerGrid.rows = Math.ceil(length/4)
                            for (var i = 0; i < length; ++i)
                                answerOption.createObject(answerGrid, {text: delegateRect.ListView.view.model[index].options[i].name, color: colors[i%12]})
                            exerciseItem.visible = true;
                        }
                    }
                }
            }
            Rectangle {
                width: parent.width; height: 1
                anchors.bottom: parent.bottom
                color: "#181B1E"
            }
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
    StackView {
        id: stackView
        width: menuBarWidth; height: parent.height - midiPlayer.height - midiPlayerLabels.height
        anchors { left: parent.left; top: parent.top}
        focus: true
        Keys.onPressed: {
            if (event.key == Qt.Key_Backspace && stackView.depth > 0) {
                exerciseItem.visible = false
                stackView.pop()
            }
        }
        
        Component.onCompleted: { stackView.push(categoryMenu.createObject(stackView, {model: exerciseCategories})); }
    }
    MidiPlayer { id: midiPlayer }
    Rectangle {
        id: midiPlayerLabels
        width: menuBarWidth; height: 20
        anchors.bottom: midiPlayer.top
        color: "#343434"
        Row {
            width: parent.width
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 15 }
            Text {
                id: tempoLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: "white"
                text: qsTr("Tempo:")
            }
            Text {
                id: volumeLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: "white"
                text: qsTr("Volume: 100%")
            }
            Text {
                id: pitchLabel
                width: parent.width / 3
                font.pointSize: 8
                horizontalAlignment: Text.AlignLeft
                color: "white"
                text: qsTr("Pitch: 0")
            }
        }
    }
    Image {
        id: background

        width: parent.width - menuBarWidth; height: parent.height
        anchors.right: parent.right
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
        Item {
            id: exerciseItem
            width: parent.width; height: childrenRect.height
            anchors.centerIn: background
            visible: false
            Column {
                anchors { horizontalCenter: parent.horizontalCenter }
                spacing: 20
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: 24
                    text: "Click 'play' to hear the interval and then choose an answer from options below!"
                }
                Row {
                    anchors { horizontalCenter: parent.horizontalCenter }
                    spacing: 20
                    Rectangle {
                        width: 120; height: 40; color: "white"; border.color: "black"; border.width: 2; radius: 5
                        Text { anchors.centerIn: parent; color: "black"; text: "play" }
                    }
                    Rectangle {
                        width: 120; height: 40; color: "gray"; border.color: "black"; border.width: 2; radius: 5
                        Text { anchors.centerIn: parent; color: "white"; text: "give up" }
                    }
                }
                Rectangle {
                    width: answerGrid.columns*140; height: answerGrid.rows*60
                    color: "#475057"
                    radius: 5
                    anchors { horizontalCenter: parent.horizontalCenter }
                    Grid {
                        id: answerGrid
                        anchors.centerIn: parent
                        spacing: 20
                        columns: 2
                        rows: 1
                        Component {
                            id: answerOption
                            Rectangle {
                                property alias text: option.text
                                width: 120; height: 40; border.color: "white"; border.width: 2; radius: 5
                                Text { id: option; anchors.centerIn: parent; width: parent.width; horizontalAlignment: Qt.AlignHCenter; color: "black"; wrapMode: Text.Wrap }
                            }
                        }
                    }
                }
            }
        }
    }
    PianoView {
        anchors { verticalCenter: midiPlayer.verticalCenter; bottomMargin: 10; horizontalCenter: background.horizontalCenter }
    }
}