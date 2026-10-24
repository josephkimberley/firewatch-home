// ES5 syntax intentionally: this exact contract runs in webOS Qt 5 and Node.
// Config contains data only. No configuration value is executed as code.
function defaults() {
    return {
        version: 1,
        apps: [
            {id:"youtube.leanback.v4",label:"YouTube"},
            {id:"bbc.iplayer.3.0",label:"BBC iPlayer"},
            {id:"com.fvp.itv",label:"ITVX"},
            {id:"com.fvp.ch4",label:"Channel 4"},
            {id:"amazon",label:"Prime Video"}
        ],
        inputs:[{port:1,label:"HDMI 1"},{port:2,label:"HDMI 2"},{port:3,label:"HDMI 3"},{port:4,label:"HDMI 4"}],
        clock:{timeZone:"system",format:"24h"},
        scene:{theme:"autumn",period:"auto",motion:true},
        layout:{groupGap:88.328125,divider:true,inputTintOpacity:0.08}
    };
}
function fail(message) { throw new Error(message); }
function object(value, keys, at) {
    if (!value || typeof value !== "object" || Array.isArray(value)) fail(at+": expected object");
    var names=Object.keys(value);
    for(var i=0;i<names.length;i++) if(keys.indexOf(names[i])<0) fail(at+": unknown field "+names[i]);
}
function label(value,at) {
    if(typeof value!=="string" || !value.trim() || value.length>64 || /[\x00-\x1f\x7f]/.test(value)) fail(at+": invalid label");
}
function asset(value,at) {
    if(value===undefined)return;
    if(typeof value!=="string" || !/^(?:[A-Za-z0-9_-]+\/)*[A-Za-z0-9_-]+\.(png|svg)$/.test(value)) fail(at+": use a relative PNG/SVG asset path");
}
function flag(value,at) { if(typeof value!=="boolean")fail(at+": expected boolean"); }
function range(value,min,max,at) { if(typeof value!=="number" || !isFinite(value) || value<min || value>max)fail(at+": expected "+min+"–"+max); }
function validateConfig(config) {
    object(config,["version","apps","inputs","clock","scene","layout"],"config");
    if(config.version!==1)fail("Unsupported configuration version; no automatic migration attempted");
    if(!Array.isArray(config.apps)||config.apps.length>5)fail("apps: at most five supported in this first layout");
    if(!Array.isArray(config.inputs)||config.inputs.length>4)fail("inputs: at most four");
    if(!config.apps.length&&!config.inputs.length)fail("At least one app or input is required");
    var ids=[],ports=[],i,app,input;
    for(i=0;i<config.apps.length;i++) {
        app=config.apps[i];object(app,["id","label","icon"],"apps["+i+"]");
        if(typeof app.id!=="string" || !/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(app.id))fail("apps["+i+"]: invalid app ID");
        if(ids.indexOf(app.id)>=0)fail("Duplicate app ID: "+app.id);
        ids.push(app.id);label(app.label,"apps["+i+"]");asset(app.icon,"apps["+i+"].icon");
    }
    for(i=0;i<config.inputs.length;i++) {
        input=config.inputs[i];object(input,["port","label","icon"],"inputs["+i+"]");
        if(typeof input.port!=="number"||Math.floor(input.port)!==input.port||input.port<1||input.port>4)fail("inputs["+i+"]: port must be 1–4");
        if(ports.indexOf(input.port)>=0)fail("Duplicate HDMI port: "+input.port);
        if(ids.indexOf("com.webos.app.hdmi"+input.port)>=0)fail("HDMI "+input.port+" appears in both groups");
        ports.push(input.port);label(input.label,"inputs["+i+"]");asset(input.icon,"inputs["+i+"].icon");
    }
    object(config.clock,["timeZone","format"],"clock");
    if(["system","UTC","Europe/London"].indexOf(config.clock.timeZone)<0)fail("clock.timeZone: this preview supports system, UTC or Europe/London");
    if(["12h","24h"].indexOf(config.clock.format)<0)fail("clock.format: expected 12h or 24h");
    object(config.scene,["theme","period","motion"],"scene");
    if(["autumn","winter"].indexOf(config.scene.theme)<0)fail("scene.theme: expected autumn or winter");
    if(["auto","dawn","morning","noon","afternoon","evening","dusk","night"].indexOf(config.scene.period)<0)fail("scene.period: unknown phase");
    flag(config.scene.motion,"scene.motion");
    object(config.layout,["groupGap","divider","inputTintOpacity"],"layout");
    range(config.layout.groupGap,16,96,"layout.groupGap");range(config.layout.inputTintOpacity,0,0.3,"layout.inputTintOpacity");flag(config.layout.divider,"layout.divider");
    return config;
}
function targets(config) {
    validateConfig(config);
    var out=[],i,entry;
    for(i=0;i<config.apps.length;i++) {entry=config.apps[i];out.push({id:entry.id,label:entry.label,icon:entry.icon||"",group:"app"});}
    for(i=0;i<config.inputs.length;i++) {entry=config.inputs[i];out.push({id:"com.webos.app.hdmi"+entry.port,label:entry.label,icon:entry.icon||"",group:"input",port:entry.port});}
    return out;
}
function parse(text) {
    if(typeof text!=="string"||text.length>65536)fail("Configuration must be JSON text under 64 KiB");
    return validateConfig(JSON.parse(text));
}
function resolve(text) {
    try {return {config:parse(text),error:"",usedFallback:false};}
    catch(error){return {config:defaults(),error:String(error.message||error),usedFallback:true};}
}
function layout(config) {
    validateConfig(config);
    var apps=config.apps.length, inputs=config.inputs.length, count=apps+inputs;
    var tileWidth=119.046875,gap=23.03125,groupExtra=apps&&inputs?config.layout.groupGap:0;
    var total=count*tileWidth+(count-1)*gap+groupExtra,start=(1920-total)/2,positions=[];
    for(var i=0;i<count;i++)positions.push(start+i*(tileWidth+gap)+(i>=apps?groupExtra:0));
    return {positions:positions,width:tileWidth,start:start,end:start+total,dividerVisible:!!(apps&&inputs&&config.layout.divider),dividerX:apps&&inputs?positions[apps]-((gap+groupExtra)/2):0};
}
function clampSelection(index,count) {
    if(typeof index!=="number"||!isFinite(index))return 0;
    return Math.max(0,Math.min(count+2,Math.floor(index)));
}
if(typeof module!=="undefined"&&module.exports)module.exports={defaults:defaults,validateConfig:validateConfig,targets:targets,parse:parse,resolve:resolve,layout:layout,clampSelection:clampSelection};
