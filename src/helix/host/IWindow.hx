package helix.host;

/** The window the app draws in: title, size, place, fullscreen, visibility and the monitors, in logical pixels.
    Names follow libwgf's conventions: every set has a get (is for a bool); can says whether to offer an action at all;
    request asks for what the platform may refuse or grant later, returning whether it asked, never whether it was granted.
    A setter that can't act here refuses, returning false: the web can't move or size its window, and under XWayland the compositor places windows. */
interface IWindow {
 function getTitle():String;
 function setTitle(title:String):Void;
 function getWidth():Int;
 function getHeight():Int;
 /** False where a program can't size its window (the web), or for a size under 1. */
 function setSize(width:Int,height:Int):Bool;
 /** Whether setPosition and setMonitor can work: not on the web, nor where the compositor places windows (XWayland). */
 function canMove():Bool;
 function getX():Int;
 function getY():Int;
 /** False where the window can't move (canMove). */
 function setPosition(x:Int,y:Int):Bool;
 function canFullscreen():Bool;
 function isFullscreen():Bool;
 /** Asks for fullscreen or a window; isFullscreen answers on a later frame. False where it can't ask (canFullscreen). On the web the browser
     grants it only soon after a key press or click. */
 function requestFullscreen(enabled:Bool):Bool;
 function isVisible():Bool;
 function setVisible(visible:Bool):Bool;
 function getMonitorCount():Int;
 /** The monitor holding the window. */
 function getMonitor():Int;
 /** False for an index out of range, or where the window can't move (canMove). */
 function setMonitor(index:Int):Bool;
 /** "" for an index out of range, as the other monitor getters answer 0. */
 function getMonitorName(index:Int):String;
 function getMonitorX(index:Int):Int;
 function getMonitorY(index:Int):Int;
 function getMonitorWidth(index:Int):Int;
 function getMonitorHeight(index:Int):Int;
}
