import QtQuick 2.5

Item {
    id: keyboard

    property int keyWidth: 20
    property int keyHeight: 3.4*keyWidth

    function noteOn(chan, pitch, vol) {
        highlightKey(pitch, "#778692")
    }
    function noteOff(chan, pitch, vol) {
        highlightKey(pitch, ([1,3,6,8,10].indexOf(pitch % 12) > -1) ? "black":"white")
    }
    function highlightKey(pitch, color) {
        if (pitch < 24) {
            keyboard.children[pitch-21].color = color
            return
        }
        var note = (pitch - 24) % 12
        var octave = (pitch - 24 - note) / 12
        keyboard.children[3+octave].children[note].color = color
    }

    width: 2*keyWidth+7*(7*keyWidth); height: keyHeight

    WhiteKey { id: whiteKeyA }
    BlackKey { anchor: whiteKeyA }
    WhiteKey { id: whiteKeyB; anchor: whiteKeyA }
    Octave { id: octave1; initialAnchor: whiteKeyB }
    Octave { id: octave2; initialAnchor: octave1 }
    Octave { id: octave3; initialAnchor: octave2 }
    Octave { id: octave4; initialAnchor: octave3 }
    Octave { id: octave5; initialAnchor: octave4 }
    Octave { id: octave6; initialAnchor: octave5 }
    Octave { id: octave7; initialAnchor: octave6 }

    Component.onCompleted: {
        sequencer.noteOn.connect(noteOn)
        sequencer.noteOff.connect(noteOff)
    }
}