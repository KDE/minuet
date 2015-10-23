import QtQuick 2.5
import QtQuick.Controls 1.4

Item {
    visible: true

    ListModel {
        id: fruitModel
        ListElement {
            name: "Intervals"
            cost: 2.45
        }
        ListElement {
            name: "Rythm"
            cost: 3.25
        }
        ListElement {
            name: "Theory"
            cost: 1.95
        }
        ListElement {
            name: "Chords"
            cost: 1.95
        }
        ListElement {
            name: "Scales"
            cost: 1.95
        }
        ListElement {
            name: "Misc"
            cost: 1.95
        }
    }

    Component {
        id: fruitDelegate
        Rectangle {
            color: "#475057"
            height: 50; width: parent.width
            Text {
                text: name; color: "white"
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
            }
            Rectangle {
                height: 1; width: parent.width
                color: "#181B1E"
                anchors.bottom: parent.bottom
            }
            Image {
                height: 24; width: 24
                anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 10 }
                source: "qrc:/images/navigate-next.png"
            }
        }
    }
    
    ScrollView {
        id: scrollView
        frameVisible: true
        height: parent.height; width: 200
        Rectangle {
            color: "#475057"
            anchors.fill: parent
        }
        ListView {
            anchors.fill: parent
            model: fruitModel
            delegate: fruitDelegate
        }
    }
    Image {
        anchors.left: scrollView.right
        width: parent.width - scrollView.width
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
    }
}
