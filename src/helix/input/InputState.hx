package helix.input;

/** Shared edge accumulator used by real adapters, replay and tooling.
    Tick edges (pressed, released) are counted, and consume() after a simulation tick takes one of each, so every press is seen by exactly one tick,
    and two presses between ticks reach two ticks;
    frame edges (framePressed, frameReleased), typed text, the wheel and lifted touches last one frame, until the host's endFrame(). */
class InputState implements IInput {
 var held:Array<Bool>=[for(_ in 0...Key.COUNT) false];var pushes:Array<Int>=[for(_ in 0...Key.COUNT) 0];var lifts:Array<Int>=[for(_ in 0...Key.COUNT) 0];
 var framePushes:Array<Bool>=[for(_ in 0...Key.COUNT) false];var frameLifts:Array<Bool>=[for(_ in 0...Key.COUNT) false];
 var mouseHeld=[false,false,false];var mousePushes=[0,0,0];var mouseFramePushes=[false,false,false];
 public var pads(default,null):Array<Gamepad>=[for(_ in 0...4) new Gamepad()];
 public var pointerX(default,null)=-1.;public var pointerY(default,null)=-1.;
 public var pointerDown(default,null)=false;public var pointerPressed(get,never):Bool;public var pointerReleased(get,never):Bool;
 var pointerPushes=0;var pointerLifts=0;
 function get_pointerPressed():Bool return pointerPushes>0;
 function get_pointerReleased():Bool return pointerLifts>0;
 public var pointerFramePressed(default,null)=false;public var pointerFrameReleased(default,null)=false;
 public var text(default,null)="";
 public var wheelX(default,null)=0.;public var wheelY(default,null)=0.;
 public var touches(default,null):Array<Touch>=[];
 public function new(){}
 public function down(key:Key):Bool return held[key];
 public function pressed(key:Key):Bool return pushes[key]>0;
 public function released(key:Key):Bool return lifts[key]>0;
 public function framePressed(key:Key):Bool return framePushes[key];
 public function frameReleased(key:Key):Bool return frameLifts[key];
 public function mouseDown(button:MouseButton):Bool return mouseHeld[button];
 public function mousePressed(button:MouseButton):Bool return mousePushes[button]>0;
 public function mouseFramePressed(button:MouseButton):Bool return mouseFramePushes[button];
 public function padDown(button:PadButton):Bool {for(pad in pads)if(pad.connected&&pad.down(button))return true;return false;}
 public function padPressed(button:PadButton):Bool {for(pad in pads)if(pad.connected&&pad.pressed(button))return true;return false;}
 public function axis(axis:PadAxis):Float {for(pad in pads)if(pad.connected)return pad.rawAxis(axis);return 0;}
 public function keyEvent(key:Key,value:Bool):Void {
  if(value&&!held[key]){pushes[key]++;framePushes[key]=true;}if(!value&&held[key]){lifts[key]++;frameLifts[key]=true;}held[key]=value;
 }
 public function capture(key:Key,value:Bool,push:Bool,lift:Bool):Void {
  held[key]=value;if(push)pushes[key]++;if(lift)lifts[key]++;framePushes[key]=framePushes[key]||push;frameLifts[key]=frameLifts[key]||lift;
 }
 /** Pad 0's button or axis, connecting it: for replay and tests. */
 public function padEvent(button:PadButton,value:Bool):Void {if(!pads[0].connected)pads[0].connect(true,"replay");pads[0].buttonEvent(button,value);}
 public function axisEvent(axis:PadAxis,value:Float):Void {if(!pads[0].connected)pads[0].connect(true,"replay");pads[0].axisEvent(axis,value);}
 public function mouseEvent(button:MouseButton,value:Bool):Void {if(value&&!mouseHeld[button]){mousePushes[button]++;mouseFramePushes[button]=true;}mouseHeld[button]=value;}
 public function pointerEvent(x:Float,y:Float,value:Bool):Void {
  pointerX=x;pointerY=y;if(value&&!pointerDown){pointerPushes++;pointerFramePressed=true;}if(!value&&pointerDown){pointerLifts++;pointerFrameReleased=true;}pointerDown=value;
 }
 public function capturePointer(x:Float,y:Float,value:Bool,push:Bool,lift:Bool):Void {
  pointerX=x;pointerY=y;pointerDown=value;if(push)pointerPushes++;if(lift)pointerLifts++;pointerFramePressed=pointerFramePressed||push;pointerFrameReleased=pointerFrameReleased||lift;
 }
 public function textEvent(value:String):Void text+=value;
 public function wheelEvent(x:Float,y:Float):Void {wheelX+=x;wheelY+=y;}
 /** A finger down, moved or lifted. A lifted one stays in touches, not down, until the frame ends. */
 public function touchEvent(id:Int,x:Float,y:Float,value:Bool):Void {
  var touch=null;for(t in touches)if(t.id==id&&t.down)touch=t;
  if(touch==null){if(!value)return;touch={id:id,x:x,y:y,down:true,pressed:true,released:false};touches.push(touch);return;}
  touch.x=x;touch.y=y;if(!value){touch.down=false;touch.released=true;}
 }
 public function clear():Void {
  for(key in Key.all)keyEvent(key,false);for(button in MouseButton.all)mouseEvent(button,false);
  for(pad in pads){for(button in PadButton.all)pad.buttonEvent(button,false);for(axis in PadAxis.all)pad.axisEvent(axis,0);pad.consume();pad.endFrame();}
  pointerEvent(-1,-1,false);for(t in touches)if(t.down)touchEvent(t.id,t.x,t.y,false);
  for(i in 0...pushes.length){pushes[i]=0;framePushes[i]=false;}for(i in 0...3){mousePushes[i]=0;mouseFramePushes[i]=false;}pointerPushes=0;pointerFramePressed=false;
 }
 public function consume():Void {
  for(i in 0...pushes.length){if(pushes[i]>0)pushes[i]--;if(lifts[i]>0)lifts[i]--;}for(pad in pads)pad.consume();for(i in 0...3)if(mousePushes[i]>0)mousePushes[i]--;
  if(pointerPushes>0)pointerPushes--;if(pointerLifts>0)pointerLifts--;
 }
 /** The host calls this after each frame. */
 public function endFrame():Void {
  for(i in 0...framePushes.length){framePushes[i]=false;frameLifts[i]=false;}pointerFramePressed=false;pointerFrameReleased=false;
  for(i in 0...3)mouseFramePushes[i]=false;for(pad in pads)pad.endFrame();
  text="";wheelX=0;wheelY=0;touches=[for(t in touches)if(t.down)t];for(t in touches)t.pressed=false;
 }
}
