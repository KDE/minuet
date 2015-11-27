import QtQuick 2.4
import QtQuick.Controls 1.3

Item {
    id: exerciseView

    property string chosenExercise
    property Item answerRectangle
    
    signal answerHoverEnter(var chan, var pitch, var vel, var color)
    signal answerHoverExit(var chan, var pitch, var vel)
    
    function clearExerciseGrid() {
        exerciseView.visible = false
        for (var i = 0; i < answerGrid.children.length; ++i)
            answerGrid.children[i].destroy()
    }
    function highlightRightAnswer() {
        for (var i = 0; i < answerGrid.children.length; ++i)
            if (answerGrid.children[i].model.name != chosenExercise)
                answerGrid.children[i].opacity = 0.25
            else
                answerRectangle = answerGrid.children[i]
        answerHoverEnter(0, exerciseController.chosenRootNote() + parseInt(answerRectangle.model.sequenceFromRoot), 0, answerRectangle.color)
        animation.start()
    }
    function itemChanged(model) {
        sequencer.allNotesOff()
        clearExerciseGrid()
        var length = model.length
        answerGrid.columns = Math.min(6, length)
        answerGrid.rows = Math.ceil(length/6)
        var colors = ["#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "#ffed6f", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#ffff99", "#b15928"]
        for (var i = 0; i < length; ++i)
            answerOption.createObject(answerGrid, {model: model[i], color: colors[i%24]})
        exerciseView.visible = true
        exerciseView.state = "initial"
    }

    visible: false

    Column {
        anchors.centerIn: parent
        spacing: 20
        Text {
            id: messageText

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 18
            textFormat: Text.RichText
            text: qsTr("Hear the interval and then choose an answer from options below!<br/>Click 'play' if you want to hear again!")
        }
        Row {
            anchors { horizontalCenter: parent.horizontalCenter }
            spacing: 20
            Button {
                id: newQuestionButton

                width: 120; height: 40
                text: qsTr("new question")
                onClicked: {
                    chosenExercise = exerciseController.randomlyChooseExercise()
                    messageText.text = qsTr("Hear the interval and then choose an answer from options below!<br/>Click 'play' if you want to hear again!")
                    exerciseController.playChoosenExercise()
                    exerciseView.state = "waitingForAnswer"
                }
            }
            Button {
                id: playQuestionButton

                width: 120; height: 40
                text: qsTr("play question")
                onClicked: exerciseController.playChoosenExercise()
            }
            Button {
                id: giveUpButton

                width: 120; height: 40
                text: qsTr("give up")
                onClicked: highlightRightAnswer()
            }
        }
        Rectangle {
            width: answerGrid.columns*130+10; height: answerGrid.rows*50+10
            color: "#475057"
            radius: 5
            anchors.horizontalCenter: parent.horizontalCenter
            Grid {
                id: answerGrid

                anchors.centerIn: parent
                spacing: 10; columns: 2; rows: 1
                Component {
                    id: answerOption

                    Rectangle {
                        id: answerRectangle

                        property var model

                        width: 120; height: 40
                        Text {
                            id: option;

                            text: model.name
                            width: parent.width;
                            anchors.centerIn: parent;
                            horizontalAlignment: Qt.AlignHCenter;
                            color: "black";
                            wrapMode: Text.Wrap
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (option.text == chosenExercise)
                                    messageText.text = "Congratulations!<br/>You answered correctly!"
                                else
                                    messageText.text = "Ops, not this time!<br/>Try again!"
                                answerHoverExit(0, exerciseController.chosenRootNote() + parseInt(model.sequenceFromRoot), 0)
                                highlightRightAnswer()
                            }
                            hoverEnabled: true
                            onEntered: answerHoverEnter(0, exerciseController.chosenRootNote() + parseInt(model.sequenceFromRoot), 0, color)
                            onExited: answerHoverExit(0, exerciseController.chosenRootNote() + parseInt(model.sequenceFromRoot), 0)
                        }
                    }
                }
            }
        }
    }
    states: [
        State {
            name: "initial"
            StateChangeScript {
                script: {
                    sequencer.allNotesOff()
                    for (var i = 0; i < answerGrid.children.length; ++i)
                        answerGrid.children[i].opacity = 1
                    newQuestionButton.enabled = true
                    playQuestionButton.enabled = false
                    giveUpButton.enabled = false
                    answerGrid.enabled = false
                    answerGrid.opacity = 0.25
                }
            }
        },
        State {
            name: "waitingForAnswer"
            StateChangeScript {
                script: {
                    newQuestionButton.enabled = false
                    playQuestionButton.enabled = true
                    giveUpButton.enabled = true
                    answerGrid.enabled = true
                    answerGrid.opacity = 1
                }
            }
        }
    ]
    ParallelAnimation {
        id: animation
        
        loops: 2
        SequentialAnimation {
            PropertyAnimation { target: answerRectangle; property: "rotation"; to: -45; duration: 200 }
            PropertyAnimation { target: answerRectangle; property: "rotation"; to:  45; duration: 200 }
            PropertyAnimation { target: answerRectangle; property: "rotation"; to:   0; duration: 200 }
        }
        SequentialAnimation {
            PropertyAnimation { target: answerRectangle; property: "scale"; to: 1.2; duration: 300 }
            PropertyAnimation { target: answerRectangle; property: "scale"; to: 1.0; duration: 300 }
        }
        
        onStopped: exerciseView.state = "initial"
    }
}