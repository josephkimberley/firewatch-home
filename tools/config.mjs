// Run the identical ES5 module used by QML, avoiding a second validator contract.
import {readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';
import vm from 'node:vm';
const sandbox = {module:{exports:{}}, Intl};
vm.runInNewContext(readFileSync(new URL('../src/native/LauncherConfig.js',import.meta.url),'utf8'), sandbox, {filename:'LauncherConfig.js'});
const runtime=sandbox.module.exports;
const local=value=>JSON.parse(JSON.stringify(value));
export const validateConfig = config => runtime.validateConfig(config);
export const targets = config => local(runtime.targets(config));
export const defaults = () => local(runtime.defaults());
export const parse = text => local(runtime.parse(text));
export const resolve = text => local(runtime.resolve(text));
export const layout = config => local(runtime.layout(config));
export const clampSelection = runtime.clampSelection;
if(process.argv[1] && import.meta.url===pathToFileURL(process.argv[1]).href) {
  try {
    if(!process.argv[2])throw new Error('Usage: node tools/config.mjs config/default.json');
    const config=parse(readFileSync(process.argv[2],'utf8'));
    console.log(JSON.stringify({valid:true,targets:targets(config)},null,2));
  } catch(error){console.error(error.message);process.exitCode=1;}
}
