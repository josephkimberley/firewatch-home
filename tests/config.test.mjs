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
