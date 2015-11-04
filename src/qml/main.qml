import QtQuick 2.5
import QtQuick.Controls 1.4

Item {
    property int menuBarWidth: 280

    Component {
        id: categoryDelegate

        Rectangle {
            width: parent.width; height: 50
            color: "#475057"

            Text {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                //text: modelData.category.split('|')[0]; color: "white"
                text: modelData.options[scrollView.depth].name; color: "white"
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
            }
        }
    }
    StackView {
        id: scrollView

        width: menuBarWidth; height: parent.height - midiPlayer.height - midiPlayerLabels.height

        Rectangle {
            anchors.fill: parent
            color: "#475057"
        }
        ListView {
            anchors.fill: parent
            model: exerciseCategories
            delegate: categoryDelegate
        }
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

        width: parent.width - scrollView.width
        anchors.left: scrollView.right
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
    }
    PianoView {
        anchors { verticalCenter: midiPlayer.verticalCenter; bottomMargin: 10; horizontalCenter: background.horizontalCenter }
    }
    Component.onCompleted: {
        console.log(exerciseCategories);
        for (var prop in exerciseCategories) {
            console.log("Object item:", prop, "=", exerciseCategories[prop])
        }
    }
}