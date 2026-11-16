import type {IncomingMessage,ServerResponse} from 'node:http';
import {readFileSync} from 'node:fs';
import {Readable} from 'node:stream';
import {pipeline} from 'node:stream/promises';
import type {AgentConfig} from './config.js';
import type {AgentService} from './agent-service.js';
import {createHandlers} from './handlers.js';

function readBounded(req:IncomingMessage):Promise<Buffer|null>{return new Promise((resolve,reject)=>{
 const chunks:Buffer[]=[];let size=0;
 const cleanup=()=>{req.off('data',data);req.off('end',end);req.off('error',error);req.off('aborted',aborted);};
 const error=(failure:Error)=>{cleanup();reject(failure);};const aborted=()=>error(new Error('Request aborted'));
 const end=()=>{cleanup();resolve(Buffer.concat(chunks));};
 const data=(chunk:Buffer|string)=>{const bytes=Buffer.isBuffer(chunk)?chunk:Buffer.from(chunk);size+=bytes.length;if(size>32768){cleanup();req.resume();resolve(null);}else chunks.push(bytes);};
 req.on('data',data);req.once('end',end);req.once('error',error);req.once('aborted',aborted);
});}
export function createAPIHandler(config:AgentConfig,agent:AgentService,allowedOrigins:ReadonlySet<string>=new Set()){
 const handlers=createHandlers(config,agent);const active=new Set<AbortController>();
 const json=(res:ServerResponse,status:number,detail:string)=>{res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify({detail}));};
 async function handle(req:IncomingMessage,res:ServerResponse){
  const origin=req.headers.origin;
  if(origin&&!allowedOrigins.has(origin)){json(res,403,'Origin is not allowed.');req.resume();return;}
  if(origin){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');}
  if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Methods':'GET, POST, OPTIONS','Access-Control-Allow-Headers':'Content-Type'});res.end();req.resume();return;}
  const assets:Record<string,[string,string]>={'/api/docs':['docs.html','text/html; charset=utf-8'],'/api/openapi.json':['openapi.json','application/json'],'/workflow.svg':['workflow.svg','image/svg+xml'],'/workflow.puml':['workflow.puml','text/plain; charset=utf-8']};
  if(req.method==='GET'&&req.url&&assets[req.url]){const [file,media]=assets[req.url];try{const bytes=readFileSync(new URL('../public/'+file,import.meta.url));res.writeHead(200,{'Content-Type':media,'X-Content-Type-Options':'nosniff'});res.end(bytes);}catch{json(res,503,'Reference asset unavailable. Run npm run build.');}return;}
  if(req.url==='/api/health'&&req.method==='GET'){res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({status:'ok',api_key_configured:config.apiKeyConfigured}));return;}
  const mode=req.url==='/api/agent/query'?'query':req.url==='/api/agent/stream'?'stream':null;
  if(!mode||req.method!=='POST'){json(res,404,'Not found.');req.resume();return;}
  const controller=new AbortController();active.add(controller);
  const abort=()=>{if(!res.writableEnded)controller.abort();};req.once('aborted',abort);res.once('close',abort);
  try{
   const body=await readBounded(req);if(body===null){res.setHeader('Connection','close');json(res,413,'Request body is too large.');return;}
   // Browser Origin was checked against the explicit allowlist above. Native calls have none.
   const headers=new Headers({'Content-Type':req.headers['content-type']||''});
   const request=new Request(`http://127.0.0.1${req.url}`,{method:'POST',headers,body:body.toString('utf8'),signal:controller.signal});
   const response=await handlers[mode](request);
   res.writeHead(response.status,Object.fromEntries(response.headers));res.flushHeaders();
   if(response.body)await pipeline(Readable.fromWeb(response.body as never),res);else res.end();
  }catch{controller.abort();if(!res.headersSent)json(res,500,'The agent service could not process this request.');else if(!res.writableEnded)res.end();}
  finally{active.delete(controller);req.off('aborted',abort);res.off('close',abort);}
 }
 return {handle,abortAll(){for(const request of active)request.abort();}};
}
