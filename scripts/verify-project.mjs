import assert from 'node:assert/strict';
import {readFileSync,existsSync,readdirSync} from 'node:fs';
const read=p=>readFileSync(p,'utf8');
const steps=JSON.parse(read('apple/SmallestAgent/Resources/workflow.json'));
assert.deepEqual(steps.map(s=>s.number),Array.from({length:16},(_,i)=>i+1));
for(const step of steps){assert.ok(Number.isInteger(step.from)&&step.from>=0&&step.from<6);assert.ok(Number.isInteger(step.to)&&step.to>=0&&step.to<6);assert.ok(existsSync(step.source));const lines=read(step.source).split(/\r?\n/);assert.ok(step.code);assert.ok(lines[step.line-1].trim()===step.code.split('\n')[0].trim(),step.source+':'+step.line);}
const pbx=read('apple/SmallestAgent.xcodeproj/project.pbxproj');
for(const name of readdirSync('apple/SmallestAgent').filter(n=>n.endsWith('.swift')))assert.ok(pbx.includes('"'+name+'"'),name+' absent from Xcode project');
assert.ok(pbx.includes('SmallestAgentTests'));assert.ok(pbx.includes('Resources'));assert.ok(existsSync('apple/SmallestAgent.xcodeproj/xcshareddata/xcschemes/SmallestAgent.xcscheme'));
assert.match(read('apple/SmallestAgent/Info-Debug.plist'),/NSAllowsArbitraryLoads/);assert.doesNotMatch(read('apple/SmallestAgent/Info-Release.plist'),/NSAllowsArbitraryLoads/);
const app=read('apple/SmallestAgent/ContentView.swift');assert.equal((app.match(/\.tabItem/g)||[]).length,5);
assert.match(read('apple/SmallestAgent/Resources/workflow.svg'),/SwiftUI client/);assert.match(read('apple/SmallestAgent/Resources/workflow.svg'),/fill="none"/);
console.log('Project/resource checks passed: five native tabs, all Swift file references, debug/release plist boundaries and 16 real source excerpts. This is not an Xcode compilation.');
