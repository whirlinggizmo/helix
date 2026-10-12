const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),assert=require('node:assert/strict'),os=require('node:os'),crypto=require('node:crypto');
const {parseArgs}=require('node:util');
const root=path.resolve(__dirname,'..'),out=path.resolve(root,'../results');
const {chromium}=require(path.join(root,'build/tools/node_modules/playwright'));
const {PNG}=require(path.join(root,'build/tools/node_modules/pngjs'));
const {values}=parseArgs({options:{action:{type:'string',default:'checks'},browser:{type:'string'},repeats:{type:'string',default:'3'},script:{type:'string',default:'autopilot/playthrough.json'}}});
assert(['checks','cpu','autopilot'].includes(values.action));const repeats=Number(values.repeats);assert(Number.isInteger(repeats)&&repeats>=1&&repeats<=3);
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');fs.mkdirSync(out,{recursive:true});
const report={action:values.action,date:new Date().toISOString(),completed:false,cpu:os.cpus()[0].model,platform:process.platform,
 artifacts:Object.fromEntries(fs.readdirSync(path.join(root,'build/web'),{recursive:true}).filter(f=>fs.statSync(path.join(root,'build/web',f)).isFile()).map(f=>[f.replaceAll(path.sep,'/'),sha(fs.readFileSync(path.join(root,'build/web',f)))])),checks:[],runs:[]};
