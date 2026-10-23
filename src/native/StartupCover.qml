import QtQuick 2.12
import WebOSServices 1.0

// App-owned readiness handshake. Never changes boot policy or LG's cover code.
Item {
    id: handshake
    visible: false
    property string appId: "uk.local.minimalhome.native"
    property bool artworkReady: false
    property bool finished: false
    property bool closeAttempted: false
    property int generation: 0
    property int step: 0
    property var client: null
    signal trace(string label, var detail)

    function dispose() {
        var previous=client;client=null;
        if(previous)previous.destroy();
    }
    function cancel() {
        finished=true;generation++;advance.stop();retry.stop();deadline.stop();dispose();
    }
    function complete(reason) {
        trace("cover-ready-finished",reason);cancel();
    }
    function begin() {
        if(finished||!artworkReady)return;
        deadline.start();request();
    }
    function request() {
        if(finished)return;
        dispose();
        var services=["com.webos.coverUI","com.webos.service.tvpower","com.webos.applicationManager","com.webos.coverUI"];
        var methods=["getStatus","power/getPowerState","getForegroundAppInfo","close"];
        var serial=++generation;
        if(step===3){
            if(closeAttempted){complete("duplicate prevented");return;}
            closeAttempted=true;
        }
        try {
            client=serviceComponent.createObject(handshake,{service:services[step],method:methods[step],requestGeneration:serial});
            if(!client){complete("service unavailable");return;}
            trace("cover-ready-request",{step:step});
            var token=client.callService({});
            if(finished||serial!==generation)return;
            if(!token){
                dispose();
                if(closeAttempted)complete("close not dispatched");
                else retry.restart();
            }
        }catch(error){complete(String(error));}
    }
    function response(source,serial,value) {
        if(finished||source!==client||serial!==generation)return;
        // Consume this response before queuing the next gate, including a
        // synchronous callback made from callService().
        generation++;dispose();
        trace("cover-ready-response",{step:step,value:value});
        if(step===0&&value.isRunning!==true){complete("no cover");return;}
        if(step===1&&value.state!=="Active"){complete("TV not active");return;}
        if(step===2&&value.appId!==appId){complete("another app is foreground");return;}
        if(step===3){complete("close accepted");return;}
        step++;advance.restart();
    }
    function failed(source,serial,reason) {
        if(finished||source!==client||serial!==generation)return;
        complete(reason);
    }
    Component {
        id: serviceComponent
        Service {
            id: connection
            property int requestGeneration: -1
            appId: handshake.appId
            onCallSuccess: handshake.response(connection,requestGeneration,response)
            onCallFailure: handshake.failed(connection,requestGeneration,response)
            onError: handshake.failed(connection,requestGeneration,errorText)
        }
    }
    Timer {id:retry;interval:120;onTriggered:handshake.request()}
    Timer {id:advance;interval:0;onTriggered:handshake.request()}
    Timer {id:deadline;interval:1800;onTriggered:handshake.complete("bounded timeout")}
    onArtworkReadyChanged: if(artworkReady){trace("cover-artwork-ready",{});begin();}
}
