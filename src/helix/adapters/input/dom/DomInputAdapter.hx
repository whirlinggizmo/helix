package helix.adapters.input.dom;

import helix.input.InputState;
import helix.input.Key;
import helix.input.MouseButton;
import helix.input.PadButton;
import helix.input.PadAxis;
import js.Browser;
import js.html.CanvasElement;

class DomInputAdapter extends InputState {
 public var active=true;var canvas:CanvasElement;
 /** Fingers down on the canvas; the first is the pointer until a second lands, then none is until all lift. */
 var fingers:Array<Int>=[];var pointerFinger=-1;var gesture=false;
 public function new(canvas:CanvasElement){super();this.canvas=canvas;
  Browser.window.addEventListener("keydown",e->{
   if(!active)return;var event:js.html.KeyboardEvent=cast e,k=codes.get(event.code);
   var shortcut=event.ctrlKey||event.metaKey||event.altKey;
   if(k!=null){keyEvent(k,true);var n:Int=k;if(!shortcut&&!(n>=(Key.F1:Int)&&n<=(Key.F25:Int)))event.preventDefault();}
   // Typed characters: event.key is one character (or a surrogate pair) once the layout is applied.
   if(!shortcut&&event.key!=null&&(event.key.length==1||event.key.length==2&&StringTools.fastCodeAt(event.key,0)>=0xD800))textEvent(event.key);
  });
  Browser.window.addEventListener("keyup",e->{var event:js.html.KeyboardEvent=cast e,k=codes.get(event.code);if(k!=null)keyEvent(k,false);});
  canvas.addEventListener("contextmenu",e->e.preventDefault());
  canvas.addEventListener("pointerdown",e->{var event:js.html.PointerEvent=cast e;canvas.setPointerCapture(event.pointerId);event.preventDefault();
   if(event.pointerType=="touch")finger(event,true);else{mouse(event.buttons);if(event.button==0)pointer(event,true);}});
  canvas.addEventListener("pointermove",e->{var event:js.html.PointerEvent=cast e;
   if(event.pointerType=="touch")finger(event,fingers.indexOf(event.pointerId)>=0);else{mouse(event.buttons);pointer(event,event.buttons&1!=0);}});
  canvas.addEventListener("pointerup",e->{var event:js.html.PointerEvent=cast e;
   if(event.pointerType=="touch")finger(event,false);else{mouse(event.buttons);if(event.button==0)pointer(event,false);}});
  canvas.addEventListener("pointercancel",e->{var event:js.html.PointerEvent=cast e;if(event.pointerType=="touch")finger(event,false);else pointerEvent(-1,-1,false);});
  canvas.addEventListener("wheel",e->{var event:js.html.WheelEvent=cast e;event.preventDefault();
   // Notches: Chromium and Firefox report about 100 pixels or 3 lines a notch.
   var scale=event.deltaMode==0?1/100:event.deltaMode==1?1/3:1;wheelEvent(event.deltaX*scale,-event.deltaY*scale);},{passive:false});
 }
 function position(event:js.html.PointerEvent):{x:Float,y:Float} {var box=canvas.getBoundingClientRect();return {x:(event.clientX-box.left)*canvas.width/box.width,y:(event.clientY-box.top)*canvas.height/box.height};}
 function pointer(event:js.html.PointerEvent,value:Bool):Void {var p=position(event);pointerEvent(p.x,p.y,value);}
 /** Every button from the event's bitmask: a second button pressed while one is held arrives as a move, not a down. */
 function mouse(buttons:Int):Void {mouseEvent(MouseButton.Left,buttons&1!=0);mouseEvent(MouseButton.Right,buttons&2!=0);mouseEvent(MouseButton.Middle,buttons&4!=0);}
 function finger(event:js.html.PointerEvent,value:Bool):Void {
  var p=position(event),id=event.pointerId;touchEvent(id,p.x,p.y,value);
  if(value&&fingers.indexOf(id)<0)fingers.push(id);if(!value)fingers.remove(id);
  // A second finger lets the pointer go, off the window, so a pinch never drops or clicks anything.
  if(fingers.length>1&&!gesture){gesture=true;if(pointerFinger>=0){pointerEvent(-1,-1,false);pointerFinger=-1;}}
  if(gesture){if(fingers.length==0)gesture=false;return;}
  if(pointerFinger<0&&value){pointerFinger=id;pointerEvent(p.x,p.y,true);}
  else if(id==pointerFinger){pointerEvent(p.x,p.y,value);if(!value)pointerFinger=-1;}
 }
 public function poll():Void {
  if(!active){clear();return;}
  // The first four pads the page sees, in the W3C standard layout; a page sees a pad only after a button press on it.
  var list:Dynamic=Browser.navigator.getGamepads(),slot=0;
  for(i in 0...list.length){
   var pad:Dynamic=list[i];if(pad==null||!pad.connected||slot>=4)continue;var state=pads[slot++];
   if(!state.connected||state.name!=pad.id)state.connect(true,pad.id);
   for(button in PadButton.all){var b:Int=button;state.buttonEvent(button,pad.buttons.length>b&&pad.buttons[b].pressed);}
   for(axis in [PadAxis.LeftX,PadAxis.LeftY,PadAxis.RightX,PadAxis.RightY]){var a:Int=axis;state.axisEvent(axis,pad.axes.length>a?pad.axes[a]:0);}
   state.axisEvent(PadAxis.LeftTrigger,pad.buttons.length>6?pad.buttons[6].value:0);state.axisEvent(PadAxis.RightTrigger,pad.buttons.length>7?pad.buttons[7].value:0);
  }
  while(slot<4){if(pads[slot].connected)pads[slot].connect(false,"");slot++;}
 }
 /** KeyboardEvent.code to Key, by place on the keyboard. */
 static final codes:Map<String,Key>={
  var m=new Map<String,Key>();
  for(i in 0...26)m.set("Key"+String.fromCharCode(65+i),cast (65+i));for(i in 0...10){m.set("Digit"+i,cast (48+i));m.set("Numpad"+i,cast (320+i));}
  for(i in 1...26)m.set("F"+i,cast (289+i));
  var named:Map<String,Key>=["Space"=>Key.Space,"Quote"=>Key.Apostrophe,"Comma"=>Key.Comma,"Minus"=>Key.Minus,"Period"=>Key.Period,"Slash"=>Key.Slash,"Semicolon"=>Key.Semicolon,"Equal"=>Key.Equal,"BracketLeft"=>Key.LeftBracket,"Backslash"=>Key.Backslash,"BracketRight"=>Key.RightBracket,"Backquote"=>Key.Grave,"IntlBackslash"=>Key.World1,"IntlRo"=>Key.World2,"Escape"=>Key.Escape,"Enter"=>Key.Enter,"Tab"=>Key.Tab,"Backspace"=>Key.Backspace,"Insert"=>Key.Insert,"Delete"=>Key.Delete,"ArrowRight"=>Key.Right,"ArrowLeft"=>Key.Left,"ArrowDown"=>Key.Down,"ArrowUp"=>Key.Up,"PageUp"=>Key.PageUp,"PageDown"=>Key.PageDown,"Home"=>Key.Home,"End"=>Key.End,"CapsLock"=>Key.CapsLock,"ScrollLock"=>Key.ScrollLock,"NumLock"=>Key.NumLock,"PrintScreen"=>Key.PrintScreen,"Pause"=>Key.Pause,"NumpadDecimal"=>Key.KeypadDecimal,"NumpadDivide"=>Key.KeypadDivide,"NumpadMultiply"=>Key.KeypadMultiply,"NumpadSubtract"=>Key.KeypadSubtract,"NumpadAdd"=>Key.KeypadAdd,"NumpadEnter"=>Key.KeypadEnter,"NumpadEqual"=>Key.KeypadEqual,"ShiftLeft"=>Key.Shift,"ShiftRight"=>Key.Shift,"ControlLeft"=>Key.Control,"ControlRight"=>Key.Control,"AltLeft"=>Key.Alt,"AltRight"=>Key.Alt,"MetaLeft"=>Key.Super,"MetaRight"=>Key.Super,"ContextMenu"=>Key.Menu];
  for(code=>key in named)m.set(code,key);
  m;
 };
}
