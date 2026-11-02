import haxe.io.Bytes;
import helix.platform.IWindow;
import helix.platform.Orientation;

/** A window whose state a test sets: 800 by 600 logical pixels at a pixel ratio of 1 until changed. Requests for size, place and
	fullscreen are counted and granted at once, and the others' state set, their `done` called at the next `answer`, as a window manager
	would answer at a later poll; a request named in `refusing` fails there instead, with its name. */
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

	/** Gets the requests that fail, by name: "size", "position", "fullscreen", "visible", "monitor", "maximized", "minimized", "focus",
		"opacity", "minimumSize" or "maximumSize". */
	public final refusing:Array<String> = [];

	// The answers due at the next answer().
	var due:Array<Void->Void> = [];

	/** Answers the requests made since the last call, as an `IEvents.poll` would. */
	public function answer():Void {
		var now = due;
		due = [];
		for (f in now)
			f();
	}

	// Leaves the request's answer for the next answer(): done, or failed with its name where refusing names it.
	function later(name:String, grant:Void->Void, done:Null<Void->Void>, failed:Null<String->Void>):Bool {
		var refused = refusing.indexOf(name) >= 0;
		if (!refused)
			grant();
		due.push(() -> if (refused) {
			if (failed != null)
				failed('$name refused');
		} else if (done != null) done());
		return true;
	}

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

	public function requestSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 1 || height < 1)
			return false;
		requests.push('size $width $height');
		return later("size", () -> {
			logicalWidth = width;
			logicalHeight = height;
		}, done, failed);
	}

	public function canMove():Bool
		return true;

	public var x(get, never):Int;

	function get_x():Int
		return left;

	public var y(get, never):Int;

	function get_y():Int
		return top;

	public function requestPosition(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		requests.push('position $x $y');
		return later("position", () -> {
			left = x;
			top = y;
		}, done, failed);
	}

	public function canFullscreen():Bool
		return true;

	public var fullscreen(get, never):Bool;

	function get_fullscreen():Bool
		return full;

	public function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		requests.push('fullscreen $enabled');
		return later("fullscreen", () -> full = enabled, done, failed);
	}

	public var orientation(get, never):Orientation;

	function get_orientation():Orientation
		return Any;

	public function requestOrientation(orientation:Orientation, ?done:Void->Void, ?failed:String->Void):Bool
		return false;

	public var visible(get, never):Bool;

	var shown = true;

	function get_visible():Bool
		return shown;

	public function requestVisible(visible:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return later("visible", () -> shown = visible, done, failed);

	public var monitorCount(get, never):Int;

	function get_monitorCount():Int
		return 2;

	public var monitorIndex(get, never):Int;

	var monitor = 0;

	function get_monitorIndex():Int
		return monitor;

	public function requestMonitorIndex(monitorIndex:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (monitorIndex < 0 || monitorIndex >= monitorCount)
			return false;
		return later("monitor", () -> monitor = monitorIndex, done, failed);
	}

	public function getMonitorName(monitorIndex:Int):String
		return "";

	public function getMonitorX(monitorIndex:Int):Int
		return 0;

	public function getMonitorY(monitorIndex:Int):Int
		return 0;

	public function getMonitorWidth(monitorIndex:Int):Int
		return 1920;

	public function getMonitorHeight(monitorIndex:Int):Int
		return 1080;

	public function getMonitorRefreshRate(monitorIndex:Int):Float
		return 60;

	public var maximized(get, never):Bool;

	var large = false;

	function get_maximized():Bool
		return large;

	public function requestMaximized(maximized:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return later("maximized", () -> {
			large = maximized;
			if (!maximized)
				small = false;
		}, done, failed);

	public var minimized(get, never):Bool;

	var small = false;

	function get_minimized():Bool
		return small;

	public function requestMinimized(minimized:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return later("minimized", () -> small = minimized, done, failed);

	public function requestFocus(?done:Void->Void, ?failed:String->Void):Bool
		return later("focus", () -> {}, done, failed);

	public function setIcon(width:Int, height:Int, pixels:Bytes):Void {}

	public var opacity(get, never):Float;

	var faded = 1.;

	function get_opacity():Float
		return faded;

	public function requestOpacity(opacity:Float, ?done:Void->Void, ?failed:String->Void):Bool
		return later("opacity", () -> faded = opacity, done, failed);

	/** Gets the size limits last granted, as text: "minimum w h" and "maximum w h". */
	public final limits:Array<String> = [];

	public function requestMinimumSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 0 || height < 0)
			return false;
		return later("minimumSize", () -> limits.push('minimum $width $height'), done, failed);
	}

	public function requestMaximumSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 0 || height < 0)
			return false;
		return later("maximumSize", () -> limits.push('maximum $width $height'), done, failed);
	}

	/** Gets the files dropped, as name and bytes, which `readDroppedFile` reads by index. */
	public final dropped:Array<{name:String, bytes:Bytes}> = [];

	public function readDroppedFile(fileIndex:Int, maxBytes:Int, read:(name:String, bytes:Bytes) -> Void, failed:String->Void):Void {
		var file = dropped[fileIndex];
		if (fileIndex < 0 || file == null)
			failed('No dropped file $fileIndex');
		else if (file.bytes.length > maxBytes)
			failed("too large");
		else
			read(file.name, file.bytes);
	}

	public function canClose():Bool
		return false;

	public function close():Void {}

	public var onClose:Null<Void->Void> = null;
}
