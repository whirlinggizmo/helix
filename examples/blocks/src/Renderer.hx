import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** Draws a Game through Batch2D in cell units. */
class Renderer {
 public static final colors=[0x3fd0e0ff,0xf0d040ff,0xa050e0ff,0x50d060ff,0xe04848ff,0x4870e8ff,0xf09030ff];
 var batch:Batch2D;
 public function new(batch:Batch2D){this.batch=batch;}
 static function shade(color:Int,amount:Float):Int {
  inline function channel(shift:Int):Int {var v=(color>>>shift)&255;return Std.int(amount>=0?v+(255-v)*amount:v*(1+amount))<<shift;}
  return channel(24)|channel(16)|channel(8)|(color&255);
 }
 function block(x:Float,y:Float,size:Float,color:Int):Void {
  var edge=size*.14;batch.rect(x,y,size,size,shade(color,-.45));batch.rect(x,y,size-edge,size-edge,shade(color,.35));batch.rect(x+edge,y+edge,size-2*edge,size-2*edge,color);
 }
 /** A piece centered in a box, at a given cell size. */
 function preview(kind:Int,box:Array<Float>,size:Float):Void {
  var c=Pieces.cells[kind][0],minX=9,maxX=0,minY=9,maxY=0;
  for(i in 0...4){minX=Std.int(Math.min(minX,c[i*2]));maxX=Std.int(Math.max(maxX,c[i*2]));minY=Std.int(Math.min(minY,c[i*2+1]));maxY=Std.int(Math.max(maxY,c[i*2+1]));}
  var x=box[0]+(box[2]-(maxX-minX+1)*size)/2,y=box[1]+(box[3]-(maxY-minY+1)*size)/2;
  for(i in 0...4)block(x+(c[i*2]-minX)*size,y+(c[i*2+1]-minY)*size,size,colors[kind]);
 }
 function panel(box:Array<Float>,label:String):Void {batch.roundedRect(box[0],box[1],box[2],box[3],.3,0x141b2bff);Text2D.draw(batch,label,box[0]+box[2]/2,box[1]+.2,.45,0x8090a8ff,Center);}
 function button(box:Array<Float>,label:String,size:Float):Void {batch.roundedRect(box[0],box[1],box[2],box[3],.3,0x22304aff);Text2D.draw(batch,label,box[0]+box[2]/2,box[1]+(box[3]-size)/2,size,0xe0e8f4ff,Center);}
 public function render(game:Game,layout:Layout,camera:Camera2D,tick:Int):Void {
  batch.begin(camera,0x0a0e18ff);
  var fx=layout.fieldX,fy=layout.fieldY,visible=Game.H-Game.HIDDEN;
  batch.rect(fx-.15,fy-.15,Game.W+.3,visible+.3,0x2a3550ff);batch.rect(fx,fy,Game.W,visible,0x05070dff);
  for(x in 1...Game.W)batch.rect(fx+x-.01,fy,.02,visible,0x111827ff);for(y in 1...visible)batch.rect(fx,fy+y-.01,Game.W,.02,0x111827ff);
  for(y in Game.HIDDEN...Game.H){var flash=game.clearing.indexOf(y)>=0;
   for(x in 0...Game.W){var v=game.cell(x,y);if(v>0)block(fx+x,fy+y-Game.HIDDEN,1,flash&&game.clearTimer%6<3?0xffffffff:colors[v-1]);}}
  if(game.piece>=0){
   var c=Pieces.cells[game.piece][game.rotation],ghost=game.ghostY();
   for(i in 0...4){var y=ghost+c[i*2+1]-Game.HIDDEN;if(y>=0)batch.frame(fx+game.px+c[i*2]+.06,fy+y+.06,.88,.88,.08,(colors[game.piece]&0xffffff00)|0x90);}
   for(i in 0...4){var y=game.py+c[i*2+1]-Game.HIDDEN;if(y>=0)block(fx+game.px+c[i*2],fy+y,1,colors[game.piece]);}
  }
  panel(layout.holdBox,"HOLD");if(game.held>=0)preview(game.held,[layout.holdBox[0],layout.holdBox[1]+.5,layout.holdBox[2],layout.holdBox[3]-.5],layout.portrait? 0.6:.8);
  panel(layout.nextBox,"NEXT");
  var count=layout.portrait?1:3,slot=(layout.nextBox[3]-.5)/count;
  for(i in 0...count)if(i<game.queue.length)preview(game.queue[i],[layout.nextBox[0],layout.nextBox[1]+.5+i*slot,layout.nextBox[2],slot],i==0?(layout.portrait? 0.6:.8):.6);
  var sx=layout.scoreX,sy=layout.scoreY;
  Text2D.draw(batch,Std.string(game.score),sx,sy,1,0xf0f4faff,Center);
  Text2D.draw(batch,"LEVEL "+game.level,sx,sy+1.3,.4,0x8090a8ff,Center);Text2D.draw(batch,"LINES "+game.lines,sx,sy+1.9,.4,0x8090a8ff,Center);
  if(game.state=="playing")button(layout.pauseBox,"II",.7);
  if(game.state!="playing"){
   batch.rect(fx,fy,Game.W,visible,0x05070dd0);var cy=fy+visible*.3;
   var title=switch game.state {case "paused":"PAUSED";case "over":"GAME OVER";default:"BLOCKS";};
   Text2D.draw(batch,title,fx+Game.W/2,cy,1.2,0xf0f4faff,Center);
   if(game.best>0)Text2D.draw(batch,"BEST "+game.best,fx+Game.W/2,cy+2,.5,0x8090a8ff,Center);
   if(tick%60<40)Text2D.draw(batch,game.state=="paused"?"TAP OR ENTER TO RESUME":"TAP OR ENTER TO PLAY",fx+Game.W/2,cy+3.5,.4,0xe0e8f4ff,Center);
   if(game.state=="title"){var help=["TAP: TURN   DRAG: MOVE","FLICK DOWN: DROP  UP: HOLD","KEYS: ARROWS Z X SPACE C"];for(i in 0...help.length)Text2D.draw(batch,help[i],fx+Game.W/2,cy+6+i*.8,.35,0x8090a8ff,Center);}
  }
  batch.end();
 }
}
