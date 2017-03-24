import QtQuick 2.7

Repeater {
    id: repeater
    property bool spaced: true

    Note {
        midiKey: modelData
        spaced: (index == 0) ? true:repeater.spaced
    }
}
