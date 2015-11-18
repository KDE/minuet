import QtQuick 2.5

Item {
    property Item initialAnchor

    width: 7*keyWidth; height: keyHeight
    anchors.left: initialAnchor.right

    WhiteKey { id: whiteKey1 }
    BlackKey { anchor: whiteKey1 }
    WhiteKey { id: whiteKey2; anchor: whiteKey1 }
    BlackKey { anchor: whiteKey2 }
    WhiteKey { id: whiteKey3; anchor: whiteKey2 }
    WhiteKey { id: whiteKey4; anchor: whiteKey3 }
    BlackKey { anchor: whiteKey4 }
    WhiteKey { id: whiteKey5; anchor: whiteKey4 }
    BlackKey { anchor: whiteKey5 }
    WhiteKey { id: whiteKey6; anchor: whiteKey5 }
    BlackKey { anchor: whiteKey6 }
    WhiteKey { anchor: whiteKey6 }
}