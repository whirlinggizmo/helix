import Game.Actions;
import helix.input.InputState;
import helix.input.PointerGestures;
import helix.render2d.Camera2D;
class BlocksTests {
 static var checks=0;
 static function check(value:Bool,message:String):Void {if(!value)throw message;checks++;}
 static function started(seed=7):Game {var g=new Game(seed),a=new Actions();a.start=true;g.step(a);return g;}
 static function idle(g:Game,ticks:Int):Void {var a=new Actions();for(_ in 0...ticks)g.step(a);}
 static function main():Void {
  var g=started();check(g.state=="playing"&&g.piece>=0,"Start spawns a piece");
  var seen=[g.piece].concat(g.queue.slice(0,6));seen.sort((a,b)->a-b);check(seen.join(",")=="0,1,2,3,4,5,6","First bag holds each piece once");
  for(kind in 0...7)for(turn in 0...4){var c=Pieces.cells[kind][turn],n=0;for(i in 0...4)if(c[i*2]>=0&&c[i*2]<4&&c[i*2+1]>=0&&c[i*2+1]<4)n++;check(n==4,"Rotations stay in their box");}
  check(Pieces.cells[2][1].join(",")=="2,1,1,0,1,1,1,2","T turned clockwise points right");
  // A T in its right rotation with its stem on the left wall: turning clockwise only fits with the kick one cell right.
  g=started();g.piece=2;g.rotation=1;g.px=-1;g.py=10;check(g.fits(2,1,-1,10)&&!g.fits(2,2,-1,10),"T at the wall needs a kick to turn");
  var a=new Actions();a.rotateClockwise=true;g.step(a);check(g.rotation==2&&g.px==0,"Wall kick moves the T off the wall");
  g=started();var kind=g.piece;a=new Actions();a.hold=true;g.step(a);check(g.held==kind&&g.holdUsed,"Hold keeps the piece");
  var current=g.piece;g.step(a);check(g.piece==current&&g.held==kind,"Hold works once per piece");
  g=started();a=new Actions();a.hardDrop=true;g.step(a);check(g.pieces==1&&g.score>0,"Hard drop locks and scores two a row");
  check(g.piece<0&&g.events.indexOf("lock")>=0,"Spawn waits after a lock");idle(g,Game.SPAWN_TICKS);check(g.piece>=0,"Next piece spawns");
  // Lock delay: a piece on the ground locks after LOCK_TICKS without moves.
  g=started();g.py=g.ghostY();var before=g.pieces;idle(g,Game.LOCK_TICKS-1);check(g.pieces==before,"Lock waits");idle(g,1);check(g.pieces==before+1,"Lock delay ends");
  // Line clear: fill the bottom row but one cell, drop an I upright into the gap.
  g=started();for(x in 0...Game.W-1)g.board[(Game.H-1)*Game.W+x]=1;g.piece=0;g.rotation=1;g.px=Game.W-3;g.py=0;
  a=new Actions();a.hardDrop=true;g.step(a);check(g.clearing.length==1&&g.lines==1,"Full row clears");
  idle(g,Game.CLEAR_TICKS);check(g.clearing.length==0&&g.cell(Game.W-1,Game.H-1)!=0&&g.cell(0,Game.H-1)==0,"Rows above fall into the cleared row");
  g=started();for(y in 0...Game.H)for(x in 0...Game.W)g.board[y*Game.W+x]=x==0?0:1;g.piece=-1;g.spawnTimer=1;idle(g,1);check(g.state=="over","Blocked spawn ends the game");
  g=started();a=new Actions();a.pause=true;g.step(a);check(g.state=="paused","Pause");var tick=g.tick;idle(g,30);check(g.tick==tick,"Paused game stands still");a.clear();a.start=true;g.step(a);check(g.state=="playing","Resume");
  var x=new Game(99),y=new Game(99);var s=new Actions();s.start=true;x.step(s);y.step(s);for(i in 0...3000){s.clear();s.left=i%37==0?1:0;s.rotateClockwise=i%53==0;s.hardDrop=i%90==0;x.step(s);y.step(s);}
  check(haxe.Json.stringify(x.snapshot())==haxe.Json.stringify(y.snapshot()),"Seeded play repeats exactly");
  // Gestures, from InputState's pointer as touch delivers it.
  var input=new InputState(),gestures=new PointerGestures(10);
  input.pointerEvent(100,100,true);gestures.update(input,0);input.consume();input.pointerEvent(102,101,false);gestures.update(input,.1);check(gestures.isTapped()&&!gestures.isDragging(),"Short still press taps");
  input.consume();input.pointerEvent(100,100,true);gestures.update(input,1);input.consume();input.pointerEvent(100,100,false);gestures.update(input,1.5);check(!gestures.isTapped(),"Long press is no tap");
  input.consume();input.pointerEvent(100,100,true);gestures.update(input,2);for(i in 1...5){input.consume();input.pointerEvent(100,100+i*40,true);gestures.update(input,2+i/60);}
  input.consume();input.pointerEvent(100,300,false);gestures.update(input,2+5/60);check(gestures.isDragging()&&!gestures.isTapped()&&gestures.getFlickY()>1000,"Fast drag flicks down");
  var camera=new Camera2D();camera.setViewport(400,800);camera.fit(0,0,12,26);check(Math.abs(camera.getZoom()-800/26)<1e-9,"Fit uses the tighter axis");
  check(Math.abs(camera.screenToWorldX(camera.worldToScreenX(3.5))-3.5)<1e-9&&Math.abs(camera.screenToWorldY(camera.worldToScreenY(20))-20)<1e-9,"Screen and world round trip");
  check(Math.abs(camera.clipX(6))<1e-9&&Math.abs(camera.clipY(13))<1e-9,"World center is clip center");
  Sys.println(haxe.Json.stringify({passed:true,checks:checks}));
 }
}
