import QtQuick 2.12
import "UKClock.js" as UKClock
import "Appearance.js" as Appearance

// Release 2.2.4's UI, measured in its original 1920 × 1080 CSS coordinate space.
// The owning window handles persistence and Luna calls; this item emits intent only.
FocusScope {
    id: root
    width: 1920
    height: 1080
    focus: true
    property string fontFamily: regularFont.name
    FontLoader { id:regularFont; source:"fonts/BarlowCondensed-Regular.ttf" }
    FontLoader { id:clockFont; source:"fonts/BarlowCondensed-SemiBold.ttf" }
    FontLoader { id:dateFont; source:"fonts/BarlowCondensed-Medium.ttf" }
    property string sceneName:"valley"
    property string styleName:"colour"
    property string framing:"wide"
    readonly property var appearanceState:Appearance.state(sceneName,landscape,styleName,themeMode,framing,motionEnabled)
    property int selectedIndex: 0
    property int lastTile: 0
    property string landscape: "autumn"
    property string period: "evening"
    property string themeMode: "auto"
    property bool motionEnabled: true
    property bool sceneBusy: false
    property int launchPendingIndex: -1
    property bool reducedMotion: false
    property string clockText: ""
    property string dateText: ""
    property string statusMessage: ""
    property bool statusVisible: false
    readonly property real designScale: Math.min(width / 1920, height / 1080)
    readonly property color headerInk: styleName === "ember" ? "#fff2dc" : sceneName === "lookout" ? (landscape === "winter" ? (["dawn","morning","noon","afternoon","evening"].indexOf(period)>=0?"#193242":"#fff2dc") : (["morning","evening"].indexOf(period)>=0?"#193242":"#fff2dc")) : landscape === "winter" && ["morning", "noon", "afternoon"].indexOf(period) >= 0 ? "#17334b" : landscape === "autumn" && ["dawn", "morning", "noon", "afternoon"].indexOf(period) >= 0 ? "#173b38" : "#fff2dc"
    readonly property real tileBacking: Appearance.buttonBacking(sceneName,landscape,styleName,period,framing)
    readonly property var themeModes: ["dawn", "morning", "noon", "afternoon", "evening", "dusk", "night"]
    readonly property var targetIds: ["youtube.leanback.v4", "bbc.iplayer.3.0", "com.fvp.itv", "com.fvp.ch4", "amazon", "com.webos.app.hdmi1", "com.webos.app.hdmi2", "com.webos.app.hdmi4", "com.webos.app.hdmi3"]
    readonly property var targetLabels: ["YouTube AdFree", "BBC iPlayer", "ITVX", "Channel 4", "Prime Video", "Xbox (HDMI 1)", "PS5 (HDMI 2)", "Switch (HDMI 4)", "Apple TV (HDMI 3)"]
    readonly property var logoFiles: ["youtube", "", "itvx", "channel4", "prime", "xbox", "playstation", "nintendoswitch", "appletv"]
    readonly property var logoWidths: [53.76, 0, 72.96, 48, 78.72, 53.76, 53.76, 53.76, 67.2]
    readonly property var logoHeights: [40.32, 0, 36.48, 53.76, 78.72, 53.76, 53.76, 53.76, 53.76]
    readonly property var tints: ["#ff3943", "#ff5ba9", "#d2fa30", "#8ef5cd", "#70c7ee", "#b3dd9b", "#91b9ef", "#f38d8f", "#ededed"]
    readonly property var footerIndices:[9]

    signal targetRequested(string appId, string label, int index)
    signal landscapeRequested(string landscape)
    signal sceneRequested(string name)
    signal styleRequested(string name)
    signal framingRequested(string mode)
    signal themeRequested(string mode)
    signal motionRequested(bool enabled)
    signal focusRequested(real x, real y)
    signal selectionRequested(int index, string targetId)

    function capitalized(value) { return value.length ? value.charAt(0).toUpperCase() + value.slice(1) : ""; }
    function alpha(colorValue, amount) { return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, amount); }
    function select(index) {
        selectedIndex = index>=0&&index<9?index:9;
        if (selectedIndex < 9) {
            lastTile = selectedIndex;
            selectionRequested(selectedIndex, targetIds[selectedIndex]);
        }
        forceActiveFocus();
        focusRequested(selectedIndex < 9 ? (selectedIndex / 8 - 0.5) * 42 : 0, selectedIndex < 9 ? 0 : 3);
    }
    function activate(index) {
        if (index < 9) {
            if (launchPendingIndex < 0) targetRequested(targetIds[index], targetLabels[index], index);
        } else if (index === 9) { appearance.open(); }
    }
    function applyAppearance(key,value) {
        if(key==='sceneChoice'){sceneRequested(value.scene);landscapeRequested(value.season);}
        else if(key==='lighting'){styleRequested(value.style);themeRequested(value.theme);}
        else if(key==='scene')sceneRequested(value);
        else if(key==='season')landscapeRequested(value);
        else if(key==='style')styleRequested(value);
        else if(key==='theme')themeRequested(value);
        else if(key==='framing')framingRequested(value);
        else if(key==='motion')motionRequested(value);
    }

    function showStatus(message) { statusMessage = message; statusVisible = true; statusTimer.restart(); }
    function updateClock() {
        var now=UKClock.parts(Date.now());
        clockText=UKClock.timeText(now);dateText=UKClock.dateText(now).toUpperCase();
    }

    property int nativeBackKey: -1
    function isBackKey(key) { return key===nativeBackKey||key===Qt.Key_Back||key===Qt.Key_Escape||key===461; }
    function handleKey(key, autoRepeat) {
        if(isBackKey(key))key=Qt.Key_Back;
        if(appearance.opened)return appearance.handle(key,autoRepeat);
        var index = selectedIndex;
        var footerPosition = footerIndices.indexOf(index);
        if (key === Qt.Key_Left && footerPosition >= 0) index = footerIndices[(footerPosition + footerIndices.length - 1) % footerIndices.length];
        else if (key === Qt.Key_Right && footerPosition >= 0) index = footerIndices[(footerPosition + 1) % footerIndices.length];
        else if (key === Qt.Key_Up && index >= 9) index = lastTile;
        else if (key === Qt.Key_Down && index < 9) index = 9;
        else if (key === Qt.Key_Left && index > 0 && index < 9) index--;
        else if (key === Qt.Key_Right && index < 8) index++;
        else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Select) {
            if (!autoRepeat) activate(index);
            return true;
        } else if (key === Qt.Key_Escape || key === Qt.Key_Back || key === 461) {
            return true; // Back only dismisses Appearance; Red opens LG Home.
        } else if ([Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].indexOf(key) < 0) return false;
        select(index);
        return true;
    }
    // LG dispatches its native Back key independently of browser keycode 461.
    // Consume the full gesture and act on release, so held/repeated Back cannot
    // close Appearance and then immediately exit the app on the same press.
    Keys.onPressed: {
        if(isBackKey(event.key))event.accepted=true;
        else event.accepted=handleKey(event.key,event.isAutoRepeat);
    }
    Keys.onReleased: {
        if(isBackKey(event.key)){
            event.accepted=true;
            if(!event.isAutoRepeat)handleKey(event.key,false);
        }
    }
    onVisibleChanged: if (visible) { updateClock(); forceActiveFocus(); }
    Component.onCompleted: { updateClock(); forceActiveFocus(); }
    Timer { id: statusTimer; interval: 5500; onTriggered: root.statusVisible = false }
    Timer { interval: 30000; running: root.visible; repeat: true; onTriggered: root.updateClock() }

    Item {
        id: stage
        width: 1920; height: 1080
        anchors.centerIn: parent
        scale: root.designScale

        Item {
            id: heading
            x: 99.828125; y: 48.59375; width: 1720.34375; height: 100
            Text {
                id: clockLabel
                anchors.left: parent.left; width: 320; horizontalAlignment: Text.AlignLeft
                text: root.clockText; color: root.headerInk
                transformOrigin: Item.TopLeft
                font.family: clockFont.name; font.weight: Font.DemiBold; font.pixelSize: 50; font.letterSpacing: 0.5
                renderType: Text.QtRendering
            }
            Text {
                anchors.left: parent.left; y: 60.625; width: 320; horizontalAlignment: Text.AlignLeft
                transformOrigin: Item.TopLeft
                text: root.dateText; color: root.headerInk; opacity: 0.82
                font.family: dateFont.name; font.weight: Font.Medium; font.pixelSize: 17; font.letterSpacing: 1.4
                renderType: Text.QtRendering
            }
        }

        Repeater {
            model: 9
            delegate: Item {
                id: tile
                readonly property bool chosen: !appearance.opened && root.selectedIndex === index
                readonly property color tint: root.tints[index]
                readonly property real cornerRadius: index < 5 ? 18.24 : 5.76
                x: Math.round(index < 5 ? 288 + index * 142.078125 : 1086.71875 + (index - 5) * 142.078125)
                y: Math.round(875.65625 + (chosen && !root.reducedMotion ? -3.78 : 0))
                width: index === 4 ? 119.0625 : 119.046875; height: 119.03125
                opacity: root.launchPendingIndex === index ? 0.65 : 1
                Behavior on y { enabled: !root.reducedMotion; NumberAnimation { duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.25, 0.1, 0.25, 1, 1, 1] } }
                // Snowy daylight needs a quiet local backing, without dimming the artwork.
                Rectangle {
                    anchors.fill: parent; radius: tile.cornerRadius
                    color: '#10191d'; opacity: root.tileBacking; antialiasing: true
                    Behavior on opacity { enabled: !root.reducedMotion; NumberAnimation { duration: 250 } }
                }
                // CSS linear-gradient(145deg, tint 7.5%, tint 2%) in one native draw;
                // the signed-distance edge also clips the gradient to its round corners.
                ShaderEffect {
                    anchors.fill: parent
                    property vector2d boxSize: Qt.vector2d(width, height)
                    property real cornerRadius: tile.cornerRadius
                    property color tint: tile.tint
                    property real focusedAmount: tile.chosen ? 1 : 0
                    Behavior on focusedAmount { enabled: !root.reducedMotion; NumberAnimation { duration: 140 } }
                    fragmentShader: "
                        varying highp vec2 qt_TexCoord0;
                        uniform lowp float qt_Opacity;
                        uniform highp vec2 boxSize;
                        uniform highp float cornerRadius;
                        uniform lowp vec4 tint;
                        uniform highp float focusedAmount;
                        void main() {
                            highp vec2 p = (qt_TexCoord0 - vec2(0.5)) * boxSize;
                            highp vec2 d = vec2(0.573576436, 0.819152044);
                            highp float t = clamp(dot(p, d) / dot(boxSize, abs(d)) + 0.5, 0.0, 1.0);
                            highp vec2 q = abs(p) - (boxSize * 0.5 - vec2(cornerRadius));
                            highp float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - cornerRadius;
                            lowp float a = mix(mix(0.075, 0.02, t), 0.13, focusedAmount) * (1.0 - smoothstep(-0.6, 0.6, dist));
                            gl_FragColor = vec4(tint.rgb * a, a) * qt_Opacity;
                        }"
                }
                Rectangle {
                    anchors.fill: parent; radius: tile.cornerRadius
                    color: "transparent"; border.width: tile.chosen ? 2 : 1
                    border.color: tile.chosen ? "#fff4df" : root.alpha(tile.tint, 0.16)
                    antialiasing: true
                    Behavior on border.color { enabled: !root.reducedMotion; ColorAnimation { duration: 140 } }
                }
                // Original SVG rasterized once at final display resolution.
                // Pixel-aligned 1:1 sampling avoids a second downsampling pass.
                Image {
                    visible: index !== 1
                    anchors.centerIn: parent
                    width: Math.round(root.logoWidths[index]); height: Math.round(root.logoHeights[index])
                    source: root.logoFiles[index] ? "logos/" + root.logoFiles[index] + ".png" : ""
                    fillMode: Image.Stretch
                    smooth: true; mipmap: false; asynchronous: false
                }
                Item {
                    visible: index === 1
                    width: parent.width; height: 43.609375; anchors.centerIn: parent
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3.25
                        Repeater {
                            model: ["B", "B", "C"]
                            Rectangle {
                                width: 10.546875; height: 10.546875; color: "#ff5ba9"
                                Text {
                                    id: bbcLetter
                                    anchors.centerIn: parent; text: modelData; color: "#241a25"
                                    font.family: "Arial"; font.pixelSize: 8; font.weight: Font.Black
                                    scale: 8.256 / 8
                                    renderType: Text.QtRendering
                                }
                            }
                        }
                    }
                    Text {
                        id: iplayerLabel
                        anchors.horizontalCenter: parent.horizontalCenter; y: 12.703125
                        scale: 26.88 / 27; transformOrigin: Item.Top
                        text: "iPlayer"; color: "#ff5ba9"
                        font.family: "Arial"; font.pixelSize: 27; font.bold: true; font.letterSpacing: -1.6128 / scale
                        renderType: Text.QtRendering
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: root.select(index)
                    onClicked: { root.select(index); root.activate(index); }
                }
                Accessible.role: Accessible.Button
                Accessible.name: root.targetLabels[index]
                Accessible.onPressAction: { root.select(index); root.activate(index); }
            }
        }
        Rectangle {
            x: 1030.546875; y: 894.84375; width: 1; height: 80.625
            gradient: Gradient {
                GradientStop { position: 0; color: "#00fff0dc" }
                GradientStop { position: 0.25; color: "#40fff0dc" }
                GradientStop { position: 0.75; color: "#40fff0dc" }
                GradientStop { position: 1; color: "#00fff0dc" }
            }
        }
        Item {
            id: footer
            x: 99.828125; y: 1021.0625; width: 1720.34375; height: 33.03125
            // Remote shortcut hint, not a second focusable navigation control.
            Row {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                spacing: 10; opacity: 0.78
                Rectangle { width: 14; height: 14; radius: 4; color: "#d95c57"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "LG Home"; font.family: regularFont.name; font.pixelSize: 21; font.letterSpacing: 0.4; color: "#efe1c7" }
                Accessible.role: Accessible.StaticText
                Accessible.name: "Red button: LG Home"
            }
            Rectangle {
                anchors.right:parent.right;y:-5;width:114;height:44;radius:5
                color:root.selectedIndex===9&&!appearance.opened?"#15fff0dc":"transparent"
                border.width:root.selectedIndex===9&&!appearance.opened?1:0;border.color:"#fff1dd"
                Text {anchors.centerIn:parent;text:"Appearance";font.family:regularFont.name;font.pixelSize:21;font.letterSpacing:.4;color:"#efe1c7"}
                MouseArea {anchors.fill:parent;hoverEnabled:true;onEntered:root.select(9);onClicked:{root.select(9);root.activate(9);}}
                Accessible.role:Accessible.Button;Accessible.name:"Appearance"
                Accessible.onPressAction:{root.select(9);root.activate(9);}
            }
        }
        AppearancePanel {
            id:appearance;z:10
            selectionState:root.appearanceState;period:root.period;fontFamily:root.fontFamily;busy:root.sceneBusy
            onChanged:root.applyAppearance(key,value)
            onDismissed:root.select(9)
        }

        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 120
            y: 1080 - 129.6 - height
            width: Math.min(921.6, statusText.implicitWidth + 42.24)
            height: statusText.implicitHeight + 30.24
            color: "#ed1b1525"; radius: 9.6
            opacity: root.statusVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Text {
                id: statusText
                anchors.fill: parent; anchors.margins: 15.12; anchors.leftMargin: 21.12; anchors.rightMargin: 21.12
                text: root.statusMessage; wrapMode: Text.WordWrap
                color: "#fff4e1"; font.family: root.fontFamily; font.pixelSize: 20
                renderType: Text.QtRendering
            }
        }
    }
}
