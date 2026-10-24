#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { checkAssets, repo } from './check-assets.mjs';

const args=process.argv.slice(2);
if(args.includes('--help')) {
  console.log('Usage: node tools/build.mjs [--zig /path/to/zig] [--python /path/to/python3] [--config local/config.json]\nRequires Zig 0.13.0, Python 3.9+, Node 20+. Writes only dist/. Does not connect to a TV.');
  process.exit(0);
}
let zig=process.env.ZIG || 'zig', python=process.env.PYTHON || 'python3', config='config/default.json';
for(let i=0;i<args.length;i++) {
  if(args[i]==='--zig' && args[i+1]) zig=args[++i];
  else if(args[i]==='--python' && args[i+1]) python=args[++i];
  else if(args[i]==='--config' && args[i+1]) config=args[++i];
  else throw new Error(`Unknown/incomplete argument: ${args[i]}`);
}
function run(command, argv, env={}) {
  const result=spawnSync(command,argv,{cwd:repo,encoding:'utf8',env:{...process.env,...env},maxBuffer:8*1024*1024});
  if(result.error || result.status!==0) throw new Error(`${path.basename(command)} failed: ${result.error?.message || result.stderr || result.stdout}`);
  return result.stdout.trim();
}
try {
  const version=run(zig,['version']);
  if(version!=='0.13.0') throw new Error(`Expected Zig 0.13.0; found ${version}. See docs/BUILD.md.`);
  run(python,['-c','import sys; assert sys.version_info >= (3,9), "Python 3.9+ required"']);
  const assets=checkAssets();
  run(process.execPath,['tools/config.mjs',config]);
  const dist=path.join(repo,'dist'), stage=path.join(dist,'stage');
  fs.mkdirSync(dist,{recursive:true});
  if(fs.existsSync(stage)) fs.rmSync(stage,{recursive:true});
  fs.cpSync(path.join(repo,'src/native'),stage,{recursive:true});
  fs.copyFileSync(path.resolve(repo,config),path.join(stage,'launcher-config.json'));
  const env={ZIG_GLOBAL_CACHE_DIR:path.join(dist,'zig-global-cache'),ZIG_LOCAL_CACHE_DIR:path.join(dist,'zig-local-cache')};
  run(zig,['cc','-target','arm-linux-musleabi','-mcpu=cortex_a9','-static','-Os','-s','-Wall','-Wextra','-Werror','-fno-ident','-Wl,--build-id=none','src/launcher.c','-o',path.join(stage,'minimal-home')],env);
  fs.chmodSync(path.join(stage,'minimal-home'),0o755);
  const app=JSON.parse(fs.readFileSync(path.join(stage,'appinfo.json'),'utf8'));
  const output=path.join(dist,`${app.id}_${app.version}_arm.ipk`);
  console.log(run(python,['tools/package_ipk.py',stage,output]));
  const hash=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  fs.writeFileSync(path.join(dist,'build-report.json'),JSON.stringify({toolchain:{zig:version,target:'arm-linux-musleabi',cpu:'cortex_a9',link:'static'},sourceSha256:hash(path.join(repo,'src/launcher.c')),launcherSha256:hash(path.join(stage,'minimal-home')),packageSha256:hash(output),assets,runtimeVerifiedOnTV:false,systemIntegrationIncluded:false},null,2)+'\n');
  console.log('Built app-only developer preview in dist/. No TV connection or system integration.');
} catch(e) { console.error(e.message); process.exitCode=1; }
