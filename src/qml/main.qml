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
    }
    ExerciseView {
        id: exerciseView
        
        width: background.width; height: minuetMenu.height
        anchors { top: background.top; horizontalCenter: background.horizontalCenter }
        minuetMenu: minuetMenu
    }
    PianoView {
        anchors { verticalCenter: midiPlayer.verticalCenter; bottomMargin: 10; horizontalCenter: background.horizontalCenter }
    }
}