package helix.debug;
import helix.render2d.Batch2D;
import helix.render2d.Text2D;

/** The frame rate and the frame's cost, averaged over half a second, drawn in a corner in screen units (a Camera2D at zoom 1). */
class FpsOverlay {
 public var rate(default,null)=0.;public var milliseconds(default,null)=0.;
 var frames=0;var time=0.;var cost=0.;
 public function new(){}
 /** dt: the frame's interval; cpu: what the frame cost, in milliseconds (IDiagnostics.frameCpu). */
 public function update(dt:Float,cpu:Float):Void {
  frames++;time+=dt;cost+=cpu;
  if(time>=.5){rate=frames/time;milliseconds=cost/frames;frames=0;time=0;cost=0;}
 }
 public function draw(batch:Batch2D,x:Float,y:Float,size=16.,color=0x7fe07fff):Void Text2D.draw(batch,Std.int(rate+.5)+' FPS  '+(Math.round(milliseconds*10)/10)+' MS',x,y,size,color);
}
