import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {checkAssets,repo} from '../tools/check-assets.mjs';

test('all approved wallpaper mappings and runtime assets are complete',()=>{
  const report=checkAssets();
  assert.equal(report.wallpapers,42);
  assert.equal(report.systemIntegrationIncluded,false);
});

test('manifest icons have real PNG dimensions suitable for webOS',()=>{
  for(const [name,size] of [['icon.png',80],['large-icon.png',130]]) {
    const b=fs.readFileSync(path.join(repo,'src/native',name));
    assert.equal(b.subarray(1,4).toString(),'PNG');
    assert.equal(b.readUInt32BE(16),size);assert.equal(b.readUInt32BE(20),size);
  }
});
