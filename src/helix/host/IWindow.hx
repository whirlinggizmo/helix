package helix.host;

typedef MonitorInfo = {var name:String;var x:Int;var y:Int;var width:Int;var height:Int;}

/** The window the app draws in: title, size, place, fullscreen, visibility and the monitors, in logical pixels.
    A change a platform can't make returns false: the web can't move or size its window, and under XWayland the compositor places windows. */
interface IWindow {
 function setTitle(title:String):Void;
 function width():Int;
 function height():Int;
 function setSize(width:Int,height:Int):Bool;
 function x():Int;
 function y():Int;
 function setPosition(x:Int,y:Int):Bool;
 function canFullscreen():Bool;
 function fullscreen():Bool;
 /** On the web the browser allows this only soon after a key press or click. */
 function setFullscreen(enabled:Bool):Void;
 function visible():Bool;
 function setVisible(visible:Bool):Bool;
 function monitorCount():Int;
 /** The monitor holding the window. */
 function monitor():Int;
 function setMonitor(index:Int):Bool;
 function monitorInfo(index:Int):MonitorInfo;
}
