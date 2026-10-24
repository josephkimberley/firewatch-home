import QtQuick 2.12
import "SceneMath.js" as MathScene
import "RuntimeClock.js" as RuntimeClock
import "Appearance.js" as Appearance
import "SceneShaders.js" as Shaders

Item {
    id: scene
    width: 1920; height: 1080
    clip:true
    property string timeZone:"system"
    onTimeZoneChanged:scheduleSample()
    property string season: "autumn"
    property string sceneName:"valley"
    property string styleName:"colour"
    property string framing:"wide"
    property string displayedScene:"valley"
    property string displayedStyle:"colour"
    property string displayedSeason:"autumn"
    property string displayedFraming:"wide"
    property real winterNightAmount:0
    property bool wantWinterStars:false
    readonly property bool starAssetsReady:starless.status===Image.Ready&&valleyMaskImage.status===Image.Ready&&frontMaskImage.status===Image.Ready
    // Image status handlers can run before this derived binding is reevaluated.
    // Retry when the combined readiness value changes, including a cold Night launch.
    onStarAssetsReadyChanged: if(starAssetsReady)commit()
    property var pendingAppearance:null
    readonly property real artworkZoom:displayedScene==="lookout"?1:1.025
    readonly property real birdZoom:displayedScene==="lookout"&&displayedFraming==="close"?1.65:artworkZoom
    property real winterSourceA:0
    property real winterSourceB:0
    signal loadFailed(string message)
    property string theme: "auto"
    property bool playing: true
    property bool ready: false
    property string period: "Evening"
    property real time: 0
    property real night: 0
    property real blend: 0
    property real panX: 0
    property real panY: 0
    property real targetX: 0
    property real targetY: 0
    property real lastTime: 0
    property int activeBank: -1
    property int pendingBank: -1
    property var pendingLight: null
    property string requestedKey: ""
    property bool initialized: false
    // Scene cards change scene and season together. Coalesce their binding updates
    // before touching either texture bank; a cached intermediate scene is not a choice.
    property bool selectionQueued: false
    function scheduleSample() {
        selectionQueued=true;selectionTimer.restart();
    }
    Timer {id:selectionTimer;interval:0;repeat:false;onTriggered:{scene.selectionQueued=false;scene.sample();}}
    property bool assigningSources: false
    property bool same0: false
    property bool same1: false
    signal firstArtworkFrame()
    function setFocusPoint(x,y) { targetX=0;targetY=0; }
    function setTheme(value) { theme=value; }
    function setPlaying(value) { playing=value; }
    function sample() {
        if(!initialized||selectionQueued)return;
        var settings=Appearance.state(sceneName,season,styleName,theme,framing,playing);
        var now=RuntimeClock.parts(Date.now(),timeZone),light=settings.style==="ember"?{a:4,b:4,mix:0}:MathScene.sample(settings.theme,now.decimalHour);
        var nextWinterStars=settings.scene==='valley'&&settings.season==='winter'&&settings.style==='colour'&&(light.a===6||light.b===6);
        period=MathScene.title(light.mix<.5?light.a:light.b);
        var key=settings.scene+":"+settings.season+":"+settings.style+":"+light.a+":"+light.b+":"+(settings.scene==="lookout"?settings.framing:"wide");
        if(key===requestedKey) {
            if(pendingBank>=0){pendingLight=light;commit();}
            else {blend=light.mix;winterNightAmount=wantWinterStars?((light.a===6?1:0)*(1-blend)+(light.b===6?1:0)*blend):0;night=MathScene.phaseNights[light.a]*(1-light.mix)+MathScene.phaseNights[light.b]*light.mix;}
            return;
        }
        assigningSources=true;
        requestedKey=key;pendingLight=light;pendingAppearance=settings;pendingBank=activeBank===0?1:0;
        var a=pendingBank===0?imageA0:imageA1,b=pendingBank===0?imageB0:imageB1;
        wantWinterStars=nextWinterStars;
        if(pendingBank===0)same0=light.a===light.b;else same1=light.a===light.b;
        a.source=Qt.resolvedUrl(Appearance.source(settings.scene,settings.season,settings.style,light.a,settings.framing));
        b.source=light.a===light.b?"":Qt.resolvedUrl(Appearance.source(settings.scene,settings.season,settings.style,light.b,settings.framing));
        assigningSources=false;
        commit();
    }
    function commit() {
        if(selectionQueued||assigningSources||pendingBank<0||!pendingLight)return;
        var a=pendingBank===0?imageA0:imageA1,b=pendingBank===0?imageB0:imageB1;
        if(a.status===Image.Error||b.status===Image.Error){pendingBank=-1;loadFailed("That scene could not load. Choose another appearance.");return;}
        if(wantWinterStars&&!starAssetsReady){
            if(starless.status===Image.Error||valleyMaskImage.status===Image.Error||frontMaskImage.status===Image.Error){pendingBank=-1;loadFailed("The winter sky could not load. Choose another scene.");}
            return;
        }
        if(a.status!==Image.Ready||((pendingBank===0?!same0:!same1)&&b.status!==Image.Ready))return;
        activeBank=pendingBank;pendingBank=-1;
        displayedScene=pendingAppearance.scene;displayedStyle=pendingAppearance.style;displayedSeason=pendingAppearance.season;displayedFraming=pendingAppearance.framing;
        winterSourceA=wantWinterStars&&pendingLight.a===6?1:0;
        winterSourceB=wantWinterStars&&pendingLight.b===6?1:0;
        blend=pendingLight.mix;
        winterNightAmount=wantWinterStars?((pendingLight.a===6?1:0)*(1-blend)+(pendingLight.b===6?1:0)*blend):0;
        night=MathScene.phaseNights[pendingLight.a]*(1-blend)+MathScene.phaseNights[pendingLight.b]*blend;
        var first=!ready;ready=true;
        if(first)firstArtworkFrame();
    }
    function frame() {
        var dt=Math.min(.1,Math.max(0,time-lastTime));lastTime=time;
        var k=1-Math.exp(-dt*2.2);panX+=(targetX-panX)*k;panY+=(targetY-panY)*k;
        for(var i=0;i<7;i++){var bird=birds.itemAt(i);if(bird)bird.update(MathScene.birdState(time,i,panX*.25,panY*.25,night));}
    }
    onFramingChanged: scheduleSample()
    onSceneNameChanged: scheduleSample()
    onStyleNameChanged: scheduleSample()
    onSeasonChanged: scheduleSample()
    onThemeChanged: scheduleSample()
    onTimeChanged: if(initialized)frame()
    onNightChanged: if(initialized)frame()
    Component.onCompleted: {initialized=true;sample();frame();}
    NumberAnimation on time { from: 0; to: 86400; duration: 86400000; loops: Animation.Infinite; running: true; paused:!scene.playing||!scene.visible }
    Timer {interval:1000;repeat:true;running:scene.visible&&scene.theme==="auto";onTriggered:scene.sample()}
    // Two complete banks keep the previous scene intact until both new textures
    // are ready. Season changes can never show mismatched halves or phases.
    Image{id:imageA0;visible:false;asynchronous:true;cache:false;onStatusChanged:scene.commit()}
    Image{id:imageB0;visible:false;asynchronous:true;cache:false;onStatusChanged:scene.commit()}
    Image{id:imageA1;visible:false;asynchronous:true;cache:false;onStatusChanged:scene.commit()}
    Image{id:imageB1;visible:false;asynchronous:true;cache:false;onStatusChanged:scene.commit()}
    Image{id:starless;visible:false;source:(scene.wantWinterStars||scene.winterNightAmount>0)?"assets/stars/winter-starless.png":"";asynchronous:true;cache:false;onStatusChanged:scene.commit()}
    Image{id:valleyMaskImage;visible:false;source:(scene.wantWinterStars||scene.winterNightAmount>0)?"assets/stars/winter-valley.png":"";asynchronous:true;cache:false;onStatusChanged:scene.commit()}
    Image{id:frontMaskImage;visible:false;source:(scene.wantWinterStars||scene.winterNightAmount>0)?"assets/stars/winter-foreground.png":"";asynchronous:true;cache:false;onStatusChanged:scene.commit()}
    ShaderEffect {
        anchors.fill:parent;visible:scene.ready
        property variant sourceA: scene.activeBank===0?imageA0:imageA1
        property variant sourceB: scene.activeBank===0?(scene.same0?imageA0:imageB0):(scene.same1?imageA1:imageB1)
        property real time:scene.time
        property real night:scene.night
        property real artworkZoom:scene.artworkZoom
        property real landscapeWind:scene.displayedScene==="valley"&&scene.displayedStyle==="colour"?1:0
        property real blend:scene.blend
        property real clearWinterA:scene.starAssetsReady?scene.winterSourceA:0
        property real clearWinterB:scene.starAssetsReady?scene.winterSourceB:0
        property variant clearSky:scene.starAssetsReady?starless:(scene.activeBank===0?imageA0:imageA1)
        property variant valleyMask:scene.starAssetsReady?valleyMaskImage:(scene.activeBank===0?imageA0:imageA1)
        property variant frontMask:scene.starAssetsReady?frontMaskImage:(scene.activeBank===0?imageA0:imageA1)
        property vector2d focusPan:Qt.vector2d(scene.panX,scene.panY)
        mesh:GridMesh{resolution:Qt.size(128,72)}
        blending:false
        vertexShader:Shaders.landscapeVertex
        fragmentShader:Shaders.landscapeFragment
    }
    WinterStars {anchors.fill:parent;visible:scene.ready&&scene.starAssetsReady&&scene.winterNightAmount>0;time:scene.time;amount:scene.winterNightAmount;zoom:scene.artworkZoom;skyImage:starless;valleyImage:valleyMaskImage;frontImage:frontMaskImage}
    Item {visible:scene.ready;transform:Scale {origin.x:960;origin.y:594;xScale:scene.birdZoom;yScale:scene.birdZoom} Repeater {id:birds;model:7;BirdMesh{}}}
    ShaderEffect {
        width:1920;height:1080
        property real age:(scene.time+28)%137
        property real progress:(age-110)/1.3
        property real alpha:Math.sin(progress*Math.PI)*scene.night*.75
        visible:scene.ready&&scene.night>.2&&age>110&&age<111.3
        blending:true
        vertexShader:Shaders.meteorVertex
        fragmentShader:Shaders.meteorFragment
    }
}
