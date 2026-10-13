package helix.input;

/** Taps, drags and flicks from IInput's pointer, in screen pixels; touch and mouse alike. Update once per tick, before the input is consumed. */
class PointerGestures {
 /** How far a press may move and still be a tap, and how long it may last. */
 public var slop:Float;public var tapSeconds:Float;
 public var down(default,null)=false;public var pressed(default,null)=false;public var released(default,null)=false;
 /** Moved past slop during this press. */
 public var dragging(default,null)=false;
 public var tapped(default,null)=false;
 public var x(default,null)=0.;public var y(default,null)=0.;public var startX(default,null)=0.;public var startY(default,null)=0.;
 /** Velocity over the last tenth of a second before release, pixels per second. */
 public var flickX(default,null)=0.;public var flickY(default,null)=0.;
 var started=0.;var samples:Array<Float>=[];
 public function new(slop=12.,tapSeconds=.3){this.slop=slop;this.tapSeconds=tapSeconds;}
 public function update(input:IInput,now:Float):Void {
  pressed=false;released=false;tapped=false;flickX=flickY=0;
  if(input.pointerPressed&&!down){down=true;pressed=true;dragging=false;started=now;startX=x=input.pointerX;startY=y=input.pointerY;samples=[];}
  if(down){
   if(input.pointerX>=0){x=input.pointerX;y=input.pointerY;}
   samples.push(now);samples.push(x);samples.push(y);while(samples.length>3&&now-samples[0]>.1)samples.splice(0,3);
   if(!dragging&&(Math.abs(x-startX)>slop||Math.abs(y-startY)>slop))dragging=true;
   if(input.pointerReleased||!input.pointerDown){
    down=false;released=true;tapped=!dragging&&now-started<=tapSeconds;
    var span=now-samples[0];if(span>0){flickX=(x-samples[1])/span;flickY=(y-samples[2])/span;}
   }
  }
 }
}
