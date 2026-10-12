import helix.graphics.IGraphics;
import haxe.io.Bytes;
import Game.Body;

/** One renderer: transforms, geometry, font quads, batching and order live here. */
class Renderer {
 public static inline var CAPACITY=65536*GeneratedLayout.stride;
 public var vertices(default,null)=0;
 public var draws(default,null)=0;
 public var uploadBytes(default,null)=0;
 public var geometryHash(default,null)="";
 var gpu:IGraphics;var data=Bytes.alloc(CAPACITY);var buffer:Int;var texture:Int;var pipeline:Int;
 var r=1.;var g=1.;var b=1.;var a=1.;
 public function new(gpu:IGraphics){this.gpu=gpu;texture=gpu.createTexture(128,64,Atlas.make());buffer=gpu.createBuffer(CAPACITY);pipeline=gpu.createPipeline(true);}
 function color(r:Float,g:Float,b:Float,a:Float=1.):Void {this.r=r;this.g=g;this.b=b;this.a=a;}
 inline function vertex(x:Float,y:Float,u:Float=127.5/128,v:Float=63.5/64):Void {
  if(vertices>=65536)throw "Geometry capacity exceeded";
  var p=vertices++*GeneratedLayout.stride,position=p+GeneratedLayout.positionOffset,uv=p+GeneratedLayout.uvOffset,color=p+GeneratedLayout.colorOffset;
  data.setFloat(position,x/(Game.W/2.)-1);data.setFloat(position+4,1-y/(Game.H/2.));
  data.setFloat(uv,u);data.setFloat(uv+4,v);data.setFloat(color,r);data.setFloat(color+4,g);data.setFloat(color+8,b);data.setFloat(color+12,a);
 }
 function quad(x:Float,y:Float,w:Float,h:Float,u0:Float=127.5/128,v0:Float=63.5/64,u1:Float=127.5/128,v1:Float=63.5/64):Void {
  vertex(x,y,u0,v0);vertex(x+w,y,u1,v0);vertex(x+w,y+h,u1,v1);
  vertex(x,y,u0,v0);vertex(x+w,y+h,u1,v1);vertex(x,y+h,u0,v1);
 }
 function line(x:Float,y:Float,x2:Float,y2:Float,width:Float=1.5):Void {
  var dx=x2-x,dy=y2-y,len=Math.sqrt(dx*dx+dy*dy);if(len==0)return;
  var px=-dy*width/(2*len),py=dx*width/(2*len);
  vertex(x+px,y+py);vertex(x-px,y-py);vertex(x2-px,y2-py);
  vertex(x+px,y+py);vertex(x2-px,y2-py);vertex(x2+px,y2+py);
 }
 function text(value:String,x:Float,y:Float,scale:Float=3):Void {
  for(i in 0...value.length){var n=value.charCodeAt(i)-32;if(n>=0&&n<64&&n!=0){var ox=n%16*8,oy=Std.int(n/16)*8;quad(x+i*6*scale,y,5*scale,7*scale,(ox+.01)/128,(oy+.01)/64,(ox+5+.01)/128,(oy+7+.01)/64);}}
 }
 function centered(value:String,y:Float,scale:Float=3):Void text(value,(Game.W-value.length*6*scale)/2,y,scale);
 function rock(body:Body):Void {
  var x=body.x/256.,y=body.y/256.,radius=Game.radius(body.size)*1.;
  for(i in 0...10){var a=(body.angle+Std.int(i*256/10))&255,c=(body.angle+Std.int((i+1)*256/10))&255;
   var ra=radius*(body.shape.length==10?body.shape[i]/100.:1.),rb=radius*(body.shape.length==10?body.shape[(i+1)%10]/100.:1.);
   line(x+Trig.cos[a]*ra/1024,y+Trig.sin[a]*ra/1024,x+Trig.cos[c]*rb/1024,y+Trig.sin[c]*rb/1024);
  }
 }
 function rounded(x:Float,y:Float,w:Float,h:Float,radius:Float):Void {
  quad(x+radius,y,w-2*radius,h);quad(x,y+radius,w,h-2*radius);
  for(corner in 0...4){var cx=corner==0||corner==3?x+radius:x+w-radius,cy=corner<2?y+radius:y+h-radius;
   for(i in 0...8){var angle=wrapAngle(128+corner*64+i*8),next=wrapAngle(angle+8);vertex(cx,cy);vertex(cx+Trig.cos[angle]*radius/1024,cy+Trig.sin[angle]*radius/1024);vertex(cx+Trig.cos[next]*radius/1024,cy+Trig.sin[next]*radius/1024);}
  }
 }
 static inline function wrapAngle(value:Int):Int return value&255;
 function shipIcon(x:Float,y:Float):Void {line(x,y-12,x+8,y+10,2);line(x+8,y+10,x,y+5,2);line(x,y+5,x-8,y+10,2);line(x-8,y+10,x,y-12,2);}
 public function render(game:Game,input:Controls,width:Int,height:Int,hash:Bool=false,menu:Menu=null,ready:Bool=true):Void {
  vertices=0;
  color(.22,.27,.36);for(i in 0...100)quad((i*137+51)%Game.W,(i*83+19)%Game.H,1,1);
  color(.78,.80,.84);for(body in game.rocks)rock(body);
  color(1,1,1);for(body in game.bullets)quad(body.x/256.-2,body.y/256.-2,4,4);
  for(body in game.particles){var fade=body.life/(body.lifetime*1.);color(1,.38+.5*fade,.12+.45*fade,fade);quad(body.x/256.-1,body.y/256.-1,2+fade,2+fade);}
  if(game.state=="playing"&&game.respawnDelay==0&&(game.invulnerable==0||game.tick%12<6)){
   var ship=game.ship,x=ship.x/256.,y=ship.y/256.,c=Trig.cos[ship.angle]/1024.,t=Trig.sin[ship.angle]/1024.;
   color(.5,.83,1);line(x+c*18,y+t*18,x-c*12-t*11,y-t*12+c*11,2);line(x-c*12-t*11,y-t*12+c*11,x-c*6,y-t*6,2);
   line(x-c*6,y-t*6,x-c*12+t*11,y-t*12-c*11,2);line(x-c*12+t*11,y-t*12-c*11,x+c*18,y+t*18,2);
  }
  if(game.state!="title"){
   color(.9,.93,.97);text(Std.string(game.score),24,20,3);color(.5,.83,1);for(i in 0...game.lives)shipIcon(32+i*26,72);
   color(.7,.75,.8);text("WAVE "+game.wave,Game.W-150,24,2);
  }
  if(game.state!="playing"){
   var over=game.state=="gameover",selection=menu==null?0:menu.selected,hover=menu==null?-1:menu.hovered;
   color(.055,.07,.12,.94);rounded(245,over?205:235,470,over?330:240,8);
   color(.85,.9,.97);centered(over?"GAME OVER":"ASTEROIDS",over?245:275,6);
   color(.65,.72,.8);centered(over?"SCORE "+game.score+"   BEST "+game.best:"TURN: ARROWS   THRUST: UP   FIRE: SPACE",over?325:345,over?2:1.5);
   for(i in 0...(over?2:1)){
    var y=390+i*64;var focused=i==selection;
    if(focused){color(.45,.85,1);rounded(328,y-2,304,56,5);}
    color(i==hover ? .19 : .12,i==hover ? .24 : .16,i==hover ? .34 : .24);rounded(330,y,300,52,4);
    color(.85,.9,.97);centered(ready?(over?(i==0?"PLAY AGAIN":"TITLE"):"PLAY"):"LOADING",y+17,2.5);
   }
   if(!over&&game.best>0){color(.65,.72,.8);centered("BEST "+game.best,490,2);}
  }
  uploadBytes=vertices*GeneratedLayout.stride;draws=vertices>0?1:0;
  if(hash)geometryHash=haxe.crypto.Sha256.make(data.sub(0,uploadBytes)).toHex();
  var scale=Math.min(width/(Game.W*1.),height/(Game.H*1.)),w=Std.int(Game.W*scale),h=Std.int(Game.H*scale);
  gpu.beginFrame(width,height,Std.int((width-w)/2),Std.int((height-h)/2),w,h);
  gpu.updateBuffer(buffer,data,uploadBytes);if(vertices>0)gpu.draw(pipeline,buffer,texture,vertices,0);gpu.endFrame();
 }
 public function cleanup():Void {gpu.destroy("pipeline",pipeline);gpu.destroy("buffer",buffer);gpu.destroy("texture",texture);gpu.shutdown();}
}
