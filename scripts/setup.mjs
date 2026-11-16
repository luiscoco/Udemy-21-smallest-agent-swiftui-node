import {existsSync,copyFileSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');process.chdir(root);
const cli=process.env.npm_execpath||resolve(dirname(process.execPath),'node_modules/npm/bin/npm-cli.js');
const result=spawnSync(process.execPath,[cli,'--prefix','backend','ci'],{stdio:'inherit'});if(result.error)throw result.error;if(result.status!==0)process.exit(result.status??1);
if(!existsSync('backend/.env')){copyFileSync('backend/.env.example','backend/.env');console.log('Created backend/.env with a placeholder key. Existing configurations are preserved.');}
const generated=spawnSync(process.execPath,['scripts/generate-lesson.mjs'],{stdio:'inherit'});process.exit(generated.status??1);