const file=path.join(out,'browser-'+values.action+'.json'),save=()=>fs.writeFileSync(file,JSON.stringify(report,null,2)+'\n');
function audit(){
 const proto=WebGL2RenderingContext.prototype;window.traffic={draws:0,uploadBytes:0,errors:[]};
 const clear=proto.clear;proto.clear=function(...a){window.traffic={draws:0,uploadBytes:0,errors:[]};return clear.apply(this,a);};
 const draw=proto.drawArrays;proto.drawArrays=function(...a){window.traffic.draws++;const r=draw.apply(this,a),e=this.getError();if(e)window.traffic.errors.push(e);return r;};
 const upload=proto.bufferSubData;proto.bufferSubData=function(t,o,data){window.traffic.uploadBytes+=data.byteLength;return upload.apply(this,arguments);};
}
(async()=>{
 const server=http.createServer((req,res)=>{const name=new URL(req.url,'http://local').pathname.slice(1)||'index.html';
  if(name==='favicon.ico'){res.writeHead(204).end();return;}
  const base=path.resolve(root,'build/web'),filePath=path.resolve(base,name);
  if(!filePath.startsWith(base+path.sep)||!fs.existsSync(filePath)||!fs.statSync(filePath).isFile()){res.writeHead(404).end();return;}
  res.setHeader('Content-Type',name.endsWith('.js')?'text/javascript':name.endsWith('.html')?'text/html':name.endsWith('.json')?'application/json':name.endsWith('.wav')?'audio/wav':name.endsWith('.ogg')||name.endsWith('.opus')?'audio/ogg':'application/octet-stream');res.setHeader('Cache-Control','no-store');res.end(fs.readFileSync(filePath));});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));let browser;
 try{
  const angle=process.platform==='darwin'?'metal':process.platform==='win32'?'d3d11':'vulkan';
  browser=await chromium.launch({executablePath:values.browser||chromium.executablePath(),headless:true,args:['--no-sandbox','--use-angle='+angle]});
  report.browser=browser.version();report.angle=angle;save();
  async function open(params,instrument=false,setup=null,scale=1){
   const page=await browser.newPage({viewport:{width:800,height:600},deviceScaleFactor:scale}),errors=[];
   page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
   if(instrument)await page.addInitScript(audit);if(setup)await page.addInitScript(setup);
   await page.goto(`http://127.0.0.1:${server.address().port}/?${new URLSearchParams(params)}`);
   await page.waitForFunction(()=>window.inspect&&window.inspect().ready&&window.inspect().frames>0,null,{timeout:30000}).catch(e=>{throw Error(JSON.stringify(errors)+' '+e.message);});assert.deepEqual(errors,[]);
   return {page,errors};
  }
  if(values.action==='checks'){
   for(const tick of [0,180,600,1200,2400]){
    const {page,errors}=await open({tick:String(tick),audio:'0'},true);const state=await page.evaluate(()=>({result:window.result,traffic:window.traffic}));
    assert.deepEqual(errors,[]);assert.equal(state.result.inputTick,tick);assert.equal(state.traffic.draws,1);assert.equal(state.traffic.uploadBytes,state.result.uploadBytes);assert.deepEqual(state.traffic.errors,[]);
    assert(!/SwiftShader|llvmpipe|Software/i.test(state.result.host.renderer));
    const png=await page.locator('canvas').screenshot();fs.writeFileSync(path.join(out,`browser-${tick}.png`),png);
    const pixels=PNG.sync.read(png);let hudPixels=0;
    const region=state.result.game.state==='title'?[200,190,600,400]:[10,10,150,80];
    for(let y=region[1];y<region[3];y++)for(let x=region[0];x<region[2];x++){const p=(y*800+x)*4;if(pixels.data[p+1]>150&&pixels.data[p+2]>180)hudPixels++;}
    assert(hudPixels>100,'Expected readable menu/HUD');report.checks.push({tick,...state,hudPixels});save();await page.close();console.log('Checked frozen tick',tick);
   }
   const {page,errors}=await open({frames:'3600'});assert.equal((await page.evaluate(()=>window.inspect())).game.state,'title');
   await page.mouse.click(400,345);await page.waitForFunction(()=>window.inspect().game.state==='playing');
   const before=await page.evaluate(()=>window.inspect());await page.keyboard.down('w');await page.keyboard.down('Space');
   await page.waitForFunction(()=>window.inspect().game.shots>=3);await page.keyboard.up('w');await page.keyboard.up('Space');
   await page.waitForFunction(()=>window.hostInfo().audioLoops===0);
   const after=await page.evaluate(()=>window.inspect());assert.notDeepEqual(before.game.ship,after.game.ship);assert(after.game.shots>=3);
   await page.setViewportSize({width:1000,height:700});await page.waitForFunction(()=>window.inspect().width===1000&&window.inspect().height===700);
   await page.keyboard.press('ArrowLeft');const audio=await page.evaluate(()=>window.graphicsContract.gl.getError());assert.equal(audio,0);
   const audioInfo=await page.evaluate(()=>window.hostInfo());assert(audioInfo.audioPlayed>=3,'Browser audio was not played after user gesture');
   // Contract errors must be caught before a GPU submission.
   const invalid=await page.evaluate(()=>{let rejected=0;for(const f of [()=>window.graphicsContract.createBuffer(7),()=>window.graphicsContract.createTexture(2,2,{length:3}),()=>window.graphicsContract.draw(999,998,997,3)])try{f();}catch(e){rejected++;}return rejected;});assert.equal(invalid,3);
   await page.locator('canvas').screenshot({path:path.join(out,'browser-interactive.png')});assert.deepEqual(errors,[]);
   report.interactive={start:true,thrust:true,fire:true,resize:true,pointerStart:true,loopStopped:true,invalidContractCallsRejected:invalid,...audioInfo};await page.close();
   const tap=await open({frames:'3600',audio:'0'});
   await tap.page.evaluate(()=>{dispatchEvent(new KeyboardEvent('keydown',{code:'Enter'}));dispatchEvent(new KeyboardEvent('keyup',{code:'Enter'}));});
   await tap.page.waitForFunction(()=>window.inspect().game.state==='playing');report.interactive.shortDomTap=true;
   await tap.page.evaluate(()=>dispatchEvent(new Event('blur')));await tap.page.waitForFunction(()=>!window.inspect().focused);
   const paused=await tap.page.evaluate(()=>window.inspect().game.tick);await tap.page.waitForTimeout(100);assert.equal((await tap.page.evaluate(()=>window.inspect())).game.tick,paused);
   await tap.page.evaluate(()=>dispatchEvent(new Event('focus')));await tap.page.waitForFunction(value=>window.inspect().game.tick>value,paused);report.interactive.focusPauseResume=true;assert.deepEqual(tap.errors,[]);await tap.page.close();
   const controller=await open({frames:'3600'},false,()=>{
    window.fixturePad={connected:true,mapping:'standard',axes:[0,0],buttons:Array.from({length:16},()=>({pressed:false,value:0}))};
    Object.defineProperty(navigator,'getGamepads',{value:()=>[window.fixturePad]});
   });
   await controller.page.keyboard.press('Shift');await controller.page.evaluate(()=>{window.fixturePad.buttons[9]={pressed:true,value:1};});
   await controller.page.waitForFunction(()=>window.inspect().game.state==='playing');
   await controller.page.evaluate(()=>{window.fixturePad.buttons[9]={pressed:false,value:0};window.fixturePad.buttons[1]={pressed:true,value:1};window.fixturePad.buttons[7]={pressed:true,value:.8};window.fixturePad.axes[0]=-.8;});
   await controller.page.waitForFunction(()=>window.inspect().game.shots>=3&&window.inspect().game.thrusting&&window.hostInfo().audioLoops===1);
   await controller.page.evaluate(()=>window.fixturePad.connected=false);await controller.page.waitForFunction(()=>!window.inspect().game.thrusting&&window.hostInfo().audioLoops===0);
   report.interactive.controller='Injected standard browser Gamepad API fixture; no physical-controller claim';assert.deepEqual(controller.errors,[]);await controller.page.close();
   const highDpi=await open({frames:'3600'},false,null,2);assert.equal((await highDpi.page.evaluate(()=>window.inspect())).width,1600);
   await highDpi.page.mouse.click(400,345);await highDpi.page.waitForFunction(()=>window.inspect().game.state==='playing');assert.deepEqual(highDpi.errors,[]);report.interactive.highDpiPointer=true;await highDpi.page.close();
   const missing=await browser.newPage({viewport:{width:800,height:600}}),missingErrors=[];
   missing.on('pageerror',e=>missingErrors.push(e.message));missing.on('console',m=>{if(m.type()==='error')missingErrors.push(m.text());});await missing.route('**/assets/sounds/fire.ogg',route=>route.fulfill({status:404,body:'missing'}));
   await missing.goto(`http://127.0.0.1:${server.address().port}/`);await missing.waitForFunction(()=>window.inspect&&!window.inspect().ready);
   for(let i=0;i<100&&!missingErrors.some(e=>e.includes('Sound load failed'));i++)await missing.waitForTimeout(20);
   assert(missingErrors.some(e=>e.includes('Sound load failed')&&e.includes('404')),JSON.stringify(missingErrors));assert((await missing.locator('#status').textContent()).includes('Sound load failed'));report.interactive.assetFailureReported=true;await missing.close();

  }else if(values.action==='autopilot'){
   const {page,errors}=await open({autopilot:values.script,fast:'1',audio:'0'});
   await page.waitForFunction(()=>window.result,null,{timeout:30000});const result=await page.evaluate(()=>window.result);assert.deepEqual(errors,[]);assert(result.autopilot.completed);
   report.script=values.script;report.result=result;await page.locator('canvas').screenshot({path:path.join(out,'browser-autopilot.png')});await page.close();
  }else{
   for(let repeat=0;repeat<repeats;repeat++){
    const {page,errors}=await open({replay:'1',audio:'0',autoclose:'1',frames:'600'});
    await page.waitForFunction(()=>window.result,null,{timeout:30000});const result=await page.evaluate(()=>window.result);assert.deepEqual(errors,[]);
    assert.equal(result.inputTick,660);assert.equal(result.measuredFrames,600);assert(!/SwiftShader|llvmpipe|Software/i.test(result.host.renderer));
    report.runs.push({repeat,...result});save();await page.close();console.log('Measured browser',repeat,result.phases.cpu.meanMs);
   }
  }
  report.completed=true;save();
 }finally{if(browser)await browser.close();await new Promise(r=>server.close(r));}
})().catch(e=>{save();console.error(e);process.exitCode=1;});
