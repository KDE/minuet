import QtQuick 2.5

Item {
    property int menuBarWidth: 280

    MinuetMenu {
        id: minuetMenu

        width: menuBarWidth; height: parent.height - midiPlayer.height
        anchors { left: parent.left; top: parent.top}
    }
    MidiPlayer {
        id: midiPlayer
        
        width: menuBarWidth;
    }
    Image {
        id: background

        width: parent.width - menuBarWidth; height: parent.height
        anchors.right: parent.right
        source: "qrc:/images/minuet-background.png"
        fillMode: Image.Tile
        clip: true
        PianoView {
            anchors { bottom: parent.bottom; bottomMargin: 5; horizontalCenter: parent.horizontalCenter }
        }
    }
    ExerciseView {
        id: exerciseView
        
        width: background.width; height: minuetMenu.height + 20
        anchors { top: background.top; horizontalCenter: background.horizontalCenter }
        minuetMenu: minuetMenu
    }
}