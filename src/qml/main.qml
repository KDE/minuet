import QtQuick 2.5
import QtQuick.Controls 1.4

Item {
    property int menuBarWidth: 280

    ListModel {
        id: categories

        ListElement { name: "Intervals"; cost: 2.45 }
        ListElement { name: "Rythm"; cost: 3.25 }
        ListElement { name: "Theory"; cost: 1.95 }
        ListElement { name: "Chords"; cost: 1.95 }
        ListElement { name: "Scales"; cost: 1.95 }
        ListElement { name: "Misc"; cost: 1.95 }
    }
    Component {
        id: categoryDelegate

        Rectangle {
            width: parent.width; height: 50
            color: "#475057"

            Text {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                text: name; color: "white"
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
    ScrollView {
        id: scrollView

        width: menuBarWidth; height: parent.height - midiPlayer.height

        Rectangle {
            anchors.fill: parent
            color: "#475057"
        }
        ListView {
            anchors.fill: parent
            model: categories
            delegate: categoryDelegate
        }
    }
    MidiPlayer { id: midiPlayer }
    Image {
        id: background

        width: parent.width - scrollView.width
        anchors.left: scrollView.right
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
    }
    Rectangle {
        width: background.width; height: 100
        anchors { bottom: parent.bottom; right: parent.right }
        clip: true

        PianoView { anchors.centerIn: parent }
    }
}