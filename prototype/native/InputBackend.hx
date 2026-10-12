import hybrid.InputState;
import hybrid.Key;
import hybrid.PadButton;
import hybrid.PadAxis;
class InputBackend extends InputState {
 static final codes=[13,27,9,32,37,39,38,40,65,68,87,83];
 public function new(){super();Native.inputSetup();}
 public function poll():Void {
  Native.inputPoll();
  for(key in Key.all)capture(key,Native.key(codes[key])!=0,Native.keyPressed(codes[key])!=0,Native.keyReleased(codes[key])!=0);
  capturePointer(Native.pointerX(),Native.pointerY(),Native.pointerDown()!=0,Native.pointerPressed()!=0,Native.pointerReleased()!=0);
  for(button in PadButton.all)padEvent(button,Native.padButton(button)!=0);
  for(axis in [PadAxis.LeftX,PadAxis.LeftY,PadAxis.RightTrigger])axisEvent(axis,Native.padAxis(axis));
  if(Native.focused()==0)clear();
 }
 override public function consume():Void {super.consume();Native.inputConsume();}
 public function shutdown():Void Native.inputShutdown();
}
