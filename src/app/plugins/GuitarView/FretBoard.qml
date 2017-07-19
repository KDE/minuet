import QtQuick 2.7

Rectangle {
    id: fretBoard
    height: (string1.height + string1.anchors.topMargin) * 6 + string1.anchors.topMargin
    color: "#4b3020"
    property double string_size: 3
    property string string_color: "#FFF2E6"
    property bool show_fret_marker: false
    property bool show_two_markers: false
    property bool is_nut: false
    property bool is_end: false

    Rectangle {
        id: fret_marker1
        height: 6.5 * string_size; width: height
        radius: width * 0.5
        visible: show_fret_marker
        opacity: 0.7
        anchors {
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset:  - string_size / 2
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: show_two_markers ? -(parent.height - (string1.y - parent.y)) / 4 : 0
        }
        color: "#E2E2E2"
        border.width: string_size / 2
        border.color: "#535353"
    }

    Rectangle {
        id: fret_marker2
        height: fret_marker1.height; width: height
        radius: width * 0.5
        visible: show_two_markers
        opacity: fret_marker1.opacity
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: show_two_markers ? (parent.height - (string1.y - parent.y)) / 4 : 0
        }
        color: "#E2E2E2"
        border.width: string_size / 2
        border.color: "#535353"
    }

    Rectangle {
        id: string1
        width: parent.width; height: string_size
        anchors { left: parent.left; top: parent.top; topMargin: 3 * height}
        color: string_color
    }

    Rectangle {
        id: string2
        width: parent.width; height: string_size
        anchors { left: parent.left; top: string1.bottom; topMargin: 3 * height}
        color: string_color
    }
    Rectangle {
        id: string3
        width: parent.width; height: string_size
        anchors { left: parent.left; top: string2.bottom; topMargin: 3 * height}
        color: string_color
    }
    Rectangle {
        id: string4
        width: parent.width; height: string_size
        anchors { left: parent.left; top: string3.bottom; topMargin: 3 * height}
        color: string_color
    }
    Rectangle {
        id: string5
        width: parent.width; height: string_size
        anchors { left: parent.left; top: string4.bottom; topMargin: 3 * height}
        color: string_color
    }
    Rectangle {
        id: string6
        width: parent.width; height: string_size
        anchors { left: parent.left; top: string5.bottom; topMargin: 3 * height}
        color: string_color
    }

    Rectangle {
        id: rightBar
        width: is_nut ? string_size * 4 : string_size; height: parent.height
        anchors {right: parent.right; top: parent.top; bottom: parent.bottom}
        visible: is_end ? false : true
        color: "#D9D9D9"
    }
}
