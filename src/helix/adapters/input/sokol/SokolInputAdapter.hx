package helix.adapters.input.sokol;
import helix.adapters.input.sokol.internal.InputBridge;

import helix.input.InputState;
import helix.input.Key;
import helix.input.PadButton;
import helix.input.PadAxis;
class SokolInputAdapter extends InputState {
 static final codes=[13,27,9,32,37,39,38,40,65,68,87,83,90,88,67,80,16];
 public function new(){super();InputBridge.inputSetup();}
 public function poll():Void {
  InputBridge.inputPoll();
  for(key in Key.all)capture(key,InputBridge.key(codes[key])!=0,InputBridge.keyPressed(codes[key])!=0,InputBridge.keyReleased(codes[key])!=0);
  capturePointer(InputBridge.pointerX(),InputBridge.pointerY(),InputBridge.pointerDown()!=0,InputBridge.pointerPressed()!=0,InputBridge.pointerReleased()!=0);
  for(button in PadButton.all)padEvent(button,InputBridge.padButton(button)!=0);
  for(axis in [PadAxis.LeftX,PadAxis.LeftY,PadAxis.RightTrigger])axisEvent(axis,InputBridge.padAxis(axis));
  if(InputBridge.focused()==0)clear();
 }
 override public function consume():Void {super.consume();InputBridge.inputConsume();}
 public function shutdown():Void InputBridge.inputShutdown();
}
