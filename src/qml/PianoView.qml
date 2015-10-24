import QtQuick 2.5

Item {
    width: 1020; height: 68
    Row {
        id: whiteKeys0
        Repeater {
            model: 2
            Rectangle {
                width: 20; height: 68
                border { width: 1; color: "black" }
                color: whitemouse.pressed ? "#475057" : "white"
                MouseArea { id: whitemouse;  anchors.fill: parent }

            }
        }
    }
    Row {
        id: blackKeys0
        anchors { left: whiteKeys0.left; leftMargin: 14 }
        Repeater {
            model: 1
            Rectangle {
                width: 12; height: 42
                border { width: 1; color: "black" }
                color: blackmouse.pressed ? "#475057" : "black"
                MouseArea { id: blackmouse;  anchors.fill: parent }
            }
        }
    }
    Row {
        anchors.left: whiteKeys0.right
        Repeater {
            model: 7
            Octave { }
        }
    }
}