// The Pages site's thumbnails (tools/pages.py): opens each served example in a headless browser at 1280 x 720, waits, captures the page and
// writes a 640 x 360 WebP, scaled and encoded by the browser itself. First on the GPU; once a page says the platform can't draw
// (window.graphicsUnavailable), the rest on SwiftShader, the browser's software renderer, as CI's machines have no GPU (tools/autopilot.cjs).
// A page is captured once it has settled: its services loading nothing (window.helixBusy false, from Host.isBusy) for SETTLE ms on end,
// so what it loads is in and drawn, or at its wait's end, whichever comes first.
// Arguments: the browser, the site's URL, the output directory, a file for what each page requested (its paths on the site, as JSON by example:
// what it loaded before its capture), then name=milliseconds for each example, the longest wait before its capture.
const fs=require('fs');
const path=require('path');
const {chromium}=require(path.join(__dirname,'../build/tools/node_modules/playwright'));
const [browserPath,site,out,requestsFile,...shots]=require('./cli.cjs').args(__filename,['browser','site','out','requests','name=milliseconds...']);
const requested={};
const GPU=process.platform==='linux'?['--use-angle=vulkan']:process.platform==='darwin'?['--use-angle=metal']:[];
const SOFTWARE=['--use-angle=swiftshader','--enable-unsafe-swiftshader'];
const SETTLE=2000;

// A capture (a PNG) scaled to 640 x 360 and encoded as WebP, by a canvas in page.
async function thumbnail(page,png){
 return Buffer.from(await page.evaluate(async source=>{
  const image=new Image();image.src='data:image/png;base64,'+source;await image.decode();
  const canvas=document.createElement('canvas');canvas.width=640;canvas.height=360;
  const context=canvas.getContext('2d');context.imageSmoothingQuality='high';context.drawImage(image,0,0,640,360);
  return canvas.toDataURL('image/webp',0.85).split(',')[1];},png.toString('base64')),'base64');
}

(async()=>{
 let args=GPU,browser=await chromium.launch({executablePath:browserPath,headless:true,args:['--no-sandbox',...args]});
 const scaler=async()=>(await browser.newPage());
 let scale=await scaler();
 try{
  for(const shot of shots){
   const [name,wait]=shot.split('=');
   for(;;){
    const page=await browser.newPage({viewport:{width:1280,height:720}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
    const paths=requested[name]=[];page.on('requestfinished',r=>{const url=new URL(r.url());if(url.origin===new URL(site).origin)paths.push(decodeURIComponent(url.pathname));});
    await page.goto(`${site}/${name}/?audio=0`);
    // Settled: nothing loading since a moment ago (the page's own clock), or no graphics at all.
    await page.waitForFunction(settle=>{
     if(window.graphicsUnavailable)return true;
     if(window.helixBusy!==false){window.helixIdleSince=undefined;return false;}
     if(window.helixIdleSince===undefined)window.helixIdleSince=performance.now();
     return performance.now()-window.helixIdleSince>=settle;},SETTLE,{timeout:Number(wait),polling:100}).catch(()=>console.log(`pages: ${name} still loading at ${wait} ms`));
    const unavailable=await page.evaluate(()=>window.graphicsUnavailable);
    if(unavailable&&args!==SOFTWARE){
     console.log(`pages: the GPU gave no graphics (${unavailable}); SwiftShader from ${name} on`);
     await browser.close();args=SOFTWARE;browser=await chromium.launch({executablePath:browserPath,headless:true,args:['--no-sandbox',...args]});scale=await scaler();continue;}
    if(unavailable)throw new Error(`${name}: no graphics, on the GPU or in software: ${unavailable}`);
    // The page's own bar (tools/pages.py) isn't part of the example.
    await page.addStyleTag({content:'#helix-pages{display:none!important}'});
    fs.writeFileSync(path.join(out,`${name}.webp`),await thumbnail(scale,await page.screenshot({type:'png'})));
    console.log(`pages: ${name}${errors.length?' (page errors: '+JSON.stringify(errors)+')':''}`);
    await page.close();break;}
  }
 }finally{await browser.close();}
 fs.writeFileSync(requestsFile,JSON.stringify(requested,null,1));
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
