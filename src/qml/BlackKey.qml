import QtQuick 2.5

Rectangle {
    property Item anchor;

    width: 0.6*keyWidth; height: 0.6*keyHeight
    border { width: 1; color: "black" }
    color: mouseArea.pressed ? "#475057" : "black"
    MouseArea { id: mouseArea; anchors.fill: parent }
    anchors { left: anchor.right; leftMargin: -(0.6*keyWidth)/2; top: anchor.top }
    z: 1
}