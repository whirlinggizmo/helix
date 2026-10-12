package helix.adapters.input.dom;

import helix.input.InputState;
import helix.input.Key;
import helix.input.PadButton;
import helix.input.PadAxis;
import js.Browser;
import js.html.CanvasElement;

class DomInputAdapter extends InputState {
 public var active=true;var canvas:CanvasElement;
 public function new(canvas:CanvasElement){super();this.canvas=canvas;
  Browser.window.addEventListener("keydown",e->{if(!active)return;var event:js.html.KeyboardEvent=cast e,k=code(event.code);if(k!=null){keyEvent(k,true);event.preventDefault();}});
  Browser.window.addEventListener("keyup",e->{var event:js.html.KeyboardEvent=cast e,k=code(event.code);if(k!=null)keyEvent(k,false);});
  canvas.addEventListener("pointerdown",e->{var event:js.html.PointerEvent=cast e;if(event.button==0){pointer(event,true);canvas.setPointerCapture(event.pointerId);event.preventDefault();}});
  canvas.addEventListener("pointermove",e->pointer(cast e,pointerDown));
  canvas.addEventListener("pointerup",e->pointer(cast e,false));canvas.addEventListener("pointercancel",_->pointerEvent(-1,-1,false));
 }
 static function code(value:String):Null<Key> return switch(value){
  case "Enter":Key.Enter;case "Escape":Key.Escape;case "Tab":Key.Tab;case "Space":Key.Space;
  case "ArrowLeft":Key.Left;case "ArrowRight":Key.Right;case "ArrowUp":Key.Up;case "ArrowDown":Key.Down;
  case "KeyA":Key.A;case "KeyD":Key.D;case "KeyW":Key.W;case "KeyS":Key.S;default:null;
 };
 function pointer(event:js.html.PointerEvent,value:Bool):Void {var box=canvas.getBoundingClientRect();pointerEvent((event.clientX-box.left)*canvas.width/box.width,(event.clientY-box.top)*canvas.height/box.height,value);}
 public function poll():Void {
  if(!active){clear();return;}
  var pads:Dynamic=Browser.navigator.getGamepads(),pad:Dynamic=null;
  for(i in 0...pads.length)if(pads[i]!=null&&pads[i].connected&&pads[i].mapping=="standard"){pad=pads[i];break;}
  var slots=[0,1,5,9,12,13,14,15];
  for(button in PadButton.all)padEvent(button,pad!=null&&pad.buttons.length>slots[button]&&pad.buttons[slots[button]].pressed);
  axisEvent(PadAxis.LeftX,pad!=null&&pad.axes.length>0?pad.axes[0]:0);axisEvent(PadAxis.LeftY,pad!=null&&pad.axes.length>1?pad.axes[1]:0);
  axisEvent(PadAxis.RightTrigger,pad!=null&&pad.buttons.length>7?pad.buttons[7].value:0);
 }
}
