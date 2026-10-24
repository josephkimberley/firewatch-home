import QtQuick 2.12
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Eos.Window 0.1
import WebOSServices 1.0
import WebOS.Global 1.0
import "LauncherConfig.js" as LauncherConfig
import "ConfigStore.js" as ConfigStore

WebOSWindow {
    id: root
    title: "Firewatch Home"
    appId: "uk.local.minimalhome.native"
    width: 1920; height: 1080
    visible: true
    color: "#101a20"
    property var launcherConfig: LauncherConfig.defaults()
    property var installedApps: []
    property bool inventoryAvailable: false
    property string inventoryMessage: "Loading installed apps…"
    property bool configLoaded: false
    property bool setupOffered: false
    property bool hasSavedAppearance: false
    property bool inventoryAwaiting: false
    property var configCompletion: null
    property var configRequest: null
    Settings {
        id: launcherSettings
        fileName: "/media/developer/.minimalhome-native/launcher.ini"
        category: "Launcher"
        property string current: ""
        property string previous: ""
        property bool configured: false
        property bool defaultsApplied: false
    }
    function applyConfig(config, initial) {
        LauncherConfig.validateConfig(config);
        root.launcherConfig=JSON.parse(JSON.stringify(config));
        if(initial&&!root.hasSavedAppearance&&!launcherSettings.defaultsApplied) {
            preferences.landscape=config.scene.theme==="winter"?"winter":"autumn";
            preferences.theme=config.scene.period;preferences.motion=config.scene.motion;
            launcherSettings.defaultsApplied=true;launcherSettings.sync();
        }
        controls.select(preferences.selected);
    }
    function saveConfig(config) {
        try {
            config=LauncherConfig.parse(JSON.stringify(config));
            // Keep the previous known-good value; QSettings manages disk persistence.
            launcherSettings.previous=JSON.stringify(root.launcherConfig);
            launcherSettings.current=JSON.stringify(config);
            launcherSettings.configured=true;
            launcherSettings.sync();
            root.applyConfig(config,false);
            controls.setupSaved();
            controls.showStatus("Apps and inputs saved.");
        } catch(e) {controls.setupSaveFailed("Could not save: "+String(e.message||e));}
    }
    function loadConfig() {
        var request=new XMLHttpRequest(),finished=false;
        function finish(text) {
            if(finished)return;finished=true;configTimeout.stop();root.configCompletion=null;root.configRequest=null;
            var restored=ConfigStore.restore(launcherSettings.current,launcherSettings.previous,text,LauncherConfig.parse);
            root.applyConfig(restored.config||LauncherConfig.defaults(),true);
            root.configLoaded=true;
            if(restored.recovered)controls.showStatus("Saved setup could not be read. A working configuration was restored.");
            setupOffer.restart();
        }
        root.configCompletion=finish;root.configRequest=request;configTimeout.restart();
        request.onreadystatechange=function(){if(request.readyState===XMLHttpRequest.DONE)finish(request.status===0||request.status===200?request.responseText:"");};
        try{request.open("GET",Qt.resolvedUrl("launcher-config.json"));request.send();}catch(e){finish("");}
    }
    function inventoryFailed() {
        inventoryTimeout.stop();root.inventoryAwaiting=false;root.inventoryAvailable=false;
        root.inventoryMessage="Installed apps unavailable. You can still edit HDMI inputs and keep your existing apps.";
    }
    function refreshInventory() {
        if(root.inventoryAwaiting)return;
        root.inventoryAwaiting=true;root.inventoryMessage="Loading installed apps…";inventoryTimeout.restart();
        try {if(!appInventory.callService({}))root.inventoryFailed();}catch(e){root.inventoryFailed();}
    }
    Service {
        id: appInventory
        appId:root.appId
        service:"com.webos.applicationManager"
        method:"listApps"
        onCallSuccess: {
            if(!root.inventoryAwaiting)return;
            inventoryTimeout.stop();root.inventoryAwaiting=false;
            try{root.installedApps=ConfigStore.inventory(JSON.parse(JSON.stringify(response)));root.inventoryAvailable=true;root.inventoryMessage=root.installedApps.length?"":"No visible apps were returned.";}
            catch(e){root.inventoryFailed();}
        }
        onCallFailure:if(root.inventoryAwaiting)root.inventoryFailed()
        onError:if(root.inventoryAwaiting)root.inventoryFailed()
    }
    Timer {id:configTimeout;interval:2000;onTriggered:{
        var complete=root.configCompletion,request=root.configRequest;
        if(complete)complete("");
        if(request){try{request.abort();}catch(e){}}
    }}
    Timer {id:inventoryTimeout;interval:4000;onTriggered:root.inventoryFailed()}
    Timer {id:inventoryStart;interval:1200;onTriggered:root.refreshInventory()}
    Timer {id:setupOffer;interval:500;onTriggered:{
        if(!scene.ready){restart();return;}
        if(!launcherSettings.configured&&!root.setupOffered){root.setupOffered=true;controls.openSetup(true);}
    }}
    property bool validationMode: false
    property double createdAt: Date.now()
    property bool firstFrame: false
    property bool firstArtFrame: false
    property int artworkFrames: 0
    StartupCover { id: startupCover; appId: root.appId; onTrace: root.stamp(label,detail) }
    property int launchPending: -1
    property var launchService: null
    property string launchTarget: ""
    property int launchSerial: 0
    property bool launchTokenAccepted: false
    Settings { id: startupTiming; fileName: "/media/developer/.minimalhome-native/startup-timing.ini"; property string events: "[]" }
    property var startupEvents: []
    Timer {id:startupSave;interval:250;onTriggered:startupTiming.events=JSON.stringify(root.startupEvents)}
    function stamp(label, detail) {
        var event={label:label,at:Date.now(),elapsed:Date.now()-createdAt,detail:detail||null};
        console.log("MINIMALHOME_NATIVE " + JSON.stringify(event));
        if(startupEvents.length<16&&/^(qml-complete|first-window-frame|scene-ready|first-artwork-frame|cover-)/.test(label)){startupEvents.push(event);startupSave.restart();}
    }
    function disposeLaunchService() {
        var old=launchService;launchService=null;
        if(old)old.destroy();
    }
    function resetLaunch() {
        launchSerial++;launchRetry.stop();launchTimeout.stop();
        launchPending=-1;launchTarget="";launchTokenAccepted=false;
        disposeLaunchService();
    }
    function launch(appId, label, index) {
        root.stamp("launch-attempt",{id:appId,pending:launchPending});
        if(launchPending>=0||!root.active)return;
        startupCover.cancel();resetLaunch();launchTarget=appId;launchPending=index;
        launchTimeout.restart();attemptLaunch();
    }
    function attemptLaunch() {
        if(launchPending<0||!root.active||launchTokenAccepted)return;
        var serial=launchSerial;
        try {
            // Creating a fresh Service re-runs ApplicationClient registration.
            // Reusing a failed Service can fall back to the wrong client type.
            launchService=launchServiceComponent.createObject(root,{attemptSerial:serial});
            if(!launchService)throw new Error("Could not create launch service");
            var token=launchService.callService({id:launchTarget});
            // A synchronous failure callback may already have cancelled this attempt.
            if(serial!==launchSerial)return;
            root.stamp("launch-token",{token:token});
            if(token){launchTokenAccepted=true;launchRetry.stop();}
            else {disposeLaunchService();launchRetry.restart();}
        } catch(error) {
            root.stamp("launch-exception",String(error));resetLaunch();
            controls.showStatus("Could not open that app.");
        }
    }
    function finishLaunch(client, serial, succeeded, detail) {
        if(serial!==launchSerial||client!==launchService)return;
        root.stamp(succeeded?"launch-accepted":"launch-failed",detail);
        resetLaunch();
        if(!succeeded)controls.showStatus("Could not open that app.");
    }
    Settings {
        id: preferences
        fileName: "/media/developer/.minimalhome-native/preferences.ini"
        category: "MinimalHome"
        property string landscape: "winter"
        property string sceneName: "valley"
        property string styleName: "colour"
        property string framing: "wide"
        property string theme: "auto"
        property bool motion: true
        property int selected: 4
    }
    Component {
        id: launchServiceComponent
        Service {
            id: client
            property int attemptSerial: -1
            appId: root.appId
            service: "com.webos.applicationManager"
            method: "launch"
            onResponse: if(attemptSerial===root.launchSerial&&client===root.launchService)root.stamp("service-response",payload)
            onCallSuccess: root.finishLaunch(client,attemptSerial,true,response)
            onCallFailure: root.finishLaunch(client,attemptSerial,false,response)
            onError: root.finishLaunch(client,attemptSerial,false,errorText)
        }
    }
    Timer {id:launchRetry;interval:300;onTriggered:root.attemptLaunch()}
    Timer {id:launchTimeout;interval:6500;onTriggered:{root.resetLaunch();controls.showStatus("That app is taking longer to open.");}}
    Item {
        id: stage
        width:1920;height:1080;anchors.centerIn:parent
        scale:Math.min(root.width/1920,root.height/1080)
        PaintedScene {
            id: scene
            timeZone:root.launcherConfig.clock.timeZone
            season:preferences.landscape
            sceneName:preferences.sceneName
            styleName:preferences.styleName
            framing:preferences.framing
            theme:preferences.theme
            playing:preferences.motion && root.active
            onFirstArtworkFrame: root.stamp("scene-ready")
            onLoadFailed:controls.showStatus(message)
        }
        HomeControls {
            id: controls
            nativeBackKey: WebOS.Key_webOS_Back
            launcherConfig:root.launcherConfig
            installedApps:root.installedApps
            inventoryAvailable:root.inventoryAvailable
            inventoryMessage:root.inventoryMessage
            onSetupRequested:root.saveConfig(config)
            onLgHomeRequested:root.launch("com.webos.app.home","LG Home",0)
            landscape:preferences.landscape
            sceneName:preferences.sceneName
            styleName:preferences.styleName
            framing:preferences.framing
            period:scene.period.toLowerCase()
            themeMode:preferences.theme
            motionEnabled:preferences.motion
            sceneBusy:scene.pendingBank>=0
            launchPendingIndex:root.launchPending
            onTargetRequested: root.launch(appId,label,index)
            onLandscapeRequested: preferences.landscape=landscape
            onSceneRequested: preferences.sceneName=name
            onStyleRequested: preferences.styleName=name
            onFramingRequested: preferences.framing=mode
            onThemeRequested: preferences.theme=mode
            onMotionRequested: preferences.motion=enabled
            onSelectionRequested: preferences.selected=index
            onFocusRequested: scene.setFocusPoint(x,y)
        }
    }
    onActiveChanged: {
        root.resetLaunch();
        if(active){controls.forceActiveFocus();scene.sample();}
    }
    Component.onCompleted: {root.windowProperties["_WEBOS_ACCESS_POLICY_KEYS_BACK"] = "true";if(preferences.styleName!=="colour")preferences.styleName="colour";root.hasSavedAppearance=preferences.value("landscape","")!==""||preferences.value("sceneName","")!=="";root.loadConfig();inventoryStart.start();controls.select(preferences.selected);root.stamp("qml-complete",{width:width,height:height,dpr:Screen.devicePixelRatio});}
    // Disconnect after the two-frame artwork barrier: no per-frame diagnostic JS work.
    Connections {
        target: root
        enabled: !root.firstArtFrame
        onFrameSwapped: {
            if(!root.firstFrame){root.firstFrame=true;root.stamp("first-window-frame");}
            if(scene.ready&&!root.firstArtFrame){
                root.artworkFrames++;
                if(root.artworkFrames>=2){root.firstArtFrame=true;root.stamp("first-artwork-frame");startupCover.artworkReady=true;}
                else root.update();
            }
        }
    }
}
