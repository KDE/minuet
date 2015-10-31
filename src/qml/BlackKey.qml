import QtQuick 2.5

Rectangle {
    property Item anchor;

    width: 0.6*keyWidth; height: 0.6*keyHeight
    anchors { left: anchor.right; leftMargin: -(0.6*keyWidth)/2; top: anchor.top }
    border { width: 1; color: "black" }
    color: mouseArea.pressed ? "#475057" : "black"
    z: 1

    MouseArea {
        id: mouseArea
        anchors.fill: parent
    }
}