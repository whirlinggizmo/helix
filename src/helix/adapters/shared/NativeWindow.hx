package helix.adapters.shared;

import helix.host.IWindow;

/** The desktop window of either native host (sokol_app's or SDL's), through the C each implements (window.h). Moves are refused where the
	compositor places windows (Wayland, XWayland). */
class NativeWindow implements IWindow {
	var title = "HeliX Haxe";

	/** The program's one native window. */
	public function new() {}

	public function getFramebufferWidth():Int
		return WindowBridge.width();

	public function getFramebufferHeight():Int
		return WindowBridge.height();

	public function getPixelRatio():Float
		return WindowBridge.pixelRatio();

	public function isFocused():Bool
		return WindowBridge.focused() != 0;

	public function getTitle():String
		return title;

	public function setTitle(value:String):Void {
		title = value;
		WindowBridge.setTitle(value);
	}

	public function getWidth():Int
		return WindowBridge.windowWidth();

	public function getHeight():Int
		return WindowBridge.windowHeight();

	public function requestSize(width:Int, height:Int):Bool {
		if (width < 1 || height < 1)
			return false;
		WindowBridge.setSize(width, height);
		return true;
	}

	public function canMove():Bool
		return WindowBridge.canMove() != 0;

	public function getX():Int
		return canMove() ? WindowBridge.windowX() : 0;

	public function getY():Int
		return canMove() ? WindowBridge.windowY() : 0;

	public function requestPosition(x:Int, y:Int):Bool {
		if (!canMove())
			return false;
		WindowBridge.setPosition(x, y);
		return true;
	}

	public function canFullscreen():Bool
		return true;

	public function isFullscreen():Bool
		return WindowBridge.fullscreen() != 0;

	public function requestFullscreen(enabled:Bool):Bool {
		WindowBridge.requestFullscreen(enabled ? 1 : 0);
		return true;
	}

	public function isVisible():Bool
		return WindowBridge.visible() != 0;

	public function requestVisible(visible:Bool):Bool {
		WindowBridge.setVisible(visible ? 1 : 0);
		return true;
	}

	public function getMonitorCount():Int
		return WindowBridge.displayCount();

	public function getMonitorIndex():Int
		return WindowBridge.displayCurrent();

	public function requestMonitorIndex(index:Int):Bool {
		if (index < 0 || index >= getMonitorCount() || !canMove())
			return false;
		WindowBridge.setDisplay(index);
		return true;
	}

	function valid(index:Int):Bool
		return index >= 0 && index < getMonitorCount();

	public function getMonitorName(index:Int):String
		return valid(index) ? (WindowBridge.displayName(index) : String) : "";

	public function getMonitorX(index:Int):Int
		return valid(index) ? WindowBridge.displayX(index) : 0;

	public function getMonitorY(index:Int):Int
		return valid(index) ? WindowBridge.displayY(index) : 0;

	public function getMonitorWidth(index:Int):Int
		return valid(index) ? WindowBridge.displayWidth(index) : 0;

	public function getMonitorHeight(index:Int):Int
		return valid(index) ? WindowBridge.displayHeight(index) : 0;
}
