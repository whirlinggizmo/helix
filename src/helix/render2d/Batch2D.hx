package helix.render2d;
import helix.graphics.IGraphics;
import haxe.io.Bytes;

/** Immediate 2D drawing in world units through a Camera2D. A frame is one upload and one draw per run of a texture. Colors are 0xRRGGBBAA. */
class Batch2D {
 public var vertices(default,null)=0;public var draws(default,null)=0;
 public var font(default,null):Font2D;
 var gpu:IGraphics;var capacity:Int;var data:Bytes;var buffer:Int;var pipeline:Int;var camera:Camera2D;
 var texture:Texture2D;var runStart=0;var runs:Array<Int>=[];
 var r=1.;var g=1.;var b=1.;var a=1.;
 public function new(gpu:IGraphics,capacity=32768){
  this.gpu=gpu;this.capacity=capacity;data=Bytes.alloc(capacity*GeneratedLayout.stride);
  buffer=gpu.createBuffer(capacity*GeneratedLayout.stride);pipeline=gpu.createPipeline(true);font=Font2D.pixel(gpu);texture=font.texture;
 }
 public function begin(camera:Camera2D,clearColor:Int):Void {this.camera=camera;gpu.setClearColor(clearColor);vertices=0;draws=0;runStart=0;runs=[];texture=font.texture;}
 public function end():Void {
  closeRun();gpu.beginFrame(camera.viewportWidth,camera.viewportHeight,0,0,camera.viewportWidth,camera.viewportHeight);
  gpu.updateBuffer(buffer,data,vertices*GeneratedLayout.stride);
  var i=0;while(i<runs.length){gpu.draw(pipeline,buffer,runs[i],runs[i+2],runs[i+1]);draws++;i+=3;}gpu.endFrame();
 }
 /** Later quads sample this texture. */
 public function useTexture(value:Texture2D):Void if(value!=texture){closeRun();texture=value;}
 function closeRun():Void {if(vertices>runStart){runs.push(texture.handle);runs.push(runStart);runs.push(vertices-runStart);}runStart=vertices;}
 inline function color(value:Int):Void {r=(value>>>24)/255;g=((value>>>16)&255)/255;b=((value>>>8)&255)/255;a=(value&255)/255;}
 inline function vertex(x:Float,y:Float,u:Float,v:Float):Void {
  if(vertices>=capacity)throw "Batch2D capacity exceeded";
  var p=vertices++*GeneratedLayout.stride,position=p+GeneratedLayout.positionOffset,uv=p+GeneratedLayout.uvOffset,c=p+GeneratedLayout.colorOffset;
  data.setFloat(position,camera.clipX(x));data.setFloat(position+4,camera.clipY(y));
  data.setFloat(uv,u);data.setFloat(uv+4,v);data.setFloat(c,r);data.setFloat(c+4,g);data.setFloat(c+8,b);data.setFloat(c+12,a);
 }
 /** Untextured shapes need a white texel; switch back to the font's texture when the current one has none. */
 inline function solid():Void if(texture.whiteU<0)useTexture(font.texture);
 public function quad(x:Float,y:Float,w:Float,h:Float,u0:Float,v0:Float,u1:Float,v1:Float,tint:Int):Void {
  color(tint);vertex(x,y,u0,v0);vertex(x+w,y,u1,v0);vertex(x+w,y+h,u1,v1);vertex(x,y,u0,v0);vertex(x+w,y+h,u1,v1);vertex(x,y+h,u0,v1);
 }
 public function rect(x:Float,y:Float,w:Float,h:Float,tint:Int):Void {solid();var u=texture.whiteU,v=texture.whiteV;quad(x,y,w,h,u,v,u,v,tint);}
 public function triangle(x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float,tint:Int):Void {solid();var u=texture.whiteU,v=texture.whiteV;color(tint);vertex(x0,y0,u,v);vertex(x1,y1,u,v);vertex(x2,y2,u,v);}
 public function line(x0:Float,y0:Float,x1:Float,y1:Float,width:Float,tint:Int):Void {
  var dx=x1-x0,dy=y1-y0,length=Math.sqrt(dx*dx+dy*dy);if(length==0)return;var px=-dy*width/(2*length),py=dx*width/(2*length);
  triangle(x0+px,y0+py,x0-px,y0-py,x1-px,y1-py,tint);triangle(x0+px,y0+py,x1-px,y1-py,x1+px,y1+py,tint);
 }
 /** Rectangle outline drawn inside its bounds. */
 public function frame(x:Float,y:Float,w:Float,h:Float,width:Float,tint:Int):Void {rect(x,y,w,width,tint);rect(x,y+h-width,w,width,tint);rect(x,y+width,width,h-2*width,tint);rect(x+w-width,y+width,width,h-2*width,tint);}
 public function roundedRect(x:Float,y:Float,w:Float,h:Float,radius:Float,tint:Int):Void {
  radius=Math.min(radius,Math.min(w,h)/2);rect(x+radius,y,w-2*radius,h,tint);rect(x,y+radius,radius,h-2*radius,tint);rect(x+w-radius,y+radius,radius,h-2*radius,tint);
  for(corner in 0...4){var cx=corner==0||corner==3?x+radius:x+w-radius,cy=corner<2?y+radius:y+h-radius,start=Math.PI+corner*Math.PI/2;
   for(i in 0...6){var p=start+i*Math.PI/12,q=p+Math.PI/12;triangle(cx,cy,cx+Math.cos(p)*radius,cy+Math.sin(p)*radius,cx+Math.cos(q)*radius,cy+Math.sin(q)*radius,tint);}}
 }
 public function cleanup():Void {gpu.destroy("pipeline",pipeline);gpu.destroy("buffer",buffer);font.texture.destroy(gpu);}
}
