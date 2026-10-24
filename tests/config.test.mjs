import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {validateConfig, targets} from '../tools/config.mjs';
const fresh = () => JSON.parse(readFileSync(new URL('../config/default.json', import.meta.url)));

test('reordering and renaming HDMI preserves physical port mapping', () => {
  const config = fresh();
  config.inputs = [{port: 3, label: 'Streaming box'}, {port: 1, label: 'Console'}];
  assert.deepEqual(targets(config).slice(5).map(t => [t.id, t.label]), [
    ['com.webos.app.hdmi3', 'Streaming box'], ['com.webos.app.hdmi1', 'Console']
  ]);
});
test('configuration round trip preserves user order and options', () => {
  const config = fresh(); config.apps.reverse(); config.clock.timeZone = 'Europe/London';
  config.scene.period = 'night'; config.layout.inputTintOpacity = 0;
  assert.deepEqual(validateConfig(JSON.parse(JSON.stringify(config))), config);
});
test('apps-only and inputs-only configurations are accepted', () => {
  const a = fresh(); a.inputs = []; assert.equal(targets(a).length, 5);
  const b = fresh(); b.apps = []; assert.equal(targets(b).length, 4);
});
for (const [name, mutate] of [
  ['unknown version', c => c.version = 2],
  ['duplicate app', c => c.apps[1] = c.apps[0]],
  ['duplicate port', c => c.inputs[1].port = 1],
  ['invalid port', c => c.inputs[0].port = 0],
  ['fractional port', c => c.inputs[0].port = 1.5],
  ['duplicate across groups', c => c.apps[0].id = 'com.webos.app.hdmi1'],
  ['empty launcher', c => {c.apps = []; c.inputs = [];}],
  ['unknown field', c => c.apps[0].command = 'shell'],
  ['path traversal', c => c.apps[0].icon = '../../secret.png'],
  ['absolute asset path', c => c.apps[0].icon = '/private/image.png'],
  ['network asset URL', c => c.apps[0].icon = 'https://example.com/image.png'],
  ['control character', c => c.inputs[0].label = 'bad\nlabel'],
  ['invalid timezone', c => c.clock.timeZone = 'Not/A_Zone'],
  ['wrong boolean type', c => c.scene.motion = 'false'],
  ['invalid phase', c => c.scene.period = 'midday'],
  ['invisible gap', c => c.layout.groupGap = -2]
]) test(`rejects ${name}`, () => {const c = fresh(); mutate(c); assert.throws(() => validateConfig(c));});

test('bundled JSON and QML fallback defaults cannot drift', async () => {
  const {defaults} = await import('../tools/config.mjs');
  assert.deepEqual(fresh(), defaults());
});
test('every supported tile count stays centred without collisions', async () => {
  const {layout} = await import('../tools/config.mjs');
  for(let apps=0;apps<=5;apps++) for(let inputs=0;inputs<=4;inputs++) {
    if(!apps&&!inputs)continue;
    const config=fresh();config.apps=config.apps.slice(0,apps);config.inputs=config.inputs.slice(0,inputs);
    const metrics=layout(config), count=apps+inputs;
    assert.equal(metrics.positions.length,count);
    assert.equal(metrics.start+metrics.end,1920);
    assert.ok(metrics.start>0 && metrics.end<1920);
    assert.equal(metrics.dividerVisible,!!(apps&&inputs));
    for(let i=1;i<count;i++) assert.ok(metrics.positions[i]>metrics.positions[i-1]+metrics.width);
  }
});
test('full launcher keeps the approved positions and group separation', async () => {
  const {layout}=await import('../tools/config.mjs');
  const result=layout(fresh());
  assert.equal(result.positions[0],288);
  assert.equal(result.positions[4],856.3125);
  assert.equal(result.positions[5],1086.71875);
  assert.equal(result.positions[8],1512.953125);
  assert.ok(Math.abs(result.dividerX-1030.546875)<1);
});
test('malformed and future configs recover without mutating original saved data', async () => {
  const {resolve,defaults,parse}=await import('../tools/config.mjs');
  for(const text of ['', '{', JSON.stringify({...fresh(),version:400}), 'x'.repeat(65537)]) {
    const result=resolve(text);
    assert.equal(result.usedFallback,true);assert.ok(result.error);
    assert.deepEqual(result.config,defaults());
    assert.throws(()=>parse(text));
  }
  const source=JSON.stringify(fresh());
  const result=resolve(source);
  assert.equal(result.usedFallback,false);assert.equal(result.error,'');
  assert.deepEqual(result.config,JSON.parse(source));
});
test('valid labels remain plain data and app order is independent of identity', () => {
  const config=fresh();config.apps=[{id:'org.example.media',label:'<b>Family & films</b>'}];config.inputs=[];
  assert.equal(targets(config)[0].label,'<b>Family & films</b>');
});
test('existing focus is clamped for smaller configurations and all footers are reachable', async () => {
  const {clampSelection}=await import('../tools/config.mjs');
  assert.equal(clampSelection(8,1),3);
  assert.equal(clampSelection(-1,1),0);
  assert.equal(clampSelection(NaN,9),0);
  assert.equal(clampSelection(4,9),4);
  assert.equal(clampSelection(11,9),11);
});
for(const [name,mutate] of [
  ['too many apps',c=>c.apps.push({id:'extra.app',label:'Extra'})],
  ['too many inputs',c=>c.inputs.push({port:1,label:'Another'})],
  ['unsupported scene',c=>c.scene.theme='custom-theme'],
  ['data URI icon',c=>c.apps[0].icon='data:image/svg+xml,<svg/>'],
  ['NaN layout',c=>c.layout.groupGap=NaN],
  ['HTML icon extension',c=>c.apps[0].icon='something.html'],
  ['empty label',c=>c.apps[0].label='   ']
]) test(`rejects ${name}`,()=>{const config=fresh();mutate(config);assert.throws(()=>validateConfig(config));});
