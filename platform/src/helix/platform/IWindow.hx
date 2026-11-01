package helix.platform;

import haxe.io.Bytes;

/** Defines the window a program draws in, with its title, size, position, fullscreen, visibility and monitors.

	In a page the window is the page. Its title is the document's and its size is the viewport's, while fullscreen and visibility apply to
	the canvas. Sizes are in logical pixels unless they are named as framebuffer pixels.

	A request asks for something the platform may refuse, or grant later. It returns whether it asked, and the matching property answers
	on a later frame. A `can` method tells whether to offer the request at all.

	The window reports nothing by itself. What happens to it, such as being resized, focused, minimized or asked to close, arrives as
	events from `IEvents.poll`. */
interface IWindow {
	/** Gets the drawable area's width, in framebuffer pixels. */
	var framebufferWidth(get, never):Int;

	/** Gets the drawable area's height, in framebuffer pixels. */
	var framebufferHeight(get, never):Int;

	/** Gets the number of framebuffer pixels per logical pixel. */
	var pixelRatio(get, never):Float;

	/** Gets a value indicating whether the window has the keyboard, as of the last `IEvents.poll`. */
	var focused(get, never):Bool;

	/** Gets or sets the title bar's text. In a page it is the document's title. */
	var title(get, set):String;

	/** Gets the window's inner width, in logical pixels. In a page it is the viewport's width. */
	var width(get, never):Int;

	/** Gets the window's inner height, in logical pixels. In a page it is the viewport's height. */
	var height(get, never):Int;

	/** Asks for an inner size.

		The window manager may give another size, or none; `width` and `height` reflect the result once the request completes.
		@param width  The width, in logical pixels.
		@param height  The height, in logical pixels.
		@return  False, asking nothing, in a page or for a size under 1. */
	function requestSize(width:Int, height:Int):Bool;

	/** Returns whether `requestPosition` and `requestMonitorIndex` can ask.

		@return  False in a page, and where the compositor places windows (Wayland, XWayland). */
	function canMove():Bool;

	/** Gets the window's left edge on the desktop, in logical pixels.

		Natively it is 0 where the window can't move. In a page it is the browser window's left edge. */
	var x(get, never):Int;

	/** Gets the window's top edge on the desktop, in logical pixels.

		Natively it is 0 where the window can't move. In a page it is the browser window's top edge. */
	var y(get, never):Int;

	/** Asks for the window's left and top edges on the desktop.

		`x` and `y` reflect the result once the request completes: what the window manager gave.
		@param x  The left edge, in logical pixels.
		@param y  The top edge, in logical pixels.
		@return  False, asking nothing, where the window can't move (`canMove`). */
	function requestPosition(x:Int, y:Int):Bool;

	/** Returns whether `requestFullscreen` can ask.

		@return  True natively. In a page, whether the page may go fullscreen. */
	function canFullscreen():Bool;

	/** Gets a value indicating whether the window is fullscreen now. In a page it tells whether the canvas is. */
	var fullscreen(get, never):Bool;

	/** Asks for fullscreen or a window.

		`fullscreen` reflects the result once the request completes. Natively the request is granted. A browser grants fullscreen only soon after a key press,
		click or tap. Without a recent one, the request waits for the player's next one.
		@param enabled  True for fullscreen, false for a window.
		@param done  Optional. Called once the change is granted.
		@param failed  Optional. Receives the browser's reason when it refuses. The page is unchanged.
		@return  False, calling neither, where it can't ask (`canFullscreen`). */
	function requestFullscreen(enabled:Bool, ?done:Void->Void, ?failed:String->Void):Bool;

	/** Gets the way up the screen is held for the program, as `requestOrientation` asked: `Any` when it isn't held. A page loses it as
		it leaves fullscreen, as browsers release the lock then; natively it is always `Any`. */
	var orientation(get, never):Orientation;

	/** Asks for the screen to be held one way up, or as the player holds it.

		Only some browsers lock the screen. Chrome on Android does, but only in fullscreen, so the request belongs in `requestFullscreen`'s
		done. iOS Safari and desktops don't lock it. A game also shows "turn your device" when the shape is wrong. `orientation` reflects
		the result once the request completes.
		@param orientation  Landscape, Portrait, or Any to release a lock.
		@param done  Optional. Called once the screen is locked.
		@param failed  Optional. Receives the browser's reason when it refuses.
		@return  False, calling neither, where it can't ask, which is natively. */
	function requestOrientation(orientation:Orientation, ?done:Void->Void, ?failed:String->Void):Bool;

	/** Gets a value indicating whether the program shows the window. In a page it tells whether the canvas is shown.

		Whether the player can see the window, because it isn't minimized and its tab isn't in the background, is reported by the `Shown`
		and `Hidden` events. */
	var visible(get, never):Bool;

	/** Asks to show or hide the window. In a page it shows or hides the canvas.

		`visible` reflects the result once the request completes: natively, once the window manager has shown it.
		@param visible  True to show it.
		@return  True, because it always asks. */
	function requestVisible(visible:Bool):Bool;

	/** Gets a value indicating whether the window fills the desktop as the window manager maximizes it. It is false in a page. */
	var maximized(get, never):Bool;

	/** Asks for the window maximized, or back to its size from maximized or minimized.

		`maximized` reflects the result once the request completes.
		@param maximized  True to maximize it, false to restore it.
		@return  False, asking nothing, in a page, whose canvas the page sizes. */
	function requestMaximized(maximized:Bool):Bool;

