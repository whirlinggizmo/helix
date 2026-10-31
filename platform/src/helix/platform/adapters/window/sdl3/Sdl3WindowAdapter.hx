package helix.platform.adapters.window.sdl3;

import haxe.io.Bytes;
import helix.platform.IWindow;
import helix.platform.Orientation;
import helix.platform.adapters.shared.ProgramName;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;
import helix.platform.adapters.window.sdl3.internal.WindowBridge;

/** Provides `IWindow` on an SDL3 window, natively.

	The window opens with the adapter, before the graphics adapter that draws in it. Moves are refused where the compositor places windows
	(Wayland, XWayland); orientation is a page's alone. */
class Sdl3WindowAdapter implements IWindow {
	/** Opens the program's window.

		@param options  The graphics adapter it is for, its samples, and whether presenting waits for the display.
		@throws String  SDL or the window can't be had. */
	public function new(options:Sdl3WindowAdapterOptions) {
		Sdl3Bridge.nameApp(ProgramName.product());
		if (Sdl3Bridge.open(options.msaaSamples, options.graphics == Gl ? 1 : 0, options.vsync ? 1 : 0) != 1)
			throw "SDL3 can't open a window here (see the log)";
		title = "HeliX";
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

	public function requestSize(width:Int, height:Int):Bool {
		if (width < 1 || height < 1)
			return false;
		WindowBridge.setSize(width, height);
		return true;
	}

	public function canMove():Bool
		return WindowBridge.canMove() != 0;

	public var x(get, never):Int;

	function get_x():Int
		return canMove() ? WindowBridge.x() : 0;

	public var y(get, never):Int;

	function get_y():Int
		return canMove() ? WindowBridge.y() : 0;

	public function requestPosition(x:Int, y:Int):Bool {
		if (!canMove())
			return false;
		WindowBridge.setPosition(x, y);
		return true;
	}

	public function canFullscreen():Bool
		return true;

	public var fullscreen(get, never):Bool;

	function get_fullscreen():Bool
		return WindowBridge.fullscreen() != 0;

	public function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		WindowBridge.setFullscreen(enabled ? 1 : 0);
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
		return WindowBridge.visible() != 0;

	public function requestVisible(visible:Bool):Bool {
		WindowBridge.setVisible(visible ? 1 : 0);
		return true;
	}

	public var maximized(get, never):Bool;

	function get_maximized():Bool
		return WindowBridge.maximized() != 0;

	public function requestMaximized(maximized:Bool):Bool {
		WindowBridge.setMaximized(maximized ? 1 : 0);
		return true;
	}

	public var minimized(get, never):Bool;

	function get_minimized():Bool
		return WindowBridge.minimized() != 0;

	public function requestMinimized(minimized:Bool):Bool {
		WindowBridge.setMinimized(minimized ? 1 : 0);
		return true;
	}

	public function requestFocus():Bool {
		WindowBridge.raise();
		return true;
	}

	public function setIcon(width:Int, height:Int, pixels:Bytes):Void {
		if (width <= 0 || height <= 0 || pixels.length < width * height * 4)
			throw "The icon's size isn't positive or its pixels are fewer than it needs";
		WindowBridge.setIcon(width, height, cast cpp.Pointer.arrayElem(pixels.getData(), 0).raw);
	}

	public var opacity(get, never):Float;

	function get_opacity():Float
		return WindowBridge.opacity();

	public function requestOpacity(opacity:Float):Bool
		return WindowBridge.setOpacity(opacity) != 0;

	public function requestMinimumSize(width:Int, height:Int):Bool
		return WindowBridge.setMinimumSize(width, height) != 0;

	public function requestMaximumSize(width:Int, height:Int):Bool
		return WindowBridge.setMaximumSize(width, height) != 0;

	public function getMonitorRefreshRate(index:Int):Float
		return index >= 0 && index < monitorCount ? WindowBridge.displayRefreshRate(index) : 0;

	public var monitorCount(get, never):Int;

	function get_monitorCount():Int
		return WindowBridge.displayCount();

	public var monitorIndex(get, never):Int;

	function get_monitorIndex():Int
		return WindowBridge.displayCurrent();

	public function requestMonitorIndex(index:Int):Bool {
		if (index < 0 || index >= this.monitorCount || !canMove())
			return false;
		WindowBridge.setDisplay(index);
		return true;
	}

	function isMonitor(index:Int):Bool
		return index >= 0 && index < this.monitorCount;

	public function getMonitorName(index:Int):String
		return isMonitor(index) ? (WindowBridge.displayName(index) : String) : "";

	public function getMonitorX(index:Int):Int
		return isMonitor(index) ? WindowBridge.displayX(index) : 0;

	public function getMonitorY(index:Int):Int
		return isMonitor(index) ? WindowBridge.displayY(index) : 0;

	public function getMonitorWidth(index:Int):Int
		return isMonitor(index) ? WindowBridge.displayWidth(index) : 0;

	public function getMonitorHeight(index:Int):Int
		return isMonitor(index) ? WindowBridge.displayHeight(index) : 0;

	public function canClose():Bool
		return true;

	public function close():Void {
		if (Sdl3Bridge.isOpen() == 0)
			return;
		if (onClose != null)
			onClose();
		Sdl3Bridge.close();
	}

	public var onClose:Null<Void->Void>;
}
