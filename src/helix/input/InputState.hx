package helix.input;

/** Shared edge accumulator used by real adapters, replay and tooling. */
class InputState implements IInput {
 var held:Array<Bool>=[for(_ in Key.all) false];var pushes:Array<Bool>=[for(_ in Key.all) false];var lifts:Array<Bool>=[for(_ in Key.all) false];
 var padHeld:Array<Bool>=[for(_ in 0...8) false];var padPushes:Array<Bool>=[for(_ in 0...8) false];
 var axes:Array<Float>=[0.,0.,0.];
 public var pointerX(default,null)=-1.;public var pointerY(default,null)=-1.;
 public var pointerDown(default,null)=false;public var pointerPressed(default,null)=false;public var pointerReleased(default,null)=false;
 public function new(){}
 public function down(key:Key):Bool return held[key];
 public function pressed(key:Key):Bool return pushes[key];
 public function released(key:Key):Bool return lifts[key];
 public function padDown(button:PadButton):Bool return padHeld[button];
 public function padPressed(button:PadButton):Bool return padPushes[button];
 public function axis(axis:PadAxis):Float return axes[axis];
 public function keyEvent(key:Key,value:Bool):Void {
  if(value&&!held[key])pushes[key]=true;if(!value&&held[key])lifts[key]=true;held[key]=value;
 }
 public function capture(key:Key,value:Bool,push:Bool,lift:Bool):Void {held[key]=value;pushes[key]=pushes[key]||push;lifts[key]=lifts[key]||lift;}
 public function padEvent(button:PadButton,value:Bool):Void {if(value&&!padHeld[button])padPushes[button]=true;padHeld[button]=value;}
 public function axisEvent(axis:PadAxis,value:Float):Void {axes[axis]=Math.max(-1,Math.min(1,value));}
 public function pointerEvent(x:Float,y:Float,value:Bool):Void {
  pointerX=x;pointerY=y;if(value&&!pointerDown)pointerPressed=true;if(!value&&pointerDown)pointerReleased=true;pointerDown=value;
 }
 public function capturePointer(x:Float,y:Float,value:Bool,push:Bool,lift:Bool):Void {pointerX=x;pointerY=y;pointerDown=value;pointerPressed=pointerPressed||push;pointerReleased=pointerReleased||lift;}
 public function clear():Void {
  for(key in Key.all)keyEvent(key,false);for(button in PadButton.all)padEvent(button,false);for(i in 0...3)axes[i]=0;
  pointerEvent(-1,-1,false);
  for(i in 0...pushes.length)pushes[i]=false;for(i in 0...8)padPushes[i]=false;pointerPressed=false;
 }
 public function consume():Void {
  for(i in 0...pushes.length){pushes[i]=false;lifts[i]=false;}for(i in 0...8)padPushes[i]=false;
  pointerPressed=false;pointerReleased=false;
 }
}
