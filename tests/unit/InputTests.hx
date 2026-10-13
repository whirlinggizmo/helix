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
  check(input.isFramePressed(Key.Enter)&&input.isPressed(Key.Enter),"Both edges set");
  input.consume();check(input.isPressed(Key.Enter)&&input.isReleased(Key.Enter),"Second tap waits for the next tick");
  input.consume();check(!input.isPressed(Key.Enter),"Each tap seen once");
  input.endFrame();check(!input.isFramePressed(Key.Enter),"Frame edge ends with the frame");
  input.keyEvent(Key.Space,true);input.consume();input.keyEvent(Key.Space,true);check(input.isDown(Key.Space)&&!input.isPressed(Key.Space),"Repeat is no new press");
  check(Key.named("f12")==Key.F12&&Key.fromCode(344)==Key.Shift&&Key.fromCode(999)==null&&Key.all.length==116&&Key.named("menu")==Key.Menu&&Key.named("keypadequal")==Key.KeypadEqual,"Key names and codes");
  // Text, wheel and touches last one frame; a lifted touch stays until then.
  input.textEvent("ab");input.wheelEvent(0,1);input.touchEvent(7,10,20,true);input.touchEvent(7,12,20,false);
  check(input.getText()=="ab"&&input.getWheelY()==1&&input.getTouches().length==1&&input.getTouches()[0].released,"Frame values");
  input.endFrame();check(input.getText()==""&&input.getWheelY()==0&&input.getTouches().length==0,"Frame values end");
  // Mouse buttons and the pointer count like keys.
  input.mouseEvent(MouseButton.Right,true);input.mouseEvent(MouseButton.Right,false);input.mouseEvent(MouseButton.Right,true);
  check(input.isMousePressed(MouseButton.Right)&&input.isMouseDown(MouseButton.Right),"Mouse edges");input.consume();check(input.isMousePressed(MouseButton.Right),"Second click next tick");
  input.pointerEvent(5,5,true);input.pointerEvent(5,5,false);check(input.isPointerPressed()&&input.isPointerReleased(),"Pointer tap keeps both edges");input.consume();check(!input.isPointerPressed(),"Pointer tap seen once");
  // Pads: any-pad queries, and a stick's radial dead zone.
  input.padEvent(PadButton.North,true);input.axisEvent(PadAxis.LeftX,.1);
  check(input.isPadDown(PadButton.North)&&input.getPad(0).getAxis(PadAxis.LeftX)==0&&input.getPadAxis(PadAxis.LeftX)==.1,"Dead zone");
  input.axisEvent(PadAxis.LeftX,1);check(Math.abs(input.getPad(0).getAxis(PadAxis.LeftX)-1)<1e-9,"Full reach past the dead zone");
  // Ticker: fixed steps, a pause, bounded catch-up, and input consumed per tick.
  var ticker=new Ticker(input,10),ticks=0;input.keyEvent(Key.A,true);input.keyEvent(Key.A,false);var seen=0;
  ticker.advance(.25,()->{ticks++;if(input.isPressed(Key.A))seen++;});check(ticks==2&&seen==1&&Math.abs(ticker.getFraction()-.5)<1e-9,"Ticks and fraction");
  ticker.setTimeScale(0);ticker.advance(1,()->ticks++);check(ticks==2,"Paused");
  ticker.setTimeScale(1);ticker.advance(.25,()->ticks++);ticker.advance(.25,()->ticks++);check(ticks==7,"Accumulates");
  Sys.println(haxe.Json.stringify({passed:true,checks:checks}));
 }
}
