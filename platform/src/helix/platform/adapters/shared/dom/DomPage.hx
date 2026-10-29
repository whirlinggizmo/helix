package helix.platform.adapters.shared.dom;

import js.Browser;
import js.html.CanvasElement;

/** Provides what a page's adapters share: whether the page has the keyboard, which the events adapter sees and the window adapter answers,
	and the canvas's drawing size, which follows the viewport and the pixel ratio. */
@:noCompletion
class DomPage {
	/** Gets or sets whether the page has the keyboard and is in front; the events adapter sets it from the page's listeners. */
	public static var focused = true;

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

	/** Sizes the canvas's drawing buffer to the viewport, in framebuffer pixels.

		@param canvas  The canvas the program draws in. */
	public static function fit(canvas:CanvasElement):Void {
		canvas.width = Std.int(Math.max(1, Browser.window.innerWidth * Browser.window.devicePixelRatio));
		canvas.height = Std.int(Math.max(1, Browser.window.innerHeight * Browser.window.devicePixelRatio));
	}
}
