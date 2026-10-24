import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

export const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export function checkAssets(root = repo) {
  const native = path.join(root, 'src/native');
  const errors = [], seen = new Set();
  function need(relative) {
    const normalized = path.normalize(relative);
    if (path.isAbsolute(relative) || normalized.startsWith('..')) { errors.push(`Unsafe asset path: ${relative}`); return; }
    seen.add(normalized);
    const file = path.join(native, normalized);
    if (!fs.existsSync(file) || !fs.lstatSync(file).isFile() || fs.lstatSync(file).isSymbolicLink()) errors.push(`Missing asset: ${relative}`);
  }
  function walk(dir) {
    for (const entry of fs.readdirSync(dir, {withFileTypes:true})) {
      const full = path.join(dir, entry.name);
      if (entry.isSymbolicLink()) errors.push(`Symlink not allowed: ${path.relative(native,full)}`);
      else if (entry.isDirectory()) walk(full);
      else if (/\.(qml|js)$/.test(entry.name)) {
        const text=fs.readFileSync(full,'utf8');
        for (const match of text.matchAll(/["']((?:fonts|assets|previews)\/[^"'\n]+\.(?:png|jpg|ttf|otf))["']/g)) need(match[1]);
      }
    }
  }
  walk(native);
  const appearance = vm.createContext({});
  vm.runInContext(fs.readFileSync(path.join(native,'Appearance.js'),'utf8').replace(/^\.pragma library\s*/,''),appearance);
  for (const scene of ['valley','lookout']) for (const season of ['autumn','winter']) {
    for (const framing of scene === 'valley' ? ['wide'] : ['wide','close']) for (let i=0;i<7;i++) need(appearance.source(scene,season,'colour',i,framing));
    for(let i=0;i<7;i++) need(appearance.thumbnailSource(scene,season,'colour',i));
  }
  for(const file of ['main.qml','HomeControls.qml','AppearancePanel.qml','PaintedScene.qml','StartupCover.qml','landscape.frag','landscape.vert','meteor.frag','meteor.vert','bird.frag','bird.vert']) need(file);
  const app=JSON.parse(fs.readFileSync(path.join(native,'appinfo.json'),'utf8'));
  for(const field of ['icon','largeIcon']) need(app[field]);
  if(app.type!=='native'||app.main!=='minimal-home'||app.id!=='uk.local.minimalhome.native') errors.push('Unexpected application metadata');
  for(const forbidden of ['requiredPermissions','trustLevel','services']) if(forbidden in app) errors.push(`Manifest requests unexpected privilege: ${forbidden}`);
  const inventory=JSON.parse(fs.readFileSync(path.join(root,'themes/inventory.json'),'utf8'));
  let wallpapers=0;
  for(const theme of inventory.themes) for(const phase of theme.phases) {
    const file=path.join(root,phase.path);wallpapers++;
    if(!fs.existsSync(file)) errors.push(`Missing inventoried wallpaper: ${phase.path}`);
    else if(crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')!==phase.sha256) errors.push(`Wallpaper hash differs: ${phase.path}`);
  }
  if(errors.length) throw new Error(errors.join('\n'));
  return {ok:true,wallpapers,referencedAssets:seen.size,systemIntegrationIncluded:false};
}
if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  try { console.log(JSON.stringify(checkAssets(),null,2)); } catch(e) { console.error(e.message); process.exitCode=1; }
}
