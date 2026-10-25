import QtQuick 2.12
Rectangle {
    width: 1280; height: 640; color: "#320508"
    Image {
        anchors.fill: parent
        source: "../../src/native/assets/autumn/evening-vibrant.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }
    FontLoader { id: titleFont; source: "../../src/native/fonts/BarlowCondensed-SemiBold.ttf" }
    FontLoader { id: bodyFont; source: "../../src/native/fonts/BarlowCondensed-Regular.ttf" }
    Text {
        x: 52; y: 500
        text: "FIREWATCH HOME"
        font.family: titleFont.name; font.pixelSize: 56; font.letterSpacing: 2
        color: "#fff3d9"
    }
    Text {
        x: 55; y: 573
        text: "A HOME SCREEN FOR LG webOS TVs  ·  UNOFFICIAL FAN PROJECT"
        font.family: bodyFont.name; font.pixelSize: 19; font.letterSpacing: 1.3
        color: "#e8cfb0"
    }
}
