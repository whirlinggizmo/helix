package helix.adapters.host.dom;
import helix.host.IWindow;
import js.Browser;
import js.html.CanvasElement;
/** The page is the window: its title is the document's, its size the viewport's, and fullscreen is the canvas's. A page can't move or size its window, or choose a monitor. */
class DomWindow implements IWindow {
 var canvas:CanvasElement;
 public function new(canvas:CanvasElement)this.canvas=canvas;
 public function setTitle(title:String):Void Browser.document.title=title;
 public function width():Int return Browser.window.innerWidth;
 public function height():Int return Browser.window.innerHeight;
 public function setSize(width:Int,height:Int):Bool return false;
 public function x():Int return Browser.window.screenX;
 public function y():Int return Browser.window.screenY;
 public function setPosition(x:Int,y:Int):Bool return false;
 public function canFullscreen():Bool return Browser.document.fullscreenEnabled;
 public function fullscreen():Bool return Browser.document.fullscreenElement!=null;
 public function setFullscreen(enabled:Bool):Void {
  // Allowed only soon after a key press or click: a refusal leaves the page as it was.
  if(enabled&&!fullscreen())canvas.requestFullscreen().catchError(_->null);else if(!enabled&&fullscreen())Browser.document.exitFullscreen().catchError(_->null);
 }
 public function visible():Bool return canvas.style.visibility!="hidden";
 public function setVisible(visible:Bool):Bool {canvas.style.visibility=visible?"":"hidden";return true;}
 public function monitorCount():Int return 1;
 public function monitor():Int return 0;
 public function setMonitor(index:Int):Bool return false;
 public function monitorInfo(index:Int):MonitorInfo {
  var screen=Browser.window.screen;return index==0?{name:"screen",x:0,y:0,width:screen.width,height:screen.height}:{name:"",x:0,y:0,width:0,height:0};
 }
}
