// Plays a Blocks autopilot in a headless browser against a served build and prints what the game published.
const path=require('path');
const {chromium}=require(path.join(__dirname,'../build/tools/node_modules/playwright'));
const [browserPath,url]=process.argv.slice(2);
(async()=>{
 const browser=await chromium.launch({executablePath:browserPath,headless:true,args:['--no-sandbox','--use-angle=vulkan']});const errors=[];
 try{const page=await browser.newPage({viewport:{width:800,height:600}});page.on('pageerror',e=>errors.push(e.message));
  await page.goto(url);await page.waitForFunction(()=>window.result,null,{timeout:60000});
  console.log(JSON.stringify({result:await page.evaluate(()=>window.result),errors}));}
 finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
