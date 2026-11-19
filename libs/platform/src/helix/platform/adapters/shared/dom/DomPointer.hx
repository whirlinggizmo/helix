package helix.platform.adapters.shared.dom;

import js.html.CanvasElement;
import js.html.PointerEvent;

/** Provides what the page's mouse and touch adapters share: a pointer's position on the canvas, and the canvas capturing the keyboard and
	the pointer as it is pressed. */
@:noCompletion
class DomPointer {
	/** Returns where a pointer is, in the canvas's framebuffer pixels from its top-left corner.

		@param canvas  The canvas the program draws in.
		@param event  The pointer's event.
		@return  The position. */
	public static function position(canvas:CanvasElement, event:PointerEvent):{x:Float, y:Float} {
		var box = canvas.getBoundingClientRect();
		return {x: (event.clientX - box.left) * canvas.width / box.width, y: (event.clientY - box.top) * canvas.height / box.height};
	}

	/** Captures a pressed pointer for the canvas: the canvas keeps the pointer until it is let go, and receives the keyboard's focus.
		Prevented, the press doesn't move the keyboard's focus, so the canvas focuses itself: in a frame (itch.io's page) the keys go to the
		page the player clicked.

		@param canvas  The canvas the program draws in.
		@param event  The pointer's press. */
	public static function capture(canvas:CanvasElement, event:PointerEvent):Void {
		canvas.setPointerCapture(event.pointerId);
		event.preventDefault();
		canvas.focus();
	}
}
