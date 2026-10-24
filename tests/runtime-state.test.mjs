import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
function moduleFile(name){const box={module:{exports:{}},Date,JSON};vm.runInNewContext(readFileSync(new URL('../src/native/'+name,import.meta.url),'utf8'),box);return box.module.exports;}
const store=moduleFile('ConfigStore.js'), config=moduleFile('LauncherConfig.js'), clock=moduleFile('RuntimeClock.js');
const good=JSON.stringify(config.defaults());
test('corrupt saved config recovers previous before package defaults',()=>{const old=config.defaults();old.inputs=[{port:3,label:'Cinema'}];const r=store.restore('{bad',JSON.stringify(old),good,config.parse);assert.equal(r.source,'previous');assert.equal(r.config.inputs[0].port,3);assert.equal(r.recovered,true);});
test('future schema never overwrites valid fallback',()=>{const future=config.defaults();future.version=99;assert.equal(store.restore(JSON.stringify(future),'bad',good,config.parse).source,'bundled');});
test('first run and all damaged sources have deterministic results',()=>{assert.equal(store.restore('','',good,config.parse).recovered,false);assert.equal(store.restore('{','[','false',config.parse).config,null);});
test('inventory rejects failed/malformed service responses',()=>{for(const p of [{returnValue:false,apps:[]},{},'not-json'])assert.throws(()=>store.inventory(p));});
test('inventory sanitizes titles, de-duplicates and omits HDMI/self/hidden apps',()=>{const a=store.inventory({apps:[{id:'foo',title:'Cinema\u0001'},{id:'foo',title:'Duplicate'},{id:'bar',visible:false},{id:'com.webos.app.hdmi1'},{id:'uk.local.minimalhome.native'},{id:'bad;id'},{id:'abc',title:'Player'}]});assert.equal(a.length,2);assert.equal(a[0].label,'Cinema');assert.equal(a[1].id,'abc');assert.equal('icon' in a[0],false);});
test('London DST changes at the UTC boundary',()=>{assert.equal(clock.parts(Date.parse('2026-03-29T00:59:00Z'),'Europe/London').hour,0);assert.equal(clock.parts(Date.parse('2026-03-29T01:00:00Z'),'Europe/London').hour,2);assert.equal(clock.parts(Date.parse('2026-10-25T00:59:00Z'),'Europe/London').hour,1);assert.equal(clock.parts(Date.parse('2026-10-25T01:00:00Z'),'Europe/London').hour,1);});
test('system and UTC clocks do not inherit a forced British offset',()=>{const t=Date.parse('2026-07-03T12:34:56Z');assert.equal(clock.parts(t,'UTC').hour,12);assert.equal(clock.parts(t,'system').hour,new Date(t).getHours());assert.equal(clock.parts(t,'Europe/London').decimalHour,13+34/60+56/3600);});
test('12-hour midnight/noon and 24-hour formatting',()=>{assert.equal(clock.timeText({hour:0,minute:4},'12h'),'12:04 AM');assert.equal(clock.timeText({hour:12,minute:4},'12h'),'12:04 PM');assert.equal(clock.timeText({hour:23,minute:4},'24h'),'23:04');});

test('installed icons resolve only within the same app known installation roots',()=>{
  for(const base of ['/usr/palm/applications/','/media/developer/apps/usr/palm/applications/','/media/cryptofs/apps/usr/palm/applications/']) {
    const app={id:'org.example.player',folderPath:base+'org.example.player',icon:'images/icon.png'};
    const expected='file://'+base+'org.example.player/images/icon.png';
    assert.equal(store.installedIcon(app),expected);
    assert.equal(store.installedIcon({...app,icon:base+'org.example.player/images/icon.png'}),expected);
    assert.equal(store.installedIcon({...app,icon:expected}),expected);
    assert.equal(store.inventory({apps:[app]})[0].iconURL,expected);
  }
});
test('installed icon validation rejects remote, traversal, cross-app and nonimage paths',()=>{
  const app={id:'org.example.player',folderPath:'/usr/palm/applications/org.example.player',icon:'icon.png'};
  for(const icon of ['../secret.png','images/../../secret.png','./icon.png','images/./icon.png','/etc/icon.png','/usr/palm/applications/other.app/icon.png','/usr/palm/applications/org.example.player-copy/icon.png','https://example.com/icon.png','file://evilhost/usr/palm/applications/org.example.player/icon.png','data:image/png;base64,test','icon.png?x=1','icon%2epng','images%2f..%2fsecret.png','icon.html','icon.png\\..\\secret.png','icon\u0000.png'])assert.equal(store.installedIcon({...app,icon}),'',icon);
  for(const folderPath of ['/etc','/usr/palm/applications/other.app','/usr/palm/applications/org.example.player/../other','https://example.com','/usr/palm/applications/org.example.player/subdir'])assert.equal(store.installedIcon({...app,folderPath}),'',folderPath);
  assert.equal(store.installedIcon({id:app.id,icon:'icon.png'}),'');
});
test('installed icon URL is ephemeral and never a portable config icon',()=>{
  const entry=store.inventory({apps:[{id:'org.example.player',title:'Films',icon:'/usr/palm/applications/org.example.player/icon.png'}]})[0];
  assert.equal(entry.iconURL,'file:///usr/palm/applications/org.example.player/icon.png');
  assert.equal(entry.icon,undefined);
  const choices=config.defaults();choices.apps=[{id:entry.id,label:entry.label}];
  assert.doesNotThrow(()=>config.validateConfig(choices));
  choices.apps[0].icon=entry.iconURL;
  assert.throws(()=>config.validateConfig(choices));
});

test('empty inventory titles retain valid bounded fallback labels',()=>{const id='a'.repeat(128);const app=store.inventory({apps:[{id,title:'\u0001'}]})[0];const c=config.defaults();c.apps=[{id:app.id,label:app.label}];assert.doesNotThrow(()=>config.validateConfig(c));assert.ok(app.label.length<=64);});
