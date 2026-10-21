// One visit for tools/check_cache.py: opens url in a headless browser over a profile kept between visits (userDataDir, so IndexedDB and the
// HTTP cache persist as a returning visitor's do), offline when asked (after the page itself is in hand), waits, and saves a screenshot;
// prints the page's errors and the screenshot's light and dark pixels (near white, near black: which logos it drew, whatever their turn)
// as JSON. Arguments: the browser, the URL, the profile's directory, the screenshot's path, "offline" or "online".
const path=require('path');
const {chromium}=require(path.join(__dirname,'../build/tools/node_modules/playwright'));
const {PNG}=require(path.join(__dirname,'../build/tools/node_modules/pngjs'));
const [browserPath,url,profile,shot,network]=process.argv.slice(2);
const SOFTWARE=['--use-angle=swiftshader','--enable-unsafe-swiftshader'];

(async()=>{
 const context=await chromium.launchPersistentContext(profile,{executablePath:browserPath,headless:true,args:['--no-sandbox',...SOFTWARE],viewport:{width:800,height:600}});
 const errors=[];
 try{
  const page=context.pages()[0]||await context.newPage();
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  if(network==='offline'){
   // The page and its code from the HTTP cache, then everything after offline: the assets come from the page's own cache or not at all.
   await page.route('**/*',route=>{const u=new URL(route.request().url());
    if(u.pathname.includes('/assets/'))route.abort('internetdisconnected');else route.continue();});
  }
  await page.goto(url);
  await page.waitForTimeout(4000);
  await page.screenshot({path:shot});
 }finally{await context.close();}
 const png=PNG.sync.read(require('fs').readFileSync(shot));let light=0,dark=0;
 for(let i=0;i<png.data.length;i+=4){const v=png.data[i]+png.data[i+1]+png.data[i+2];if(v>720)light++;else if(v<30)dark++;}
 console.log(JSON.stringify({errors,light,dark}));
})().catch(e=>{console.error(e.stack||e);process.exit(1);});
