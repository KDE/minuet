import QtQuick 2.7

Item {
    property int spacing
    property Clef clef

    objectName: "score"

    Row {
        spacing: 0
        Repeater {
            model: 25
            BravuraText { text: "\ue014" }
        }
    }
}
