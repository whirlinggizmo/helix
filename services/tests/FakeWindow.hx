import helix.platform.IWindow;
import helix.platform.Orientation;

/** A window whose state a test sets: 800 by 600 logical pixels at a pixel ratio of 1 until changed. Requests for size, place and
	fullscreen are counted and granted at once, as a window manager would on a later frame. */
class FakeWindow implements IWindow {
	/** Gets or sets the logical size. */
	public var logicalWidth = 800;

	public var logicalHeight = 600;

	/** Gets or sets the framebuffer pixels per logical pixel. */
	public var ratio = 1.;

	/** Gets or sets the place on the desktop. */
	public var left = 0;

	public var top = 0;

	/** Gets or sets whether it is fullscreen. */
	public var full = false;

	/** Gets the requests made: size, position and fullscreen, as text. */
	public final requests:Array<String> = [];

	/** Creates one. */
	public function new() {}

	public var framebufferWidth(get, never):Int;

	function get_framebufferWidth():Int
		return Math.round(logicalWidth * ratio);

	public var framebufferHeight(get, never):Int;

	function get_framebufferHeight():Int
		return Math.round(logicalHeight * ratio);

	public var pixelRatio(get, never):Float;

	function get_pixelRatio():Float
		return ratio;

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
		return logicalWidth;

	public var height(get, never):Int;

	function get_height():Int
		return logicalHeight;

	public function requestSize(width:Int, height:Int):Bool {
		requests.push('size $width $height');
		logicalWidth = width;
		logicalHeight = height;
		return true;
	}

	public function canMove():Bool
		return true;

	public var x(get, never):Int;

	function get_x():Int
		return left;

	public var y(get, never):Int;

	function get_y():Int
		return top;

	public function requestPosition(x:Int, y:Int):Bool {
		requests.push('position $x $y');
		left = x;
		top = y;
		return true;
	}

	public function canFullscreen():Bool
		return true;

	public var fullscreen(get, never):Bool;

	function get_fullscreen():Bool
		return full;

	public function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		requests.push('fullscreen $enabled');
		full = enabled;
		if (done != null)
			done();
		return true;
	}

	public var orientation(get, never):Orientation;

	function get_orientation():Orientation
		return Any;

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
		return 1920;

	public function getMonitorHeight(index:Int):Int
		return 1080;

	public function canClose():Bool
		return false;

	public function close():Void {}

	public var onClose:Null<Void->Void> = null;
}
