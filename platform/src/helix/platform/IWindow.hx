package helix.platform;

/** Defines the window a program draws in: its title, size, position, fullscreen, visibility and monitors.

	In a page the window is the page: its title is the document's, its size the viewport's, and fullscreen and visibility are the canvas's.
	Sizes are logical pixels unless named framebuffer pixels. A request asks for what the platform may refuse or grant later: it returns
	whether it asked, and the matching property answers on a later frame. A `can` method says whether to offer the request at all.

	The window reports nothing by itself: what happens to it (resized, focused, minimized, a close asked for) arrives as events from
	`IEvents.poll`. */
interface IWindow {
	/** Gets the drawable area's width, in framebuffer pixels. */
	var framebufferWidth(get, never):Int;

	/** Gets the drawable area's height, in framebuffer pixels. */
	var framebufferHeight(get, never):Int;

	/** Gets the number of framebuffer pixels per logical pixel. */
	var pixelRatio(get, never):Float;

	/** Gets a value indicating whether the window has the keyboard, as of the last `IEvents.poll`. */
	var focused(get, never):Bool;

	/** Gets or sets the title bar's text; in a page, the document's title. */
	var title(get, set):String;

	/** Gets the window's inner width, in logical pixels; in a page, the viewport's. */
	var width(get, never):Int;

	/** Gets the window's inner height, in logical pixels; in a page, the viewport's. */
	var height(get, never):Int;

	/** Asks for an inner size.

		The window manager may give another size, or none; `width` and `height` answer on a later frame.
		@param width  The width, in logical pixels.
		@param height  The height, in logical pixels.
		@return  False, asking nothing, in a page or for a size under 1. */
	function requestSize(width:Int, height:Int):Bool;

	/** Returns whether `requestPosition` and `requestMonitorIndex` can ask.

		@return  False in a page, and where the compositor places windows (Wayland, XWayland). */
	function canMove():Bool;

	/** Gets the window's left edge on the desktop, in logical pixels: 0 natively where it can't move, the browser window's in a page. */
	var x(get, never):Int;

	/** Gets the window's top edge on the desktop, in logical pixels: 0 natively where it can't move, the browser window's in a page. */
	var y(get, never):Int;

	/** Asks for the window's left and top edges on the desktop.

		`x` and `y` answer on a later frame, with what the window manager gave.
		@param x  The left edge, in logical pixels.
		@param y  The top edge, in logical pixels.
		@return  False, asking nothing, where the window can't move (`canMove`). */
	function requestPosition(x:Int, y:Int):Bool;

	/** Returns whether `requestFullscreen` can ask.

		@return  True natively; in a page, whether the page may go fullscreen. */
	function canFullscreen():Bool;

	/** Gets a value indicating whether the window is fullscreen now; in a page, the canvas. */
	var fullscreen(get, never):Bool;

	/** Asks for fullscreen or a window.

		`fullscreen` answers on a later frame. A browser grants fullscreen only soon after a key press, click or tap; without a recent one the
		request waits for the player's next one. Natively it is granted.
		@param enabled  True for fullscreen, false for a window.
		@param done  Optional. Called once the change is granted.
		@param failed  Optional. Receives the browser's reason when it refuses; the page stays as it was.
		@return  False, calling neither, where it can't ask (`canFullscreen`). */
	function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool;

	/** Asks for the screen held one way up, or as the player holds it.

		Only some browsers lock it (Chrome on Android, and only in fullscreen: ask in `requestFullscreen`'s done); iOS Safari and desktops
		don't. A game also shows "turn your device" when the shape is wrong.
		@param orientation  Landscape, Portrait, or Any to let a lock go.
		@param done  Optional. Called once the screen is locked.
		@param failed  Optional. Receives the browser's reason when it refuses.
		@return  False, calling neither, where it can't ask: natively. */
	function requestOrientation(orientation:Orientation, ?done:Void->Void, ?failed:String->Void):Bool;

	/** Gets a value indicating whether the program shows the window; in a page, the canvas.

		Whether the player can see it (not minimized, the tab not in the background) is reported by the `Shown` and `Hidden` events. */
	var visible(get, never):Bool;

	/** Asks to show or hide the window; in a page, the canvas.

		`visible` answers on a later frame, natively once the window manager has shown it.
		@param visible  True to show it.
		@return  True: it always asks. */
	function requestVisible(visible:Bool):Bool;

	/** Gets the number of monitors, at least 1; a page sees one screen. */
	var monitorCount(get, never):Int;

	/** Gets the index of the monitor holding the window. */
	var monitorIndex(get, never):Int;

	/** Asks for the window on another monitor.

		`monitorIndex` answers on a later frame.
		@param index  The monitor, 0 to `monitorCount` - 1.
		@return  False, asking nothing, for an index out of range or where the window can't move (`canMove`). */
	function requestMonitorIndex(index:Int):Bool;

	/** Returns a monitor's name.

		@param index  The monitor.
		@return  Its name, or "" for an index out of range. */
	function getMonitorName(index:Int):String;

	/** Returns a monitor's left edge on the desktop.

		@param index  The monitor.
		@return  The edge, in logical pixels; 0 for an index out of range, and in a page. */
	function getMonitorX(index:Int):Int;

	/** Returns a monitor's top edge on the desktop.

		@param index  The monitor.
		@return  The edge, in logical pixels; 0 for an index out of range, and in a page. */
	function getMonitorY(index:Int):Int;

	/** Returns a monitor's width.

		@param index  The monitor.
		@return  The width, in logical pixels; 0 for an index out of range. */
	function getMonitorWidth(index:Int):Int;

	/** Returns a monitor's height.

		@param index  The monitor.
		@return  The height, in logical pixels; 0 for an index out of range. */
	function getMonitorHeight(index:Int):Int;

	/** Returns whether `close` removes the window.

		A menu asks before offering Quit.
		@return  True natively; false in a page, which a script can't close. */
	function canClose():Bool;

	/** Closes the window, natively; does nothing in a page.

		The program's owner ends its loop after it, and disposes the graphics drawing in it first. `onClose` runs first. */
	function close():Void;

	/** Gets or sets the call made once, as the window goes for good: natively in `close`, in a page at pagehide; null, the default, for none.

		Nothing of the program runs after it, so it is the last place to save; in a page, no frame follows, and an asynchronous write
		started in it may not finish. A page gets no `CloseRequested`, so this is its only end. */
	var onClose:Null<Void->Void>;
}
