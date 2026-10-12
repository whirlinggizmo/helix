const fs=require('node:fs'),path=require('node:path');
const {PNG}=require(path.resolve(__dirname,'../build/tools/node_modules/pngjs'));
const [file,reference,output]=process.argv.slice(2),raw=fs.readFileSync(file);
const match=raw.toString('ascii',0,64).match(/^P6\n(\d+) (\d+)\n255\n/);if(!match)throw Error('Invalid PPM');
const width=Number(match[1]),height=Number(match[2]),header=match[0].length;
if(raw.length!==header+width*height*3)throw Error('Invalid capture extent');const png=new PNG({width,height});
for(let i=0;i<width*height;i++){for(let c=0;c<3;c++)png.data[i*4+c]=raw[header+i*3+c];png.data[i*4+3]=255;}
fs.writeFileSync(output,PNG.sync.write(png));const other=PNG.sync.read(fs.readFileSync(reference));if(other.width!==width||other.height!==height)throw Error('Dimensions differ');
let sum=0,max=0,unmatched=0,different=0;
for(let y=0;y<height;y++)for(let x=0;x<width;x++){
 const i=y*width+x;let delta=0;for(let c=0;c<3;c++){const d=Math.abs(png.data[i*4+c]-other.data[i*4+c]);sum+=d;max=Math.max(max,d);delta=Math.max(delta,d);}
 if(delta>2){different++;let found=false;for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){
  const xx=x+dx,yy=y+dy;if(xx<0||yy<0||xx>=width||yy>=height)continue;let ok=true;
  for(let c=0;c<3;c++)if(Math.abs(png.data[i*4+c]-other.data[(yy*width+xx)*4+c])>2)ok=false;
  if(ok)found=true;
 }if(!found)unmatched++;}
}
console.log(JSON.stringify({meanAbsRgbDifference:sum/(width*height*3),maxRgbDifference:max,pixelsBeyond2:different,unmatchedPixels:unmatched,tolerance:'2 RGB levels or matching browser neighbor within one pixel'}));
