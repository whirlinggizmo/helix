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

	// The framebuffer pixels a CSS pixel of each canvas gets, as its window chose: 1 until a window says.
	static final ratios = new haxe.ds.ObjectMap<CanvasElement, Float>();

	/** Sizes the canvas's drawing buffer to the canvas's own box on the page, in framebuffer pixels: its CSS size (the viewport's where the
		page gives it no size) times the ratio its window chose, 1 or the device's pixel ratio. A canvas laid out smaller than the viewport
		(a game in a page of other things, a 800 x 450 canvas on a phone's screen) is drawn at its own size, not the screen's.

		@param canvas  The canvas the program draws in.
		@param ratio  Optional. The framebuffer pixels a CSS pixel gets, kept for the fits to come (a resize); omitted, the one kept, or 1. */
	public static function fit(canvas:CanvasElement, ?ratio:Float):Void {
		if (ratio != null)
			ratios.set(canvas, ratio);
		var r = ratioOf(canvas);
		canvas.width = Std.int(Math.max(1, logicalWidth(canvas) * r));
		canvas.height = Std.int(Math.max(1, logicalHeight(canvas) * r));
	}

	/** Returns the framebuffer pixels a CSS pixel of the canvas gets: what its window chose, or 1.

		@param canvas  The canvas.
		@return  The ratio. */
	public static function ratioOf(canvas:CanvasElement):Float {
		var r = ratios.get(canvas);
		return r == null ? 1 : r;
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
