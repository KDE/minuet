import QtQuick 2.4
import QtQuick.Controls 1.3

Item {
    id: exerciseView

    property string chosenExercise
    
    signal answerHoverEnter(var chan, var pitch, var vel, var color)
    signal answerHoverExit(var chan, var pitch, var vel)
    
    function clearExerciseGrid() {
        exerciseView.visible = false
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
    }
    function highlightRightAnswer() {
        var answerRectangle;
        for (var i = 0; i < answerGrid.children.length; ++i)
            if (answerGrid.children[i].text != chosenExercise)
                answerGrid.children[i].opacity = 0.25
            else
                answerRectangle = answerGrid.children[i]
        answerHoverEnter(0, exerciseController.chosenRootNote() + answerRectangle.sequenceFromRoot, 0, answerRectangle.color)
        anim1.target = anim2.target = anim3.target = anim4.target = anim5.target = answerRectangle
        animation.start()

    }
    function itemChanged(model) {
        sequencer.allNotesOff()
        exerciseView.visible = false
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
        chosenExercise = exerciseController.randomlyChooseExercise()
        var length = model.length
        answerGrid.columns = Math.min(6, length)
        answerGrid.rows = Math.ceil(length/6)
        var colors = ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        for (var i = 0; i < length; ++i)
            answerOption.createObject(answerGrid, {text: model[i].name, sequenceFromRoot: model[i].sequenceFromRoot, color: colors[i%24]})
        exerciseView.visible = true
    }

    visible: false

    Timer {
        id: timer

        interval: 3000; running: false; repeat: false
        onTriggered: {
            sequencer.allNotesOff()
            for (var i = 0; i < answerGrid.children.length; ++i)
                    answerGrid.children[i].opacity = 1
            messageText.text = qsTr("Hear the interval and then choose an answer from options below!<br/>Click 'play' if you want to hear again!")
            chosenExercise = exerciseController.randomlyChooseExercise()
            exerciseController.playChoosenExercise()
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: 20
        Text {
            id: messageText

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 20
            textFormat: Text.RichText
            text: qsTr("Hear the interval and then choose an answer from options below!<br/>Click 'play' if you want to hear again!")
        }
        Row {
            anchors { horizontalCenter: parent.horizontalCenter }
            spacing: 20
            Button {
                width: 120; height: 40
                text: qsTr("play")
                onClicked: exerciseController.playChoosenExercise()
            }
            Button {
                width: 120; height: 40
                text: qsTr("give up")
                onClicked: { highlightRightAnswer(); timer.start() }
            }
        }
        Rectangle {
            width: answerGrid.columns*140; height: answerGrid.rows*60
            color: "#475057"
            radius: 5
            anchors { horizontalCenter: parent.horizontalCenter }
            Grid {
                id: answerGrid

                anchors.centerIn: parent
                spacing: 20; columns: 2; rows: 1
                Component {
                    id: answerOption

                    Rectangle {
                        id: answerRectangle

                        property alias text: option.text
                        property int sequenceFromRoot

                        width: 120; height: 40
                        Text { id: option; anchors.centerIn: parent; width: parent.width; horizontalAlignment: Qt.AlignHCenter; color: "black"; wrapMode: Text.Wrap }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (option.text == chosenExercise) {
                                    messageText.text = "Congratulations!<br/>You answered correctly!"
                                } else {
                                    messageText.text = "Ops, not this time!<br/>Try again!"
                                }
                                answerHoverExit(0, exerciseController.chosenRootNote() + sequenceFromRoot, 0)
                                highlightRightAnswer()
                                timer.start()
                            }
                            hoverEnabled: true
                            onEntered: answerHoverEnter(0, exerciseController.chosenRootNote() + sequenceFromRoot, 0, color)
                            onExited: if (!timer.running) answerHoverExit(0, exerciseController.chosenRootNote() + sequenceFromRoot, 0)
                        }
                    }
                }
            }
        }
        
    }
    ParallelAnimation {
        id: animation
        SequentialAnimation {
            PropertyAnimation { id: anim1; property: "rotation"; to: -45; duration: 200 }
            PropertyAnimation { id: anim2; property: "rotation"; to:  45; duration: 200 }
            PropertyAnimation { id: anim3; property: "rotation"; to:   0; duration: 200 }
        }
        SequentialAnimation {
            PropertyAnimation { id: anim4; property: "scale"; to: 1.2; duration: 300 }
            PropertyAnimation { id: anim5; property: "scale"; to: 1.0; duration: 300 }
        }
    }
}
