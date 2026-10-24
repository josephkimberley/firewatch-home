import QtQuick 2.12
import "RuntimeClock.js" as RuntimeClock
import "Appearance.js" as Appearance
import "LauncherConfig.js" as LauncherConfig

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
    property var launcherConfig: LauncherConfig.defaults()
    onLauncherConfigChanged:updateClock()
    property var installedApps: []
    property bool inventoryAvailable: false
    property string inventoryMessage: "App discovery unavailable. Existing shortcuts and HDMI inputs can still be edited."
    readonly property var targetModel: LauncherConfig.targets(launcherConfig)
    readonly property int targetCount: targetModel.length
    readonly property int appCount: launcherConfig.apps.length
    readonly property int inputCount: launcherConfig.inputs.length
    readonly property var tileLayout: LauncherConfig.layout(launcherConfig)
    readonly property int appearanceIndex: targetCount
    readonly property int setupIndex: targetCount + 1
    readonly property int lgHomeIndex: targetCount + 2
    readonly property var footerIndices: [lgHomeIndex, setupIndex, appearanceIndex]
    readonly property var appTints: ["#ff3943", "#ff5ba9", "#d2fa30", "#8ef5cd", "#70c7ee"]
    readonly property var inputTints: ["#b3dd9b", "#91b9ef", "#f38d8f", "#ededed"]
    onTargetCountChanged: {
        lastTile = Math.min(lastTile, targetCount - 1);
        selectedIndex = LauncherConfig.clampSelection(selectedIndex, targetCount);
    }
    signal setupRequested(var config)
    signal lgHomeRequested()
    function openSetup(firstRun) { setup.open(firstRun === true); }
    function setupSaved() { setup.saved(); }
    function setupSaveFailed(message) { setup.saveFailed(message); }

    signal targetRequested(string appId, string label, int index)
    signal landscapeRequested(string landscape)
    signal sceneRequested(string name)
    signal styleRequested(string name)
    signal framingRequested(string mode)
    signal themeRequested(string mode)
    signal motionRequested(bool enabled)
    signal focusRequested(real x, real y)
    signal selectionRequested(int index, string targetId)

    function iconFor(target) {
        if(target.icon)return target.icon;
        for(var i=0;i<installedApps.length;i++) {
            if(installedApps[i].id===target.id)return installedApps[i].iconURL||"";
        }
        return "";
    }
    function capitalized(value) { return value.length ? value.charAt(0).toUpperCase() + value.slice(1) : ""; }
    function alpha(colorValue, amount) { return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, amount); }
    function select(index) {
        selectedIndex = LauncherConfig.clampSelection(index, targetCount);
        if (selectedIndex < targetCount) {
            lastTile = selectedIndex;
            selectionRequested(selectedIndex, targetModel[selectedIndex].id);
        }
        forceActiveFocus();
        focusRequested(selectedIndex < targetCount && targetCount > 1 ? (selectedIndex / (targetCount - 1) - 0.5) * 42 : 0, selectedIndex < targetCount ? 0 : 3);
    }
    function activate(index) {
        if (index >= 0 && index < targetCount) {
            if (launchPendingIndex < 0) targetRequested(targetModel[index].id, targetModel[index].label, index);
        } else if (index === appearanceIndex) { appearance.open(); }
        else if (index === setupIndex) { setup.open(false); }
        else if (index === lgHomeIndex) { lgHomeRequested(); }
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
        var now=RuntimeClock.parts(Date.now(),launcherConfig.clock.timeZone);
        clockText=RuntimeClock.timeText(now,launcherConfig.clock.format);dateText=RuntimeClock.dateText(now).toUpperCase();
    }

    property int nativeBackKey: -1
    function isBackKey(key) { return key===nativeBackKey||key===Qt.Key_Back||key===Qt.Key_Escape||key===461; }
    function handleKey(key, autoRepeat) {
        if (key === Qt.Key_Red) { if(!autoRepeat) lgHomeRequested(); return true; }
        if(isBackKey(key))key=Qt.Key_Back;
        if(setup.opened)return setup.handle(key,autoRepeat);
        if(appearance.opened)return appearance.handle(key,autoRepeat);
        var index = selectedIndex;
        var footerPosition = footerIndices.indexOf(index);
        if (key === Qt.Key_Left && footerPosition >= 0) index = footerIndices[(footerPosition + footerIndices.length - 1) % footerIndices.length];
        else if (key === Qt.Key_Right && footerPosition >= 0) index = footerIndices[(footerPosition + 1) % footerIndices.length];
        else if (key === Qt.Key_Up && index >= targetCount) index = lastTile;
        else if (key === Qt.Key_Down && index < targetCount) index = appearanceIndex;
        else if (key === Qt.Key_Left && index > 0 && index < targetCount) index--;
        else if (key === Qt.Key_Right && index < targetCount - 1) index++;
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
            model: root.targetCount
            delegate: Item {
                id: tile
                readonly property bool chosen: !appearance.opened && !setup.opened && root.selectedIndex === index
                readonly property var target: root.targetModel[index] || {id:"",label:"",icon:"",group:"app"}
                readonly property color tint: target.group === "app" ? root.appTints[index % root.appTints.length] : root.inputTints[Math.max(0, index - root.appCount) % root.inputTints.length]
                readonly property real cornerRadius: target.group === "app" ? 18.24 : 5.76
                x: Math.round(root.tileLayout.positions[index] === undefined ? 960 : root.tileLayout.positions[index])
                y: Math.round(875.65625 + (chosen && !root.reducedMotion ? -3.78 : 0))
                width: root.tileLayout.width; height: 119.03125
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
                    property real baseOpacity: tile.target.group === "input" ? root.launcherConfig.layout.inputTintOpacity : 0.075
                    Behavior on focusedAmount { enabled: !root.reducedMotion; NumberAnimation { duration: 140 } }
                    fragmentShader: "
                        varying highp vec2 qt_TexCoord0;
                        uniform lowp float qt_Opacity;
                        uniform highp vec2 boxSize;
                        uniform highp float cornerRadius;
                        uniform lowp vec4 tint;
                        uniform highp float focusedAmount;
                        uniform highp float baseOpacity;
                        void main() {
                            highp vec2 p = (qt_TexCoord0 - vec2(0.5)) * boxSize;
                            highp vec2 d = vec2(0.573576436, 0.819152044);
                            highp float t = clamp(dot(p, d) / dot(boxSize, abs(d)) + 0.5, 0.0, 1.0);
                            highp vec2 q = abs(p) - (boxSize * 0.5 - vec2(cornerRadius));
                            highp float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - cornerRadius;
                            lowp float a = mix(mix(baseOpacity, baseOpacity * 0.266667, t), 0.13, focusedAmount) * (1.0 - smoothstep(-0.6, 0.6, dist));
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
                Image {
                    id: appIcon
                    anchors.centerIn: parent; width: 64; height: 64
                    source: root.iconFor(tile.target)
                    fillMode: Image.PreserveAspectFit
                    smooth: true; mipmap: false; asynchronous: true
                }
                // Readable local fallback for omitted, missing or invalid icons.
                Column {
                    anchors.centerIn: parent; width: parent.width - 14; spacing: 7
                    visible: appIcon.status !== Image.Ready
                    Text {
                        visible: tile.target.group === "input" && tile.target.label !== "HDMI " + tile.target.port
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "HDMI " + (tile.target.port || "")
                        color: tile.tint; font.family: root.fontFamily; font.pixelSize: 17
                    }
                    Text {
                        width: parent.width; horizontalAlignment: Text.AlignHCenter
                        text: tile.target.label; color: "#fff4df"
                        textFormat: Text.PlainText; wrapMode: Text.WordWrap
                        maximumLineCount: 2; elide: Text.ElideRight
                        font.family: root.fontFamily; font.pixelSize: 23
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: root.select(index)
                    onClicked: { root.select(index); root.activate(index); }
                }
                Accessible.role: Accessible.Button
                Accessible.name: tile.target.label
                Accessible.onPressAction: { root.select(index); root.activate(index); }
            }
        }
        Rectangle {
            visible: root.tileLayout.dividerVisible
            x: root.tileLayout.dividerX; y: 894.84375; width: 1; height: 80.625
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
            Rectangle {
                anchors.left: parent.left; y: -5; width: 116; height: 44; radius: 5
                color: root.selectedIndex === root.lgHomeIndex && !appearance.opened && !setup.opened ? "#15fff0dc" : "transparent"
                border.width: root.selectedIndex === root.lgHomeIndex && !appearance.opened && !setup.opened ? 1 : 0
                border.color: "#fff1dd"
                Row {
                    anchors.centerIn: parent; spacing: 10; opacity: 0.78
                    Rectangle {width:14;height:14;radius:4;color:"#d95c57";anchors.verticalCenter:parent.verticalCenter}
                    Text {text:"LG Home";font.family:regularFont.name;font.pixelSize:21;font.letterSpacing:.4;color:"#efe1c7"}
                }
                MouseArea {anchors.fill:parent;hoverEnabled:true;onEntered:root.select(root.lgHomeIndex);onClicked:root.lgHomeRequested()}
                Accessible.role: Accessible.Button; Accessible.name: "LG Home; red button shortcut"
                Accessible.onPressAction: root.lgHomeRequested()
            }
            Row {
                anchors.right: parent.right; y: -5; spacing: 20
                Repeater {
                    model: [{label:"Apps & Inputs", index:root.setupIndex}, {label:"Appearance", index:root.appearanceIndex}]
                    Rectangle {
                        width: modelData.label === "Appearance" ? 114 : 132; height: 44; radius: 5
                        color: root.selectedIndex === modelData.index && !appearance.opened && !setup.opened ? "#15fff0dc" : "transparent"
                        border.width: root.selectedIndex === modelData.index && !appearance.opened && !setup.opened ? 1 : 0
                        border.color: "#fff1dd"
                        Text {anchors.centerIn:parent;text:modelData.label;font.family:regularFont.name;font.pixelSize:21;font.letterSpacing:.4;color:"#efe1c7"}
                        MouseArea {anchors.fill:parent;hoverEnabled:true;onEntered:root.select(modelData.index);onClicked:{root.select(modelData.index);root.activate(modelData.index);}}
                        Accessible.role: Accessible.Button; Accessible.name: modelData.label
                        Accessible.onPressAction:{root.select(modelData.index);root.activate(modelData.index);}
                    }
                }
            }
        }
        AppsInputsPanel {
            id: setup; z: 12
            fontFamily: root.fontFamily
            launcherConfig: root.launcherConfig
            installedApps: root.installedApps
            inventoryAvailable: root.inventoryAvailable
            inventoryMessage: root.inventoryMessage
            onSaveRequested: function(value) { root.setupRequested(value); }
            onDismissed: root.select(root.setupIndex)
        }
        AppearancePanel {
            id:appearance;z:10
            selectionState:root.appearanceState;period:root.period;fontFamily:root.fontFamily;busy:root.sceneBusy
            onChanged:root.applyAppearance(key,value)
            onDismissed:root.select(root.appearanceIndex)
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
