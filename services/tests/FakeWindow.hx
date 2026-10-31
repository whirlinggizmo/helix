import helix.platform.IWindow;
import helix.platform.Orientation;

/** A window that is only its size: 800 by 600 framebuffer pixels, which nothing changes. */
class FakeWindow implements IWindow {
	/** Creates one. */
	public function new() {}

	public var framebufferWidth(get, never):Int;

	function get_framebufferWidth():Int
		return 800;

	public var framebufferHeight(get, never):Int;

	function get_framebufferHeight():Int
		return 600;

	public var pixelRatio(get, never):Float;

	function get_pixelRatio():Float
		return 1;

	public var focused(get, never):Bool;

	function get_focused():Bool
		return true;

	public var title(get, set):String;

	var named = "";

	function get_title():String
		return named;

	function set_title(value:String):String
		return named = value;

	public var width(get, never):Int;

	function get_width():Int
		return 800;

	public var height(get, never):Int;

	function get_height():Int
		return 600;

	public function requestSize(width:Int, height:Int):Bool
		return false;

	public function canMove():Bool
		return false;

	public var x(get, never):Int;

	function get_x():Int
		return 0;

	public var y(get, never):Int;

	function get_y():Int
		return 0;

	public function requestPosition(x:Int, y:Int):Bool
		return false;

	public function canFullscreen():Bool
		return false;

	public var fullscreen(get, never):Bool;

	function get_fullscreen():Bool
		return false;

	public function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return false;

	public function requestOrientation(orientation:Orientation, ?done:Void->Void, ?failed:String->Void):Bool
		return false;

	public var visible(get, never):Bool;

	function get_visible():Bool
		return true;

	public function requestVisible(visible:Bool):Bool
		return false;

	public var monitorCount(get, never):Int;

	function get_monitorCount():Int
		return 1;

	public var monitorIndex(get, never):Int;

	function get_monitorIndex():Int
		return 0;

	public function requestMonitorIndex(index:Int):Bool
		return false;

	public function getMonitorName(index:Int):String
		return "";

	public function getMonitorX(index:Int):Int
		return 0;

	public function getMonitorY(index:Int):Int
		return 0;

	public function getMonitorWidth(index:Int):Int
		return 800;

	public function getMonitorHeight(index:Int):Int
		return 600;

	public function canClose():Bool
		return false;

	public function close():Void {}

	public var onClose:Null<Void->Void> = null;
}
