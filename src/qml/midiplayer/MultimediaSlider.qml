import QtQuick 2.5
import QtQuick.Controls 1.4

Item {
    property alias source: sliderImage.source;
    property alias minimumValue: slider.minimumValue;
    property alias maximumValue: slider.maximumValue;
    property alias value: slider.value;

    width: sliderImage.width; height: parent.height

    Slider {
        id: slider
        
        height: parent.height - sliderImage.height - 5
        orientation: Qt.Vertical
        activeFocusOnPress: true
    }
    Image {
        id: sliderImage

        width: 15; height: 15
        anchors { top: slider.bottom; topMargin: 5; horizontalCenter: slider.horizontalCenter }
    }
}