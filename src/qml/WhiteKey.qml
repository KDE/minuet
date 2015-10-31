import QtQuick 2.5

Rectangle {
    property Item anchor;

    width: keyWidth; height: keyHeight
    border { width: 1; color: "black" }
    color: mouseArea.pressed ? "#475057" : "white"
    MouseArea { id: mouseArea; anchors.fill: parent }
    Component.onCompleted: if (anchor != null) anchors.left = anchor.right;
}