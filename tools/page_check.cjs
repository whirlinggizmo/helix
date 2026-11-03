// Serves a directory (SITE), or takes a page already served (SITE an http or https URL), opens its page in a headless Chromium with the query given, waits for the page's frames to settle and saves a
// screenshot of the 800 x 600 viewport, printing {errors, result} as JSON: the page's errors and console errors, and what a test page
// leaves in window.helixResult (null for a page that has none). A page that sets window.helixResult to null is waited on, up to 30
// seconds, until it holds the result. Run by tools/platform_checks.py, which checks an example's screenshot and a test's result.
// BROWSER is a Chromium to run, or "" for Playwright's own (the repository's, build/tools, or the one HELIX_PLAYWRIGHT names). The page
// runs on the GPU (Vulkan on Linux, Metal on macOS); where the page says it can't draw it runs again on SwiftShader. Audio is muted, and
// allowed to start without a gesture so a test page can check it. A query naming safeArea=TOP,RIGHT,BOTTOM,LEFT (CSS pixels) has Chromium
// report those as the page's env(safe-area-inset-*), as a phone with a notch would.
const [browserPath,site,query,output]=require('./cli.cjs').args(__filename,['browser','site','query','output']);
const path=require('path');
const {chromium}=require(process.env.HELIX_PLAYWRIGHT||path.join(__dirname,'../build/tools/node_modules/playwright'));
const GPU=process.platform==='linux'?['--use-angle=vulkan']:process.platform==='darwin'?['--use-angle=metal']:[];
const SOFTWARE=['--use-angle=swiftshader','--enable-unsafe-swiftshader'];

function serve(directory){
 const http=require('http'),fs=require('fs'),root=path.resolve(directory);
 const TYPES={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.svg':'image/svg+xml','.png':'image/png'};
 const server=http.createServer((request,response)=>{
  let file=path.normalize(path.join(root,decodeURIComponent(new URL(request.url,'http://x').pathname)));
  if(!file.startsWith(root)){response.writeHead(403);response.end();return;}
  if(fs.existsSync(file)&&fs.statSync(file).isDirectory())file=path.join(file,'index.html');
  if(!fs.existsSync(file)){response.writeHead(404);response.end();return;}
  response.writeHead(200,{'Content-Type':TYPES[path.extname(file)]||'application/octet-stream'});fs.createReadStream(file).pipe(response);});
 return new Promise(resolve=>server.listen(0,'127.0.0.1',()=>resolve(server)));
}

async function run(address,args){
 const browser=await chromium.launch({executablePath:browserPath||undefined,headless:true,args:['--no-sandbox','--mute-audio','--autoplay-policy=no-user-gesture-required',...args]});const errors=[];
 try{const page=await browser.newPage({viewport:{width:800,height:600}});
  page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push('console: '+m.text());});
  const safeArea=new URLSearchParams(query).get('safeArea');
  if(safeArea){const [top,right,bottom,left]=safeArea.split(',').map(Number);
   await (await page.context().newCDPSession(page)).send('Emulation.setSafeAreaInsetsOverride',{insets:{top,right,bottom,left}});}
  await page.goto(address);
  // A second of frames, then two more animation frames so the last one drawn is composited.
  await page.waitForTimeout(1000);
  await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));
  const webgl=await page.evaluate(()=>!!document.createElement('canvas').getContext('webgl2'));
  if(!webgl)return {unavailable:true};
  if(await page.evaluate(()=>window.helixResult===null))
   await page.waitForFunction(()=>window.helixResult!==null,null,{timeout:30000}).catch(()=>errors.push('no result after 30 seconds'));
  const result=await page.evaluate(()=>window.helixResult===undefined?null:window.helixResult);
  await page.screenshot({path:output});return {errors,result};}
 finally{await browser.close();}
}

(async()=>{
 const served=/^https?:\/\//.test(site),server=served?null:await serve(site);
 try{const address=served?`${site}${query}`:`http://127.0.0.1:${server.address().port}/${query}`;
  let result=await run(address,GPU);
  if(result.unavailable)result=await run(address,SOFTWARE);
  if(result.unavailable){console.error('WebGL2 is unavailable, on the GPU and on SwiftShader');process.exit(1);}
  console.log(JSON.stringify(result));}
 finally{if(server)server.close();}
})().catch(e=>{console.error(e.stack||String(e));process.exit(1);});