	/** Gets a value indicating whether the window is minimized. It is false in a page; a tab in the background is `Hidden`. */
	var minimized(get, never):Bool;

	/** Asks for the window minimized, or back from minimized.

		`minimized` reflects the result once the request completes.
		@param minimized  True to minimize it, false to restore it.
		@return  False, asking nothing, in a page. */
	function requestMinimized(minimized:Bool):Bool;

	/** Asks for the window brought to the front with the keyboard. A window manager may only flash it. In a page the canvas takes the
		keyboard.

		`focused` reflects the result once the request completes.
		@return  True, because it always asks. */
	function requestFocus():Bool;

	/** Sets the window's icon, which the desktop shows in its title bar and task bar. In a page it is the page's icon.

		@param width  The icon's width, in pixels.
		@param height  The icon's height.
		@param pixels  The icon's pixels: `width * height * 4` bytes of RGBA8, rows top first.
		@throws String  When the size isn't positive or the pixels are fewer than it needs. */
	function setIcon(width:Int, height:Int, pixels:Bytes):Void;

	/** Gets how opaque the window is, from 0 (clear) to 1. */
	var opacity(get, never):Float;

	/** Asks for the window to be see-through. In a page it fades the canvas.

		`opacity` reflects the result once the request completes.
		@param opacity  From 0 (clear) to 1 (opaque).
		@return  False, asking nothing, where the desktop can't (a desktop without a compositor). */
	function requestOpacity(opacity:Float):Bool;

	/** Asks for the smallest size the player can make the window; 0 by 0 for none.

		@param width  The width, in logical pixels.
		@param height  The height.
		@return  False, asking nothing, in a page. */
	function requestMinimumSize(width:Int, height:Int):Bool;

	/** Asks for the largest size the player can make the window; 0 by 0 for none.

		@param width  The width, in logical pixels.
		@param height  The height.
		@return  False, asking nothing, in a page. */
	function requestMaximumSize(width:Int, height:Int):Bool;

	/** Gets the number of monitors, at least 1. A page sees one screen. */
	var monitorCount(get, never):Int;

	/** Gets the index of the monitor holding the window. */
	var monitorIndex(get, never):Int;

	/** Asks for the window on another monitor.

		`monitorIndex` reflects the result once the request completes.
		@param monitorIndex  The monitor, 0 to `monitorCount` - 1.
		@return  False, asking nothing, for an index out of range or where the window can't move (`canMove`). */
	function requestMonitorIndex(monitorIndex:Int):Bool;

	/** Returns a monitor's name.

		@param monitorIndex  The monitor.
		@return  Its name, or "" for an index out of range. */
	function getMonitorName(monitorIndex:Int):String;

	/** Returns a monitor's left edge on the desktop.

		@param monitorIndex  The monitor.
		@return  The edge, in logical pixels, or 0 for an index out of range and in a page. */
	function getMonitorX(monitorIndex:Int):Int;

	/** Returns a monitor's top edge on the desktop.

		@param monitorIndex  The monitor.
		@return  The edge, in logical pixels, or 0 for an index out of range and in a page. */
	function getMonitorY(monitorIndex:Int):Int;

	/** Returns a monitor's width.

		@param monitorIndex  The monitor.
		@return  The width, in logical pixels, or 0 for an index out of range. */
	function getMonitorWidth(monitorIndex:Int):Int;

	/** Returns a monitor's height.

		@param monitorIndex  The monitor.
		@return  The height, in logical pixels, or 0 for an index out of range. */
	function getMonitorHeight(monitorIndex:Int):Int;

	/** Returns how many times a second a monitor shows a new picture.

		@param monitorIndex  The monitor, 0 to `monitorCount` - 1.
		@return  The refresh rate in hertz, or 0 where it isn't known, as in a page. */
	function getMonitorRefreshRate(monitorIndex:Int):Float;

	/** Reads a file dropped on the window, one the last `FilesDropped` event counted.

		One of `read` or `failed` is called once, during this call or later: natively during it, in a page later. Natively the file is
		read from where it is on disk, so one moved or changed since the drop reads as it is now. In a page it is the File the browser
		gave, kept until the next drop.
		@param fileIndex  The file, 0 to the event's count - 1.
		@param maxBytes  The largest file to read; a larger one fails.
		@param read  Receives the file's name, without its directory, and its bytes.
		@param failed  Receives why it can't be read: an index no drop gave, a file over `maxBytes`, or the platform's reason. */
	function readDroppedFile(fileIndex:Int, maxBytes:Int, read:(name:String, bytes:Bytes) -> Void, failed:String->Void):Void;

	/** Returns whether `close` removes the window.

		A menu checks it before offering Quit.
		@return  True natively. False in a page, which a script can't close. */
	function canClose():Bool;

	/** Closes the window natively, and does nothing in a page.

		`onClose` runs before the window closes. The program disposes the graphics drawing in the window before calling it, and ends its
		loop after it. */
	function close():Void;

	/** Gets or sets the function called once, as the window goes for good. It defaults to null, for none.

		Natively it is called in `close`. In a page it is called at pagehide, with no frame after it, so a file written there isn't kept: a
		browser drops a write that starts as its page goes. A page receives no `CloseRequested`, so this is a page's only end. */
	var onClose:Null<Void->Void>;
}
