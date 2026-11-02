package helix.platform.adapters.window.sdl3;

import haxe.io.Bytes;
import helix.platform.IWindow;
import helix.platform.Orientation;
import helix.platform.adapters.shared.ProgramName;
import helix.platform.adapters.shared.WindowAnswers;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;
import helix.platform.adapters.window.sdl3.internal.WindowBridge;

/** Provides `IWindow` on an SDL3 window, natively.

	The window opens with the adapter, before the graphics adapter that draws in it. A request answers at a later `Sdl3EventsAdapter`
	poll, as SDL reports the window's matching event, or fails after a second with none: SDL reports nothing when the window manager
	ignores a request. Moves are refused where the compositor places windows (Wayland, XWayland); orientation is a page's alone. A
	dropped file is read from its path, during the call. */
class Sdl3WindowAdapter implements IWindow {
	/** Opens the program's window.

		@param options  The graphics adapter it is for, its samples, and whether presenting waits for the display.
		@throws String  SDL or the window can't be had. */
	public function new(options:Sdl3WindowAdapterOptions) {
		Sdl3Bridge.nameApp(ProgramName.product());
		if (Sdl3Bridge.open(options.msaaSampleCount, options.graphics == Gl ? 1 : 0, options.vsync ? 1 : 0) != 1)
			throw "SDL3 can't open a window here (see the log)";
		WindowBridge.watch(1);
		title = "HeliX";
	}

	// How long a request is waited for, in seconds, before it fails: SDL reports nothing when the window manager ignores one. SDL's own
	// X11 sync waits as long, for a maximize, the slowest change it allows for.
	static inline final PATIENCE = 1.0;

	// Asks SDL, answering at a later events' poll: done once one of the window's events of the kinds given has come since, or the window
	// is already as reached says; failed with SDL's reason when it refused, or saying the window manager ignored it when neither has
	// come within PATIENCE.
	function ask(asking:Void->Int, kinds:Array<Int>, reached:Void->Bool, ignored:String, done:Null<Void->Void>, failed:Null<String->Void>):Bool {
		var counts = [for (kind in kinds) WindowBridge.eventCount(kind)];
		if (asking() == 0)
			return refuse((WindowBridge.error() : String), failed);
		var deadline = Sdl3Bridge.time() + PATIENCE;
		WindowAnswers.add(() -> {
			var come = false;
			for (i in 0...kinds.length)
				if (WindowBridge.eventCount(kinds[i]) != counts[i])
					come = true;
			if (come || reached()) {
				if (done != null)
					done();
				return true;
			}
			if (Sdl3Bridge.time() < deadline)
				return false;
			if (failed != null)
				failed(ignored);
			return true;
		});
		return true;
	}

	// Fails at the next events' poll, saying why; asked all the same.
	function refuse(reason:String, failed:Null<String->Void>):Bool {
		WindowAnswers.add(() -> {
			if (failed != null)
				failed(reason);
			return true;
		});
		return true;
	}

	// Why a fullscreen or maximized window refuses a size or a place, or null when it doesn't.
	function held():Null<String> {
		return fullscreen ? "the window is fullscreen" : maximized ? "the window is maximized" : null;
	}

	public var framebufferWidth(get, never):Int;

	function get_framebufferWidth():Int
		return Sdl3Bridge.framebufferWidth();

	public var framebufferHeight(get, never):Int;

	function get_framebufferHeight():Int
		return Sdl3Bridge.framebufferHeight();

	public var pixelRatio(get, never):Float;

	function get_pixelRatio():Float
		return WindowBridge.pixelRatio();

	public var focused(get, never):Bool;

	function get_focused():Bool
		return Sdl3Bridge.focused() != 0;

	@:isVar public var title(get, set):String;

	function get_title():String
		return title;

	function set_title(value:String):String {
		title = value;
		WindowBridge.setTitle(value);
		return value;
	}

	public var width(get, never):Int;

	function get_width():Int
		return WindowBridge.width();

