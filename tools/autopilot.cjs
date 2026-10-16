// Plays an example's autopilot in a headless browser against its served build and prints what the example published (tools/example.py).
const path=require('path');
const {chromium}=require(path.join(__dirname,'../build/tools/node_modules/playwright'));
const [browserPath,url]=process.argv.slice(2);
(async()=>{
 const browser=await chromium.launch({executablePath:browserPath,headless:true,args:['--no-sandbox','--use-angle=vulkan']});const errors=[];
 try{const page=await browser.newPage({viewport:{width:800,height:600}});page.on('pageerror',e=>errors.push(e.message));
  // The page's console errors too, and what the page shows, so a run that never publishes says why.
  page.on('console',m=>{if(m.type()==='error')errors.push('console: '+m.text());});
  await page.goto(url);
  try{await page.waitForFunction(()=>window.result,null,{timeout:60000});}
  catch(e){const status=await page.evaluate(()=>document.getElementById('status')?.textContent||'').catch(()=>'');
   throw new Error(`${e.message}\npage errors: ${JSON.stringify(errors)}\npage status: ${JSON.stringify(status)}`);}
  console.log(JSON.stringify({result:await page.evaluate(()=>window.result),errors}));}
 finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
