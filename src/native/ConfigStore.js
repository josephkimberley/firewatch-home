// Selection is pure so corrupt settings and recovery can be tested without a TV.
function restore(current, previous, bundled, parse) {
    var candidates=[current,previous,bundled], names=["saved","previous","bundled"];
    var errors=[];
    for(var i=0;i<candidates.length;i++) {
        if(!candidates[i])continue;
        try{return {config:parse(candidates[i]),source:names[i],recovered:i>0&&!!current,errors:errors};}
        catch(e){errors.push(names[i]+": "+String(e.message||e));}
    }
    return {config:null,source:"defaults",recovered:!!current,errors:errors};
}
// Accept only image files inside this app's own known LG installation roots.
// These ephemeral display URLs never enter the portable saved configuration.
function installedIcon(app) {
    if(!app||typeof app.id!=="string"||!/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(app.id)||typeof app.icon!=="string")return "";
    var roots=["/usr/palm/applications/","/media/developer/apps/usr/palm/applications/","/media/cryptofs/apps/usr/palm/applications/"];
    var icon=app.icon,path="",folder=typeof app.folderPath==="string"?app.folderPath:"";
    // Do not interpret escapes, remote hosts, backslashes or traversal components.
    if(icon.indexOf("file:///")===0)icon=icon.slice(7);
    if(!/^[A-Za-z0-9_./-]+\.(png|svg|jpe?g|webp)$/i.test(icon)||/(^|\/)\.\.?(\/|$)/.test(icon))return "";
    if(icon.charAt(0)==="/")path=icon;
    else {
        if(folder.indexOf("file:///")===0)folder=folder.slice(7);
        if(folder.charAt(folder.length-1)==="/")folder=folder.slice(0,-1);
        for(var i=0;i<roots.length;i++)if(folder===roots[i]+app.id){path=folder+"/"+icon;break;}
        if(!path)return ""; // No guessed install directory if inventory omitted it.
    }
    for(var j=0;j<roots.length;j++) {
        var prefix=roots[j]+app.id+"/";
        if(path.indexOf(prefix)===0&&path.length>prefix.length)return "file://"+path;
    }
    return "";
}
function inventory(payload) {
    if(typeof payload==="string")payload=JSON.parse(payload);
    if(!payload||payload.returnValue===false||!Array.isArray(payload.apps))throw new Error("App inventory was not available");
    var out=[],ids=[];
    for(var i=0;i<payload.apps.length;i++) {
        var app=payload.apps[i];
        if(!app||typeof app.id!=="string"||!/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(app.id)||ids.indexOf(app.id)>=0)continue;
        if(app.visible===false||app.removable===false&&app.launchPointId===undefined&&app.noWindow===true)continue;
        if(/^com.webos.app.hdmi[1-4]$/.test(app.id)||app.id==="uk.local.minimalhome.native")continue;
        var title=typeof app.title==="string"?app.title:app.id;
        title=title.replace(/[\x00-\x1f\x7f]/g,"").slice(0,64).trim()||app.id.slice(0,64);
        // Only sanitized ephemeral icon URLs accompany the app identity.
        var entry={id:app.id,label:title},iconURL=installedIcon(app);
        if(iconURL)entry.iconURL=iconURL;
        ids.push(app.id);out.push(entry);
    }
    out.sort(function(a,b){return a.label.toLowerCase()<b.label.toLowerCase()?-1:a.label.toLowerCase()>b.label.toLowerCase()?1:0;});
    return out;
}
if(typeof module!=="undefined"&&module.exports)module.exports={restore:restore,inventory:inventory,installedIcon:installedIcon};
