import helix.input.InputState;
import helix.input.Key;
import helix.input.MouseButton;
import helix.input.PadButton;
import helix.input.PadAxis;
import helix.app.Ticker;
class InputTests {
 static var checks=0;
 static function check(value:Bool,message:String):Void {if(!value)throw message;checks++;}
 public static function main():Void {
  var input=new InputState();
  // Two taps between ticks reach two ticks; the frame sees them once, until the frame ends.
  for(_ in 0...2){input.keyEvent(Key.Enter,true);input.keyEvent(Key.Enter,false);}
  check(input.framePressed(Key.Enter)&&input.pressed(Key.Enter),"Both edges set");
  input.consume();check(input.pressed(Key.Enter)&&input.released(Key.Enter),"Second tap waits for the next tick");
  input.consume();check(!input.pressed(Key.Enter),"Each tap seen once");
  input.endFrame();check(!input.framePressed(Key.Enter),"Frame edge ends with the frame");
  input.keyEvent(Key.Space,true);input.consume();input.keyEvent(Key.Space,true);check(input.down(Key.Space)&&!input.pressed(Key.Space),"Repeat is no new press");
  check(Key.named("f12")==Key.F12&&Key.fromCode(344)==Key.Shift&&Key.fromCode(999)==null&&Key.all.length==116&&Key.named("menu")==Key.Menu&&Key.named("keypadequal")==Key.KeypadEqual,"Key names and codes");
  // Text, wheel and touches last one frame; a lifted touch stays until then.
  input.textEvent("ab");input.wheelEvent(0,1);input.touchEvent(7,10,20,true);input.touchEvent(7,12,20,false);
  check(input.text=="ab"&&input.wheelY==1&&input.touches.length==1&&input.touches[0].released,"Frame values");
  input.endFrame();check(input.text==""&&input.wheelY==0&&input.touches.length==0,"Frame values end");
  // Mouse buttons and the pointer count like keys.
  input.mouseEvent(MouseButton.Right,true);input.mouseEvent(MouseButton.Right,false);input.mouseEvent(MouseButton.Right,true);
  check(input.mousePressed(MouseButton.Right)&&input.mouseDown(MouseButton.Right),"Mouse edges");input.consume();check(input.mousePressed(MouseButton.Right),"Second click next tick");
  input.pointerEvent(5,5,true);input.pointerEvent(5,5,false);check(input.pointerPressed&&input.pointerReleased,"Pointer tap keeps both edges");input.consume();check(!input.pointerPressed,"Pointer tap seen once");
  // Pads: any-pad queries, and a stick's radial dead zone.
  input.padEvent(PadButton.North,true);input.axisEvent(PadAxis.LeftX,.1);
  check(input.padDown(PadButton.North)&&input.pads[0].axis(PadAxis.LeftX)==0&&input.axis(PadAxis.LeftX)==.1,"Dead zone");
  input.axisEvent(PadAxis.LeftX,1);check(Math.abs(input.pads[0].axis(PadAxis.LeftX)-1)<1e-9,"Full reach past the dead zone");
  // Ticker: fixed steps, a pause, bounded catch-up, and input consumed per tick.
  var ticker=new Ticker(input,10),ticks=0;input.keyEvent(Key.A,true);input.keyEvent(Key.A,false);var seen=0;
  ticker.advance(.25,()->{ticks++;if(input.pressed(Key.A))seen++;});check(ticks==2&&seen==1&&Math.abs(ticker.fraction-.5)<1e-9,"Ticks and fraction");
  ticker.timeScale=0;ticker.advance(1,()->ticks++);check(ticks==2,"Paused");
  ticker.timeScale=1;ticker.advance(.25,()->ticks++);ticker.advance(.25,()->ticks++);check(ticks==7,"Accumulates");
  Sys.println(haxe.Json.stringify({passed:true,checks:checks}));
 }
}
