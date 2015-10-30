import QtQuick 2.5
import QtQuick.Controls 1.4

Item {
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
            color: "#475057"
            width: parent.width; height: 50
            Text {
                text: name; color: "white"
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
            }
            Rectangle {
                width: parent.width; height: 1
                color: "#181B1E"
                anchors.bottom: parent.bottom
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
        frameVisible: true
        width: 250; height: parent.height
        Rectangle {
            color: "#475057"
            anchors.fill: parent
        }
        ListView {
            anchors.fill: parent
            model: categories
            delegate: categoryDelegate
        }
    }
    Image {
        id: background
        anchors.left: scrollView.right
        width: parent.width - scrollView.width
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
    }
    Rectangle {
        width: background.width; height: 100
        clip: true
        anchors { bottom: parent.bottom; right: parent.right }
        PianoView { anchors.centerIn: parent }
    }
}
