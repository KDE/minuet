import QtQuick 2.5

Item {
    property int keyWidth: 20
    property int keyHeight: 68

    width: whiteKeys.width; height: keyHeight
    Row {
        id: whiteKeys
        Repeater {
            model: 7
            Rectangle {
                width: keyWidth; height: keyHeight
                border { width: 1; color: "black" }
                color: whitemouse.pressed ? "#475057" : "white"
                MouseArea { id: whitemouse; anchors.fill: parent }
            }
        }
    }
    Row {
        id: blackKeys1
        anchors { left: whiteKeys.left; leftMargin: 14 }
        spacing: 8
        Repeater {
            model: 2
            Rectangle {
                width: 12; height: 42
                border { width: 1; color: "black" }
                color: blackmouse.pressed ? "#475057" : "black"
                MouseArea { id: blackmouse; anchors.fill: parent }
            }
        }
    }
    Row {
        id: blackKeys2
        anchors { left: blackKeys1.left; leftMargin: 60 }
        spacing: 8
        Repeater {
            model: 3
            Rectangle {
                width: 12; height: 42
                border { width: 1; color: "black" }
                color: blackmouse.pressed ? "#475057" : "black"
                MouseArea { id: blackmouse; anchors.fill: parent }
            }
        }
    }
}