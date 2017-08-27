/****************************************************************************
**
** Copyright (C) 2017 by Stefan Toncu <stefan.toncu29@gmail.com>
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation; either version 2 of
** the License or (at your option) version 3 or any later version
** accepted by the membership of KDE e.V. (or its successor approved
** by the membership of KDE e.V.), which shall act as a proxy
** defined in Section 14 of version 3 of the license.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

import QtQuick 2.7
import QtQuick.Controls 2.0

Flickable {
    id: flickable

    width: guitar.width
    height: 156.4
    contentWidth: guitar.width
    boundsBehavior: Flickable.OvershootBounds
    clip: true

    property int rootName: 0
    property int rootFret: 0
    property int rootString: 0
    property int barFret: rootFret
    property int fretIntervalLimit: 6
    property int fretRootIntervalLimit: 8
    property var sequence
    property var stringsUsed

    function setSequence(sequence, stringsUsed) {
        flickable.sequence = []
        flickable.stringsUsed = []

        /* depending on the root position, select a certain sequence: C->E or F->B,
         *    equivalent to sequence[1] and sequence[2] */
        var i = 0
        if (rootName <= 4) {
            sequence[1].split(' ').forEach(function(note) {
                flickable.sequence[i++] = note
            })
            i = 0
            stringsUsed[0].split(' ').forEach(function(string) {
                flickable.stringsUsed[i++] = string
            })
        } else {
            sequence[2].split(' ').forEach(function(note) {
                flickable.sequence[i++] = note
            })
            i = 0
            stringsUsed[1].split(' ').forEach(function(string) {
                flickable.stringsUsed[i++] = string
            })
        }
    }
    /* change the opacity of unused strings to a given value */
    function setUnusedStrings(value) {
        var i, j
        /* for each fret */
        for (i = 0; i < guitar.frets.length; i++) {
            /* for each string */
            for (j = 0; j < 6; j++)
                /* if the string is not used */
                if (j < flickable.stringsUsed[0] || j > flickable.stringsUsed[1])
                    guitar.frets[i].ids[j].opacity = value
        }
    }
    /* draw the bar on the guitar */
    function setBar() {
        var i = 0, startBar = -1, endBar = -1;
        /* save the furthest to the left fret: this is the bar's fret */
        flickable.barFret = flickable.rootFret
        for (i = 0; i < flickable.sequence.length; i++) {
            var crtFret = parseInt(flickable.rootFret) + parseInt(flickable.sequence[i])
            if (crtFret < flickable.barFret)
                flickable.barFret = crtFret
        }
        /* save the start string and the end string of the bar */
        for (i = 0; i < flickable.sequence.length; i++)
            if (parseInt(flickable.rootFret) + parseInt(flickable.sequence[i]) == flickable.barFret) {
                    if (startBar == -1)
                        startBar = i;
                    endBar = i;
            }
        // set the start and end of the bar into the saved fret
        guitar.frets[flickable.barFret].startBar = startBar + parseInt(flickable.stringsUsed[0])
        guitar.frets[flickable.barFret].endBar = endBar + parseInt(flickable.stringsUsed[0])
    }
    /* remove the bar */
    function clearBar() {
        guitar.frets[flickable.barFret].startBar = -1
        guitar.frets[flickable.barFret].endBar = -1
    }
    function markNotes(model, color) {
        /* for interval and scales, only draw the notes given by sequence */
        if (currentExercise["playMode"] == "scale")
            return scaleExercise(model.sequence, true, color)

        /* for chords, clear the guitar from marks */
        clearAllMarks()
        /* then set the current root (given by model) */
        setOneRoot(0, core.exerciseController.chosenRootNote(), 0, color, model)
        /* select the right sequence from the model into flickable.sequence */
        setSequence(model.sequence, model.stringsUsed)
        /* change the opacity of unused strings to 0.3 */
        setUnusedStrings(0.3)
        /* draw the bar (if exists) on the guitar */
        setBar()
        /* for each note in the sequence, draw the note on its current fret */
        for (var i = 0; i < flickable.sequence.length; i++) {
            /* get the fret's index coresponding to each index in the sequence */
            var index = parseInt(flickable.rootFret) + parseInt(flickable.sequence[i])
            /* get the press array from the current fret */
            var aux = guitar.frets[index].press
            aux[i + parseInt(flickable.stringsUsed[0])] = true
            /* update the press array of the current fret with the modified aux array
             *    and set the fret's color */
            guitar.frets[index].press = aux
            guitar.frets[index].mark_color = color
        }
    }
    function unmarkNotes(sequence) {
        /* for interval and scales, only delete the notes given by sequence */
        if (currentExercise["playMode"] == "scale")
            return scaleExercise(sequence, false, "white")

        /* chords, reset the press array for each fret modified by markNotes */
         var i
         for (i = 0; i < flickable.sequence.length; i++) {
             var index = parseInt(flickable.rootFret) + parseInt(flickable.sequence[i])
             var aux = guitar.frets[index].press
             aux[i + parseInt(flickable.stringsUsed[0])] = false
             guitar.frets[index].press = aux
             guitar.frets[index].mark_color = color
         }
        /* change the opacity back to 1 for unused strings */
         setUnusedStrings(1)
        /* delete the bar from guitar */
         clearBar()
        /* reset root notes */
        setRoot(0, core.exerciseController.chosenRootNote(), 0, "white");
    }
    function scaleExercise(sequence, value, color) {
            /* current string used is the rootString */
            var crtString = rootString
            /* the new fret's location on guitar (index) */
            var newFret = rootFret + parseInt(sequence[0])
            /* the note at index "newFret" for string: "crtString" */
            var crtNote = (guitarToPiano(crtString) + newFret + 24) % 12

            /*
             * compute how many strings to go up if the newFret exceeds
             *    the limit set by "flickable.fretIntervalLimit"
             *    and update the "crtString" variable accordingly
             */
            var skipLastXStrings
            if (currentExercise["options"][0]["tags"].indexOf("ascending") != -1) {
                skipLastXStrings = Math.ceil((parseInt(sequence[0]) + rootFret - fretIntervalLimit) /
                                                    (11-fretIntervalLimit))
                /* keep skipLastXStrings in bounds: 0..rootString */
                if (skipLastXStrings < 0)
                    skipLastXStrings = 0
                if (skipLastXStrings > rootString)
                    skipLastXStrings = rootString
                /* update the string used for current note */
                crtString -= skipLastXStrings
            } else {
                skipLastXStrings = Math.ceil((Math.abs(parseInt(sequence[0])) + fretIntervalLimit - rootFret) /
                                                (11-fretIntervalLimit)) - 1
                /* update the string used for current note */
                crtString += skipLastXStrings

                /* recompute the fret index */
                newFret = ((crtNote+12)-guitarToPiano(crtString))%12

                /* if the note is on fret 0 == nut, draw the note on the string below */
                if (newFret == 0)
                    crtString++

                /*
                 * if the note should be on a string below the 6th,
                 *    draw it from top == string 0
                 */
                if (crtString > 5)
                    crtString = 0
            }

            /* recompute the fret index */
            newFret = ((crtNote+12)-guitarToPiano(crtString))%12
            /* the fret index result cannot be zero: change it to 12 */
            if (newFret == 0)
                newFret = 12

            /* draw or delete the marks, depending on the value */
            if (value)
                noteMark(crtString, newFret, 0, color)
            else
                noteUnmark(crtString, newFret, 0, color)
    }
    /* aditional method to bring the instrument to its initial state */
    function clean() {
        if (flickable.stringsUsed)
             setUnusedStrings(1)
    }
    /* set the root for each chord */
    function setRoot(chan, pitch, vel, color) {
        for (var i = 0; i < answerGrid.children.length; ++i)
            setOneRoot(chan, pitch, vel, color, answerGrid.children[i].model)
    }
    /*
     * set the root name and fret for the givn pitch and model,
     * then draw the root note on the guitar
     */
    function setOneRoot(chan, pitch, vel, color, model) {
        /* get the root name */
        rootName = pitch % 12
        var start = -1
        var lastString = -1

        /* for intervals/scales */
        if (currentExercise["playMode"] == "scale") {
            var mode = 1
            if (currentExercise["options"][0]["tags"].indexOf("ascending") != -1) {
                lastString = 5
                mode = -1
            } else {
                lastString = 0
                mode = 1
            }

            start = 0

            /* compute root's fret by substracting the converted guitar index
             *    into a piano index from the root's piano index */
            flickable.rootFret = ((rootName + 12) - guitarToPiano(lastString + start)) % 12
            /*
             * keep the root's fret in the limit set by "flickable.fretRootIntervalLimit";
             * if it exceeds the limit, go up one string and recompute the root fret
             */
            while (flickable.rootFret > fretRootIntervalLimit || flickable.rootFret <= 0) {
                lastString += mode
                flickable.rootFret = ((rootName + 12) - guitarToPiano(lastString + start)) % 12
            }

        /* for chords */
        } else {
            var sequence = model.sequence
            /* get the last index of the right sequence: [1] for C->E and [2] for F->B */
            if (rootName <= 4) {
                sequence[1].split(' ').forEach(function(note) {
                    lastString++
                })
                start = parseInt(model.stringsUsed[0][0])
            } else {
                sequence[2].split(' ').forEach(function(note) {
                    lastString++
                })
                start = parseInt(model.stringsUsed[1][0])
            }

            /* compute root's fret by substracting the converted guitar index
             *    into a piano index from the root's piano index */
            flickable.rootFret = ((rootName+12)-guitarToPiano(lastString+start))%12
        }

        rootString = lastString + start
        noteMark(rootString, rootFret, 0, color)
    }
    /* convert string index to piano indexes of an octave */
    function guitarToPiano(index) {
        if (index == 3)                     // D  ->  2
            return 2
        else if (index == 0 || index == 5)  // E  ->  4
            return 4
        else if (index == 2)                // G  ->  7
            return 7
        else if (index == 4)                // A  ->  9
            return 9
        else if (index == 1)                // B  ->  11
            return 11
    }
    /* return the guitar to the original state: delete all notes and the bar */
    function clearAllMarks() {
        var i
        for (i = 0; i < guitar.frets.length; i++)
            guitar.frets[i].press = [false, false, false, false, false, false]
        /* delete the bar from guitar */
         clearBar()
    }
    function scrollToNote(pitch) {
        flickable.contentX = guitar.frets[flickable.rootFret].x - flickable.width/2
    }
    function noteOn(chan, pitch, vel) {}
    function noteOff(chan, pitch, vel) {}
    function noteMark(chan, pitch, vel, color) {
        /* get the array "press" for a given index fret "pitch" */
        var aux = guitar.frets[pitch].press
        /* set the note in the aux array to TRUE at index "chan" */
        aux[chan] = true
        /* assign the modified press array to given fret ("pitch") and set the color */
        guitar.frets[pitch].press = aux
        guitar.frets[pitch].noteMarks[chan].color = color
    }
    function noteUnmark(chan, pitch, vel, color) {
        /* get the array "press" for a given index fret "pitch" */
        var aux = guitar.frets[pitch].press
        /* set the note in the aux array to FALSE at index "chan" */
        aux[chan] = false
        /* assign the modified press array to given fret ("pitch") and set the color */
        guitar.frets[pitch].press = aux
        guitar.frets[pitch].noteMarks[chan].color = color
    }
    function highlightKey(pitch, color) {}
    function itemForPitch(pitch) {}

    Rectangle {
        id: guitar

        width: board.board_width * 410 + 8.5; height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 5
        color: "#141414"

        property var frets: [nut, fretBoard1, fretBoard2, fretBoard3, fretBoard4, fretBoard5, fretBoard6, fretBoard7,
         fretBoard8, fretBoard9, fretBoard10, fretBoard11, fretBoard12, fretBoard13, fretBoard14, fretBoard15,
         fretBoard16, fretBoard17,  fretBoard18, fretBoard19, fretBoard20, fretBoard21, fretBoard22
        ]

        Item {
            id: board
            width: parent.width
            height: fretBoard1.height
            anchors.centerIn: parent

            property double board_width: 2.5

            FretBoard { id: nut;         anchors.left: parent.left     ;  width: board.board_width * 8.5; is_nut: true}
            FretBoard { id: fretBoard1;  anchors.left: nut.right       ;  width: board.board_width * 29.466}
            FretBoard { id: fretBoard2;  anchors.left: fretBoard1.right;  width: board.board_width * 27.812}
            FretBoard { id: fretBoard3;  anchors.left: fretBoard2.right;  width: board.board_width * 26.251; show_fret_marker: true}
            FretBoard { id: fretBoard4;  anchors.left: fretBoard3.right;  width: board.board_width * 24.788}
            FretBoard { id: fretBoard5;  anchors.left: fretBoard4.right;  width: board.board_width * 23.387; show_fret_marker: true}
            FretBoard { id: fretBoard6;  anchors.left: fretBoard5.right;  width: board.board_width * 22.075}
            FretBoard { id: fretBoard7;  anchors.left: fretBoard6.right;  width: board.board_width * 20.836; show_fret_marker: true}
            FretBoard { id: fretBoard8;  anchors.left: fretBoard7.right;  width: board.board_width * 19.666}
            FretBoard { id: fretBoard9;  anchors.left: fretBoard8.right;  width: board.board_width * 18.562; show_fret_marker: true}
            FretBoard { id: fretBoard10; anchors.left: fretBoard9.right;  width: board.board_width * 17.521}
            FretBoard { id: fretBoard11; anchors.left: fretBoard10.right; width: board.board_width * 16.537}
            FretBoard { id: fretBoard12; anchors.left: fretBoard11.right; width: board.board_width * 15.609; show_fret_marker: true; show_two_markers: true}
            FretBoard { id: fretBoard13; anchors.left: fretBoard12.right; width: board.board_width * 14.733}
            FretBoard { id: fretBoard14; anchors.left: fretBoard13.right; width: board.board_width * 13.906}
            FretBoard { id: fretBoard15; anchors.left: fretBoard14.right; width: board.board_width * 13.126; show_fret_marker: true}
            FretBoard { id: fretBoard16; anchors.left: fretBoard15.right; width: board.board_width * 12.289}
            FretBoard { id: fretBoard17; anchors.left: fretBoard16.right; width: board.board_width * 11.693; show_fret_marker: true}
            FretBoard { id: fretBoard18; anchors.left: fretBoard17.right; width: board.board_width * 11.037}
            FretBoard { id: fretBoard19; anchors.left: fretBoard18.right; width: board.board_width * 10.418}
            FretBoard { id: fretBoard20; anchors.left: fretBoard19.right; width: board.board_width * 9.833}
            FretBoard { id: fretBoard21; anchors.left: fretBoard20.right; width: board.board_width * 9.282}
            FretBoard { id: fretBoard22; anchors.left: fretBoard21.right; width: board.board_width * 9.760}
            FretBoard { id: chords;      anchors.left: fretBoard22.right; width: board.board_width * 30; is_end: true}
        }
    }

    ScrollIndicator.horizontal: ScrollIndicator { active: true }
}
