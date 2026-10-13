package helix.adapters.host.sokol;
import helix.adapters.host.sokol.internal.HostBridge;
import helix.host.IWindow;
/** The desktop window through sokol_app and sokol_app_utils (X11, Win32, macOS). Moves are refused where the compositor places windows (XWayland). */
class SokolWindow implements IWindow {
 public function new(){}
 public function setTitle(title:String):Void HostBridge.setTitle(title);
 public function width():Int return HostBridge.windowWidth();
 public function height():Int return HostBridge.windowHeight();
 public function setSize(width:Int,height:Int):Bool {if(width<1||height<1)return false;HostBridge.setSize(width,height);return true;}
 public function x():Int return HostBridge.canMove()!=0?HostBridge.windowX():0;
 public function y():Int return HostBridge.canMove()!=0?HostBridge.windowY():0;
 public function setPosition(x:Int,y:Int):Bool {if(HostBridge.canMove()==0)return false;HostBridge.setPosition(x,y);return true;}
 public function canFullscreen():Bool return true;
 public function fullscreen():Bool return HostBridge.fullscreen()!=0;
 public function setFullscreen(enabled:Bool):Void HostBridge.setFullscreen(enabled?1:0);
 public function visible():Bool return HostBridge.visible()!=0;
 public function setVisible(visible:Bool):Bool {HostBridge.setVisible(visible?1:0);return true;}
 public function monitorCount():Int return HostBridge.displayCount();
 public function monitor():Int return HostBridge.displayCurrent();
 public function setMonitor(index:Int):Bool {if(index<0||index>=monitorCount()||HostBridge.canMove()==0)return false;HostBridge.setDisplay(index);return true;}
 public function monitorInfo(index:Int):MonitorInfo {
  if(index<0||index>=monitorCount())return {name:"",x:0,y:0,width:0,height:0};
  return {name:(HostBridge.displayName(index):String),x:HostBridge.displayX(index),y:HostBridge.displayY(index),width:HostBridge.displayWidth(index),height:HostBridge.displayHeight(index)};
 }
}
