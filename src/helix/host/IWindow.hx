package helix.host;

/** The window the app draws in: title, size, place, fullscreen, visibility and the monitors, in logical pixels.
	Names follow docs/CONVENTIONS.md: every set has a get (is for a bool); can says whether to offer an action at all;
	request asks for what the platform may refuse or grant later, returning whether it asked, never whether it was granted.
	A setter that can't act here refuses, returning false: the web can't move or size its window, and under XWayland the compositor places windows. */
interface IWindow {
	/** The drawable area's width in framebuffer pixels (the getWidth and getHeight sizes are logical pixels). */
	function getFramebufferWidth():Int;

	/** The drawable area's height in framebuffer pixels. */
	function getFramebufferHeight():Int;

	/** Framebuffer pixels per logical pixel. */
	function getPixelRatio():Float;

	/** Whether the window has the keyboard and is shown: false while it's in the background, minimized, or (on the web) the page is hidden. */
	function isFocused():Bool;

	/** The title bar's text (the document's title, on the web). */
	function getTitle():String;

	/** Sets the title bar's text (the document's title, on the web). */
	function setTitle(title:String):Void;

	/** The window's inner width in logical pixels (the viewport's, on the web). */
	function getWidth():Int;

	/** The window's inner height in logical pixels (the viewport's, on the web). */
	function getHeight():Int;

	/** Asks for an inner size in logical pixels; getWidth and getHeight answer on a later frame, with what the window manager gave (it may
		give another size, or none). False, asking nothing, where a program can't size its window (the web), or for a size under 1. */
	function requestSize(width:Int, height:Int):Bool;

	/** Whether requestPosition and requestMonitorIndex can ask: not on the web, nor where the compositor places windows (XWayland). */
	function canMove():Bool;

	/** The window's left edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's. */
	function getX():Int;

	/** The window's top edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's. */
	function getY():Int;

	/** Asks for the window's left and top edges on the desktop in logical pixels; getX and getY answer on a later frame, with what the
		window manager gave. False, asking nothing, where the window can't move (canMove). */
	function requestPosition(x:Int, y:Int):Bool;

	/** Whether requestFullscreen can ask: always natively; on the web, where the page may go fullscreen. */
	function canFullscreen():Bool;

	/** Whether the window is fullscreen now (the canvas, on the web). */
	function isFullscreen():Bool;

	/** Asks for fullscreen or a window; isFullscreen answers on a later frame. False where it can't ask (canFullscreen). On the web the browser
		grants it only soon after a key press or click. */
	function requestFullscreen(enabled:Bool):Bool;

	/** Whether the window is shown (the canvas, on the web). */
	function isVisible():Bool;

	/** Asks to show or hide the window (the canvas, on the web); isVisible answers on a later frame (natively, once the window manager has
		shown it). Always asks: true. */
	function requestVisible(visible:Bool):Bool;

	/** How many monitors there are, at least 1; the web sees one screen. */
	function getMonitorCount():Int;

	/** The monitor holding the window. */
	function getMonitorIndex():Int;

	/** Asks for the window on monitor index; getMonitorIndex answers on a later frame. False, asking nothing, for an index out of range, or where
		the window can't move (canMove). */
	function requestMonitorIndex(index:Int):Bool;

	/** "" for an index out of range, as the other monitor getters answer 0. */
	function getMonitorName(index:Int):String;

	/** The monitor's left edge on the desktop in logical pixels; 0 for an index out of range, and on the web. */
	function getMonitorX(index:Int):Int;

	/** The monitor's top edge on the desktop in logical pixels; 0 for an index out of range, and on the web. */
	function getMonitorY(index:Int):Int;

	/** The monitor's width in logical pixels; 0 for an index out of range. */
	function getMonitorWidth(index:Int):Int;

	/** The monitor's height in logical pixels; 0 for an index out of range. */
	function getMonitorHeight(index:Int):Int;
}
