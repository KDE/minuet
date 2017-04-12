import QtQuick 2.7

BravuraText {
    property int type: 0 // [0 treble, 1 bass]
    
    objectName: "symbol"

    anchors {
        left: parent.children[0].left;
        bottom: parent.children[0].bottom;
        bottomMargin: (type == 0) ? 10:30
    }
    text: (type == 0) ? "\ue050":"\ue062"
}
