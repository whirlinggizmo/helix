package helix.adapters.host.dom;

import helix.host.IWindow;
import js.Browser;
import js.html.CanvasElement;

/** The page is the window: its title is the document's, its size the viewport's, and fullscreen is the canvas's. A page can't move or size its window,
	or choose a monitor; it sees one screen. */
class DomWindow implements IWindow {
	var canvas:CanvasElement;
	var focused = true;

	/** The page's window, with canvas as what goes fullscreen or hides, and as the drawing surface: its pixels follow the viewport's size and
		the pixel ratio. */
	public function new(canvas:CanvasElement) {
		this.canvas = canvas;
		resize();
		Browser.window.addEventListener("resize", _ -> resize());
		Browser.window.addEventListener("blur", _ -> focused = false);
		Browser.window.addEventListener("focus", _ -> focused = !Browser.document.hidden);
		Browser.document.addEventListener("visibilitychange", _ -> focused = !Browser.document.hidden);
	}

	function resize():Void {
		canvas.width = Std.int(Math.max(1, Browser.window.innerWidth * getPixelRatio()));
		canvas.height = Std.int(Math.max(1, Browser.window.innerHeight * getPixelRatio()));
	}

	public function getFramebufferWidth():Int
		return canvas.width;

	public function getFramebufferHeight():Int
		return canvas.height;

	public function getPixelRatio():Float
		return Browser.window.devicePixelRatio;

	public function isFocused():Bool
		return focused;

	public function getTitle():String
		return Browser.document.title;

	public function setTitle(title:String):Void
		Browser.document.title = title;

	public function getWidth():Int
		return Browser.window.innerWidth;

	public function getHeight():Int
		return Browser.window.innerHeight;

	public function requestSize(width:Int, height:Int):Bool
		return false;

	public function canMove():Bool
		return false;

	public function getX():Int
		return Browser.window.screenX;

	public function getY():Int
		return Browser.window.screenY;

	public function requestPosition(x:Int, y:Int):Bool
		return false;

	public function canFullscreen():Bool
		return Browser.document.fullscreenEnabled;

	public function isFullscreen():Bool
		return Browser.document.fullscreenElement != null;

	public function requestFullscreen(enabled:Bool):Bool {
		if (!canFullscreen())
			return false;
		// The browser may refuse (no recent key press or click): the page stays as it was, and isFullscreen says so.
		if (enabled && !isFullscreen())
			canvas.requestFullscreen().catchError(_ -> null);
		else if (!enabled && isFullscreen())
			Browser.document.exitFullscreen().catchError(_ -> null);
		return true;
	}

	public function isVisible():Bool
		return canvas.style.visibility != "hidden";

	public function requestVisible(visible:Bool):Bool {
		canvas.style.visibility = visible ? "" : "hidden";
		return true;
	}

	public function getMonitorCount():Int
		return 1;

	public function getMonitorIndex():Int
		return 0;

	public function requestMonitorIndex(index:Int):Bool
		return false;

	public function getMonitorName(index:Int):String
		return index == 0 ? "screen" : "";

	public function getMonitorX(index:Int):Int
		return 0;

	public function getMonitorY(index:Int):Int
		return 0;

	public function getMonitorWidth(index:Int):Int
		return index == 0 ? Browser.window.screen.width : 0;

	public function getMonitorHeight(index:Int):Int
		return index == 0 ? Browser.window.screen.height : 0;
}