	public var height(get, never):Int;

	function get_height():Int
		return WindowBridge.height();

	public function requestSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 1 || height < 1)
			return false;
		var reason = held();
		if (reason != null)
			return refuse(reason, failed);
		return ask(() -> WindowBridge.setSize(width, height), [WindowBridge.RESIZED], () -> this.width == width && this.height == height,
			"the window manager didn't resize the window", done, failed);
	}

	public function canMove():Bool
		return WindowBridge.canMove() != 0;

	public var x(get, never):Int;

	function get_x():Int
		return canMove() ? WindowBridge.x() : 0;

	public var y(get, never):Int;

	function get_y():Int
		return canMove() ? WindowBridge.y() : 0;

	public function requestPosition(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (!canMove())
			return refuse("the compositor places windows here", failed);
		var reason = held();
		if (reason != null)
			return refuse(reason, failed);
		return ask(() -> WindowBridge.setPosition(x, y), [WindowBridge.MOVED], () -> this.x == x && this.y == y, "the window manager didn't move the window",
			done, failed);
	}

	public function canFullscreen():Bool
		return true;

	public var fullscreen(get, never):Bool;

	function get_fullscreen():Bool
		return WindowBridge.fullscreen() != 0;

	// SDL applies fullscreen later on most window systems: done comes with its enter or leave event.
	public function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return ask(() -> WindowBridge.setFullscreen(enabled ? 1 : 0), [enabled ? WindowBridge.ENTER_FULLSCREEN : WindowBridge.LEAVE_FULLSCREEN],
			() -> fullscreen == enabled, enabled ? "the window manager didn't make the window fullscreen" : "the window manager didn't leave fullscreen",
			done, failed);

	public var orientation(get, never):Orientation;

	function get_orientation():Orientation
		return Any;

	public function requestOrientation(orientation:Orientation, ?done:Void->Void, ?failed:String->Void):Bool
		return false;

	public var visible(get, never):Bool;

	function get_visible():Bool
		return WindowBridge.visible() != 0;

	public function requestVisible(visible:Bool, ?done:Void->Void, ?failed:String->Void):Bool
		return ask(() -> WindowBridge.setVisible(visible ? 1 : 0), [visible ? WindowBridge.SHOWN : WindowBridge.HIDDEN], () -> this.visible == visible,
			visible ? "the window manager didn't show the window" : "the window manager didn't hide the window", done, failed);

	public var maximized(get, never):Bool;

	function get_maximized():Bool
		return WindowBridge.maximized() != 0;

	public function requestMaximized(maximized:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		if (maximized)
			return ask(() -> WindowBridge.setMaximized(1), [WindowBridge.MAXIMIZED], () -> this.maximized, "the window manager didn't maximize the window",
				done, failed);
		return ask(() -> WindowBridge.setMaximized(0), [WindowBridge.RESTORED], () -> !this.maximized && !minimized,
			"the window manager didn't restore the window", done, failed);
	}

	public var minimized(get, never):Bool;

	function get_minimized():Bool
		return WindowBridge.minimized() != 0;

	public function requestMinimized(minimized:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		if (minimized)
			return ask(() -> WindowBridge.setMinimized(1), [WindowBridge.MINIMIZED], () -> this.minimized, "the window manager didn't minimize the window",
				done, failed);
		return ask(() -> WindowBridge.setMinimized(0), [WindowBridge.RESTORED], () -> !this.minimized, "the window manager didn't restore the window", done,
			failed);
	}

	public function requestFocus(?done:Void->Void, ?failed:String->Void):Bool
		return ask(() -> WindowBridge.raise(), [WindowBridge.FOCUS_GAINED], () -> WindowBridge.hasFocus() != 0,
			"the window manager kept the keyboard in another window", done, failed);

	public function setIcon(width:Int, height:Int, pixels:Bytes):Void {
		if (width <= 0 || height <= 0 || pixels.length < width * height * 4)
			throw "The icon's size isn't positive or its pixels are fewer than it needs";
		WindowBridge.setIcon(width, height, cast cpp.Pointer.arrayElem(pixels.getData(), 0).raw);
	}

	public var opacity(get, never):Float;

	function get_opacity():Float
		return WindowBridge.opacity();

	// SDL applies opacity and the size limits during the call, and has no event for them: they answer at the next poll.
	public function requestOpacity(opacity:Float, ?done:Void->Void, ?failed:String->Void):Bool
		return ask(() -> WindowBridge.setOpacity(opacity), [], () -> true, "", done, failed);

	public function requestMinimumSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 0 || height < 0)
			return false;
		return ask(() -> WindowBridge.setMinimumSize(width, height), [], () -> true, "", done, failed);
	}

	public function requestMaximumSize(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (width < 0 || height < 0)
			return false;
		return ask(() -> WindowBridge.setMaximumSize(width, height), [], () -> true, "", done, failed);
	}

	public function getMonitorRefreshRate(monitorIndex:Int):Float
		return monitorIndex >= 0 && monitorIndex < monitorCount ? WindowBridge.displayRefreshRate(monitorIndex) : 0;

	public var monitorCount(get, never):Int;

	function get_monitorCount():Int
		return WindowBridge.displayCount();

	public var monitorIndex(get, never):Int;

	function get_monitorIndex():Int
		return WindowBridge.displayCurrent();

	public function requestMonitorIndex(monitorIndex:Int, ?done:Void->Void, ?failed:String->Void):Bool {
		if (monitorIndex < 0 || monitorIndex >= this.monitorCount)
			return false;
		if (monitorIndex == this.monitorIndex)
			return ask(() -> 1, [], () -> true, "", done, failed);
		if (!canMove())
			return refuse("the compositor places windows here", failed);
		return ask(() -> WindowBridge.setDisplay(monitorIndex), [WindowBridge.DISPLAY_CHANGED], () -> this.monitorIndex == monitorIndex,
			"the window manager didn't move the window to the monitor", done, failed);
	}

	function isMonitor(index:Int):Bool
		return index >= 0 && index < this.monitorCount;

	public function getMonitorName(monitorIndex:Int):String
		return isMonitor(monitorIndex) ? (WindowBridge.displayName(monitorIndex) : String) : "";

	public function getMonitorX(monitorIndex:Int):Int
		return isMonitor(monitorIndex) ? WindowBridge.displayX(monitorIndex) : 0;

	public function getMonitorY(monitorIndex:Int):Int
		return isMonitor(monitorIndex) ? WindowBridge.displayY(monitorIndex) : 0;

	public function getMonitorWidth(monitorIndex:Int):Int
		return isMonitor(monitorIndex) ? WindowBridge.displayWidth(monitorIndex) : 0;

	public function getMonitorHeight(monitorIndex:Int):Int
		return isMonitor(monitorIndex) ? WindowBridge.displayHeight(monitorIndex) : 0;

	public function readDroppedFile(fileIndex:Int, maxBytes:Int, read:(name:String, bytes:Bytes) -> Void, failed:String->Void):Void {
		if (fileIndex < 0 || fileIndex >= Sdl3Bridge.droppedCount()) {
			failed('No dropped file $fileIndex');
			return;
		}
		var path = (Sdl3Bridge.droppedPath(fileIndex) : String);
		var bytes = try {
			if (sys.FileSystem.stat(path).size > maxBytes) {
				failed("File exceeds byte limit");
				return;
			}
			sys.io.File.getBytes(path);
		} catch (error:Dynamic) {
			failed(Std.string(error));
			return;
		}
		read(haxe.io.Path.withoutDirectory(path), bytes);
	}

	public function canClose():Bool
		return true;

	public function close():Void {
		if (Sdl3Bridge.isOpen() == 0)
			return;
		if (onClose != null)
			onClose();
		WindowBridge.watch(0);
		Sdl3Bridge.close();
	}

	public var onClose:Null<Void->Void>;
}
