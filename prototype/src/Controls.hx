import hybrid.IInput;
import hybrid.Key;
import hybrid.PadButton;
import hybrid.PadAxis;
class Controls {
 public var start=false;public var title=false;public var quit=false;public var next=false;
 public var left=false;public var right=false;public var thrust=false;public var fire=false;
 public function new(){}
 public function read(input:IInput):Void {
  start=input.pressed(Key.Enter)||input.padPressed(PadButton.South)||input.padPressed(PadButton.Start);
  title=false;quit=input.pressed(Key.Escape);next=input.pressed(Key.Tab)||input.pressed(Key.Up)||input.pressed(Key.Down)||input.padPressed(PadButton.Up)||input.padPressed(PadButton.Down);
  left=input.down(Key.Left)||input.pressed(Key.Left)||input.down(Key.A)||input.padDown(PadButton.Left)||input.axis(PadAxis.LeftX)<-.4;
  right=input.down(Key.Right)||input.pressed(Key.Right)||input.down(Key.D)||input.padDown(PadButton.Right)||input.axis(PadAxis.LeftX)>.4;
  thrust=input.down(Key.Up)||input.pressed(Key.Up)||input.down(Key.W)||input.padDown(PadButton.South)||input.axis(PadAxis.RightTrigger)>.3;
  fire=input.down(Key.Space)||input.pressed(Key.Space)||input.padDown(PadButton.East)||input.padDown(PadButton.RightBumper);
 }
 public function replay(tick:Int):Void {start=tick==0||tick==900;title=false;quit=false;next=false;fire=true;thrust=tick%240<120;left=tick%360<110;right=tick%360>=240;}
}
