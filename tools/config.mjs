// Offline configuration contract. Runtime integration is tracked in RELEASE.md.
import {readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';

const periods = ['auto', 'dawn', 'morning', 'noon', 'afternoon', 'evening', 'dusk', 'night'];
function fail(message) { throw new Error(message); }
function object(value, keys, at) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) fail(`${at}: expected object`);
  for (const key of Object.keys(value)) if (!keys.includes(key)) fail(`${at}: unknown field ${key}`);
}
function label(value, at) {
  if (typeof value !== 'string' || !value.trim() || value.length > 64 || /[\x00-\x1f\x7f]/.test(value)) fail(`${at}: invalid label`);
}
function asset(value, at) {
  if (value === undefined) return;
  if (typeof value !== 'string' || !/^(?:[A-Za-z0-9_-]+\/)*[A-Za-z0-9_-]+\.(png|svg)$/.test(value)) fail(`${at}: use a relative PNG/SVG asset path`);
}
function flag(value, at) { if (typeof value !== 'boolean') fail(`${at}: expected boolean`); }
function range(value, min, max, at) { if (!Number.isFinite(value) || value < min || value > max) fail(`${at}: expected ${min}–${max}`); }

export function validateConfig(config) {
  object(config, ['version', 'apps', 'inputs', 'clock', 'scene', 'layout'], 'config');
  if (config.version !== 1) fail('Unsupported configuration version; no automatic migration attempted');
  if (!Array.isArray(config.apps) || config.apps.length > 5) fail('apps: at most five supported in this first layout');
  if (!Array.isArray(config.inputs) || config.inputs.length > 4) fail('inputs: at most four');
  if (!config.apps.length && !config.inputs.length) fail('At least one app or input is required');
  const ids = new Set(), ports = new Set();
  for (const [i, app] of config.apps.entries()) {
    object(app, ['id', 'label', 'icon'], `apps[${i}]`);
    if (typeof app.id !== 'string' || !/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(app.id)) fail(`apps[${i}]: invalid app ID`);
    if (ids.has(app.id)) fail(`Duplicate app ID: ${app.id}`);
    ids.add(app.id); label(app.label, `apps[${i}]`); asset(app.icon, `apps[${i}].icon`);
  }
  for (const [i, input] of config.inputs.entries()) {
    object(input, ['port', 'label', 'icon'], `inputs[${i}]`);
    if (!Number.isInteger(input.port) || input.port < 1 || input.port > 4) fail(`inputs[${i}]: port must be 1–4`);
    if (ports.has(input.port)) fail(`Duplicate HDMI port: ${input.port}`);
    if (ids.has(`com.webos.app.hdmi${input.port}`)) fail(`HDMI ${input.port} appears in both groups`);
    ports.add(input.port); label(input.label, `inputs[${i}]`); asset(input.icon, `inputs[${i}].icon`);
  }
  object(config.clock, ['timeZone', 'format'], 'clock');
  if (typeof config.clock.timeZone !== 'string') fail('clock.timeZone: expected system or an IANA zone');
  if (config.clock.timeZone !== 'system') {
    try { new Intl.DateTimeFormat('en', {timeZone: config.clock.timeZone}); }
    catch { fail('clock.timeZone: unknown IANA timezone'); }
  }
  if (!['12h', '24h'].includes(config.clock.format)) fail('clock.format: expected 12h or 24h');
  object(config.scene, ['theme', 'period', 'motion'], 'scene');
  if (typeof config.scene.theme !== 'string' || !/^[a-z][a-z0-9-]{0,47}$/.test(config.scene.theme)) fail('scene.theme: invalid theme identifier');
  if (!periods.includes(config.scene.period)) fail('scene.period: unknown phase');
  flag(config.scene.motion, 'scene.motion');
  object(config.layout, ['groupGap', 'divider', 'inputTintOpacity'], 'layout');
  range(config.layout.groupGap, 16, 96, 'layout.groupGap');
  range(config.layout.inputTintOpacity, 0, 0.3, 'layout.inputTintOpacity');
  flag(config.layout.divider, 'layout.divider');
  return config;
}

export function targets(config) {
  validateConfig(config);
  return [...config.apps.map(app => ({...app, group: 'app'})), ...config.inputs.map(input => ({
    id: `com.webos.app.hdmi${input.port}`, label: input.label, ...(input.icon ? {icon: input.icon} : {}), group: 'input'
  }))];
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    if (!process.argv[2]) fail('Usage: node tools/config.mjs config/default.json');
    const config = validateConfig(JSON.parse(readFileSync(process.argv[2], 'utf8')));
    console.log(JSON.stringify({valid: true, targets: targets(config)}, null, 2));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
