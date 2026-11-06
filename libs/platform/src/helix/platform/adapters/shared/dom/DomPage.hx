package helix.platform.adapters.shared.dom;

import js.Browser;
import js.html.CanvasElement;

/** Provides what a page's adapters share: whether the page has the keyboard and the files last dropped on the canvas, which the events
	adapter sees and the window adapter answers, and the canvas's drawing size, which follows the viewport and the pixel ratio. */
@:noCompletion
class DomPage {
	/** Gets or sets whether the page has the keyboard and is in front; the events adapter sets it from the page's listeners. */
	public static var focused = true;

	/** Gets or sets the files the last `FilesDropped` counted; the events adapter sets it at the poll delivering it. */
	public static var dropped:Array<js.html.File> = [];

	/** Finds the canvas the program draws in.

		@param id  The canvas element's id.
		@return  The canvas.
		@throws String  No canvas has that id. */
	public static function canvas(id:String):CanvasElement {
		var element = Browser.document.getElementById(id);
		if (!Std.isOfType(element, CanvasElement))
			throw 'no canvas has the id "$id"';
		return cast element;
	}

	/** Sizes the canvas's drawing buffer to the canvas's own box on the page, in framebuffer pixels: its CSS size times the device's
		pixel ratio, or the viewport's where the page gives it no size. A canvas laid out smaller than the viewport (a game in a page of
		other things, or a 800 x 450 canvas on a phone's screen) is drawn at its own size, not the screen's.

		@param canvas  The canvas the program draws in. */
	public static function fit(canvas:CanvasElement):Void {
		var ratio = Browser.window.devicePixelRatio;
		canvas.width = Std.int(Math.max(1, logicalWidth(canvas) * ratio));
		canvas.height = Std.int(Math.max(1, logicalHeight(canvas) * ratio));
	}

	/** Returns the canvas's width on the page, in logical pixels: its CSS box's, or the viewport's where the page gives it no size.

		@param canvas  The canvas.
		@return  The width. */
	public static function logicalWidth(canvas:CanvasElement):Float {
		var box = canvas.getBoundingClientRect();
		return box.width > 0 ? box.width : Browser.window.innerWidth;
	}

	/** Returns the canvas's height on the page, in logical pixels: its CSS box's, or the viewport's where the page gives it no size.

		@param canvas  The canvas.
		@return  The height. */
	public static function logicalHeight(canvas:CanvasElement):Float {
		var box = canvas.getBoundingClientRect();
		return box.height > 0 ? box.height : Browser.window.innerHeight;
	}
}
