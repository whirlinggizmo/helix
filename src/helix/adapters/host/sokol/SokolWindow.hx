package helix.adapters.host.sokol;

import helix.adapters.host.sokol.internal.HostBridge;
import helix.host.IWindow;

/** The desktop window through sokol_app and sokol_app_utils (X11, Win32, macOS). Moves are refused where the compositor places windows (XWayland). */
class SokolWindow implements IWindow {
	var title = "HeliX Haxe";

	/** The program's one sokol_app window. */
	public function new() {}

	public function getFramebufferWidth():Int
		return HostBridge.width();

	public function getFramebufferHeight():Int
		return HostBridge.height();

	public function getPixelRatio():Float
		return HostBridge.pixelRatio();

	public function isFocused():Bool
		return HostBridge.focused() != 0;

	public function getTitle():String
		return title;

	public function setTitle(value:String):Void {
		title = value;
		HostBridge.setTitle(value);
	}

	public function getWidth():Int
		return HostBridge.windowWidth();

	public function getHeight():Int
		return HostBridge.windowHeight();

	public function requestSize(width:Int, height:Int):Bool {
		if (width < 1 || height < 1)
			return false;
		HostBridge.setSize(width, height);
		return true;
	}

	public function canMove():Bool
		return HostBridge.canMove() != 0;

	public function getX():Int
		return canMove() ? HostBridge.windowX() : 0;

	public function getY():Int
		return canMove() ? HostBridge.windowY() : 0;

	public function requestPosition(x:Int, y:Int):Bool {
		if (!canMove())
			return false;
		HostBridge.setPosition(x, y);
		return true;
	}

	public function canFullscreen():Bool
		return true;

	public function isFullscreen():Bool
		return HostBridge.fullscreen() != 0;

	public function requestFullscreen(enabled:Bool):Bool {
		HostBridge.requestFullscreen(enabled ? 1 : 0);
		return true;
	}

	public function isVisible():Bool
		return HostBridge.visible() != 0;

	public function requestVisible(visible:Bool):Bool {
		HostBridge.setVisible(visible ? 1 : 0);
		return true;
	}

	public function getMonitorCount():Int
		return HostBridge.displayCount();

	public function getMonitorIndex():Int
		return HostBridge.displayCurrent();

	public function requestMonitorIndex(index:Int):Bool {
		if (index < 0 || index >= getMonitorCount() || !canMove())
			return false;
		HostBridge.setDisplay(index);
		return true;
	}

	function valid(index:Int):Bool
		return index >= 0 && index < getMonitorCount();

	public function getMonitorName(index:Int):String
		return valid(index) ? (HostBridge.displayName(index) : String) : "";

	public function getMonitorX(index:Int):Int
		return valid(index) ? HostBridge.displayX(index) : 0;

	public function getMonitorY(index:Int):Int
		return valid(index) ? HostBridge.displayY(index) : 0;

	public function getMonitorWidth(index:Int):Int
		return valid(index) ? HostBridge.displayWidth(index) : 0;

	public function getMonitorHeight(index:Int):Int
		return valid(index) ? HostBridge.displayHeight(index) : 0;
}
