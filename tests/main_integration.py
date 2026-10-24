#!/usr/bin/env python3
"""Production main.qml integration with local fake LG services. NO TV connection.
Requires optional PySide6. Replaces ONLY the window/service modules, artwork renderer,
and absolute settings directory in a temporary copy. Does not prove TV ABI/permissions.
"""
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
os.environ.setdefault('QT_QPA_PLATFORM','offscreen')
os.environ.setdefault('QT_QUICK_BACKEND','software')
os.environ.setdefault('QML_XHR_ALLOW_FILE_READ','1')
from PySide6.QtCore import QUrl,QMetaObject,Q_ARG,QEventLoop,QTimer,qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

ROOT=Path(__file__).resolve().parents[1]
app=QGuiApplication(sys.argv[:1]);app.setOrganizationName('FirewatchTest');app.setApplicationName('NoTV')
def settle(ms=150):
    loop=QEventLoop();QTimer.singleShot(ms,loop.quit);loop.exec()
def write(path,text):
    path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
def check(value,message):
    global assertions
    assertions+=1
    if not value:raise AssertionError(message)
assertions=0
messages=[]
def diagnostic(kind,context,message):
    messages.append(message)
qInstallMessageHandler(diagnostic)
with tempfile.TemporaryDirectory(prefix='firewatch-main-') as tmp:
    base=Path(tmp);native=base/'native';native.mkdir();settings=base/'settings';settings.mkdir();imports=base/'imports'
    for path in (ROOT/'src/native').iterdir():
        if path.is_file() and path.suffix in ('.qml','.js'):shutil.copy2(path,native/path.name)
    shutil.copytree(ROOT/'src/native/fonts',native/'fonts')
    shutil.copytree(ROOT/'src/native/previews',native/'previews')
    shutil.copy2(ROOT/'config/default.json',native/'launcher-config.json')
    write(imports/'Eos/Window/qmldir','module Eos.Window\nWebOSWindow 0.1 WebOSWindow.qml\n')
    write(imports/'Eos/Window/WebOSWindow.qml','import QtQuick.Window 2.2\nWindow {property string appId:""; property var windowProperties:({})}\n')
    write(imports/'WebOS/Global/qmldir','module WebOS.Global\nsingleton WebOS 1.0 WebOS.qml\n')
    write(imports/'WebOS/Global/WebOS.qml','pragma Singleton\nimport QtQml 2.12\nQtObject {enum Keys { Key_webOS_Back = 461 }}\n')
    write(imports/'WebOSServices/qmldir','module WebOSServices\nService 1.0 Service.qml\n')
    write(imports/'WebOSServices/Service.qml','''import QtQuick 2.12
Item {id:serviceObject
 property string appId:"";property string service:"";property string method:""
 signal callSuccess(var response);signal callFailure(var response);signal error(string errorText);signal response(var payload)
 function callService(payload){reply.restart();return 1;}
 Timer {id:reply;interval:5;onTriggered:{
  if(serviceObject.method==="listApps")serviceObject.callSuccess({returnValue:true,apps:[{id:"org.test.video",title:"Test video"}]});
  else if(serviceObject.method==="getStatus")serviceObject.callSuccess({returnValue:true,isRunning:false});
  else serviceObject.callSuccess({returnValue:true});
 }}
}''')
    write(native/'PaintedScene.qml','''import QtQuick 2.12
Item {
 property string timeZone:"system";property string season:"autumn";property string sceneName:"valley";property string styleName:"colour";property string framing:"wide";property string theme:"auto";property bool playing:false
 property bool ready:true;property string period:"Evening";property int pendingBank:-1
 signal firstArtworkFrame();signal loadFailed(string message)
 function sample(){}
 function setFocusPoint(x,y){}
}''')
    home=(native/'HomeControls.qml').read_text().replace('id: root','id: root\n    readonly property bool testSetupOpen:setup.opened',1)
    write(native/'HomeControls.qml',home)
    main=(native/'main.qml').read_text().replace('/media/developer/.minimalhome-native',str(settings))
    main=main.rsplit('}',1)[0]+'''
    readonly property string testSnapshot:JSON.stringify({loaded:configLoaded,config:launcherConfig,current:launcherSettings.current,previous:launcherSettings.previous,configured:launcherSettings.configured,hasAppearance:hasSavedAppearance,defaultsApplied:launcherSettings.defaultsApplied,season:preferences.landscape,scene:preferences.sceneName,theme:preferences.theme,setupOpen:controls.testSetupOpen,inventory:installedApps,inventoryAvailable:inventoryAvailable})
    function testSave(text){controls.openSetup(false);root.saveConfig(JSON.parse(text));}
    function testDiscard(){controls.handleKey(Qt.Key_Back,false);}
    function testLateInventory(){root.inventoryAwaiting=false;appInventory.callSuccess({returnValue:true,apps:[{id:"late.reply",title:"Late"}]});}
}'''
    write(native/'main.qml',main)
    engines=[]
    def load():
        engine=QQmlApplicationEngine();engine.addImportPath(str(imports));engine.load(QUrl.fromLocalFile(str(native/'main.qml')))
        if not engine.rootObjects():raise AssertionError('Production main.qml failed to instantiate')
        engines.append(engine);root=engine.rootObjects()[0];settle(650);return root
    def snap(root):return json.loads(root.property('testSnapshot'))
    def unload(root):
        root.close();root.deleteLater();settle();engines[-1].deleteLater();settle()
    root=load();state=snap(root)
    check(state['loaded'],'bundled configuration loaded')
    check(not state['configured'],'first use remains unconfigured until Save')
    check(state['setupOpen'],'first-use setup offered after artwork ready')
    check(state['season']=='autumn','fresh install applies bundled scene defaults')
    initial=state['config'];custom=json.loads(json.dumps(initial));custom['apps']=[{'id':'org.test.video','label':'My films'}];custom['inputs']=[{'port':3,'label':'Streamer'}]
    QMetaObject.invokeMethod(root,'testSave',Q_ARG('QVariant',json.dumps(custom)));settle()
    state=snap(root)
    check(state['config']==custom,'Save applies normalized signal payload')
    check(json.loads(state['current'])==custom,'Save persists current JSON')
    check(json.loads(state['previous'])==initial,'Save retains prior valid config')
    check(state['configured'] and not state['setupOpen'],'successful Save closes setup')
    invalid=json.loads(json.dumps(custom));invalid['inputs'][0]['port']=9
    QMetaObject.invokeMethod(root,'testSave',Q_ARG('QVariant',json.dumps(invalid)));settle()
    state=snap(root)
    check(state['config']==custom,'invalid save leaves live model untouched')
    check(state['setupOpen'],'invalid save retains editable draft')
    QMetaObject.invokeMethod(root,'testDiscard');settle(700)
    state=snap(root);check(state['inventoryAvailable'],'fake installed app inventory loaded')
    inventory=state['inventory'];QMetaObject.invokeMethod(root,'testLateInventory');settle()
    check(snap(root)['inventory']==inventory,'late timed-out inventory callback ignored')
    unload(root)
    root=load();state=snap(root)
    check(state['config']==custom,'saved config survives a new QML engine')
    check(not state['setupOpen'],'configured relaunch does not interrupt with setup')
    unload(root)
    # Simulate an existing original installation with appearance and no community config.
    (settings/'launcher.ini').unlink(missing_ok=True)
    write(settings/'preferences.ini','[MinimalHome]\nlandscape=winter\nsceneName=lookout\ntheme=dusk\nframing=close\nmotion=true\nselected=0\nstyleName=colour\n')
    root=load();state=snap(root)
    check(state['hasAppearance'],'existing appearance keys detected')
    check(state['season']=='winter' and state['scene']=='lookout' and state['theme']=='dusk','community setup preserves existing appearance')
    unload(root)
    errors=[line for line in messages if any(marker in line for marker in ['ReferenceError:', 'TypeError:', 'SyntaxError:', 'Cannot assign', 'Binding loop', 'Cannot open:'])]
    check(not errors,'unexpected QML runtime errors: '+ '\n'.join(errors))
    print(json.dumps({'passed':True,'assertions':assertions,'scope':'Production main.qml + real Qt Settings in temp directory; LG services/window and artwork are stubs; no TV access'},indent=2))
