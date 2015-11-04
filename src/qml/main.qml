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
            }
            Rectangle {
                width: parent.width; height: 1
                anchors.bottom: parent.bottom
                color: "#181B1E"
            }
            Image {
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
        anchors.left: parent.left
        
        Component.onCompleted: { categoryMenu.createObject(stackView, {model: exerciseCategories}); }
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

        width: parent.width - menuBarWidth
        anchors.right: parent.right
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
    }
    PianoView {
        anchors { verticalCenter: midiPlayer.verticalCenter; bottomMargin: 10; horizontalCenter: background.horizontalCenter }
    }
}