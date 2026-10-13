package helix.input;

/** One gamepad slot. Edges work as the keyboard's: tick edges until consume(), frame edges until the frame ends.
    Sticks read past a radial dead zone, rescaled so they still reach 1; getRawAxis reads them as the pad reports. */
class Gamepad {
 var connected=false;var name="";var deadzone=.15;
 var held=[for(_ in 0...PadButton.COUNT) false];var pushes=[for(_ in 0...PadButton.COUNT) false];var framePushes=[for(_ in 0...PadButton.COUNT) false];
 var axes=[for(_ in 0...PadAxis.COUNT) 0.];
 public function new(){}
 public function isConnected():Bool return connected;
 public function getName():String return name;
 /** Fraction of a stick's reach that reads as centred. */
 public function getDeadzone():Float return deadzone;
 /** False for a value outside 0 (none) to just under 1. */
 public function setDeadzone(value:Float):Bool {if(!(value>=0&&value<1))return false;deadzone=value;return true;}
 public function isDown(button:PadButton):Bool return held[button];
 public function isPressed(button:PadButton):Bool return pushes[button];
 public function isFramePressed(button:PadButton):Bool return framePushes[button];
 public function getRawAxis(axis:PadAxis):Float return axes[axis];
 public function getAxis(axis:PadAxis):Float {
  if(axis==PadAxis.LeftTrigger||axis==PadAxis.RightTrigger)return axes[axis];
  var left=axis==PadAxis.LeftX||axis==PadAxis.LeftY,x=axes[left?PadAxis.LeftX:PadAxis.RightX],y=axes[left?PadAxis.LeftY:PadAxis.RightY];
  var length=Math.sqrt(x*x+y*y);if(length<=deadzone)return 0;
  var scale=Math.min(1,(length-deadzone)/(1-deadzone))/length;return axes[axis]*scale;
 }
 public function connect(value:Bool,name:String):Void {
  if(connected&&!value)for(button in PadButton.all)buttonEvent(button,false);
  connected=value;this.name=value?name:"";if(!value)for(i in 0...axes.length)axes[i]=0;
 }
 public function buttonEvent(button:PadButton,value:Bool):Void {if(value&&!held[button]){pushes[button]=true;framePushes[button]=true;}held[button]=value;}
 public function axisEvent(axis:PadAxis,value:Float):Void axes[axis]=Math.max(axis==PadAxis.LeftTrigger||axis==PadAxis.RightTrigger?0:-1,Math.min(1,value));
 public function consume():Void for(i in 0...pushes.length)pushes[i]=false;
 public function endFrame():Void for(i in 0...framePushes.length)framePushes[i]=false;
}
