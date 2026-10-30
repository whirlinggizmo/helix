package helix.platform.adapters.mouse.dom;

import helix.platform.IMouse;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.dom.DomListeners;
import helix.platform.adapters.shared.dom.DomPointer;
import js.html.CanvasElement;
import js.html.PointerEvent;

/** Provides `IMouse` in a browser page: the mouse's and a pen's buttons, moves and wheel over the canvas, in its framebuffer pixels.

	The canvas keeps a pressed mouse until it is let go, so a drag out of it still arrives. Its context menu is kept from showing. */
class DomMouseAdapter implements IMouse {
	final stream:EventStream;
	final canvas:CanvasElement;
	final listeners = new DomListeners();
	// The buttons as last recorded (bit 0 left, 1 right, 2 middle), so a change is one down or up.
	var buttons = 0;

	/** Starts listening to the mouse over the canvas.

		@param options  The events adapter its events are delivered by. */
	public function new(options:DomMouseAdapterOptions) {
		stream = options.events.stream;
		canvas = options.events.canvas;
		listeners.add(canvas, "contextmenu", e -> e.preventDefault());
		listeners.add(canvas, "pointerdown", e -> {
			if (e.pointerType == "touch")
				return;
			DomPointer.capture(canvas, e);
			pointer(e);
		});
		listeners.add(canvas, "pointermove", e -> if (e.pointerType != "touch") pointer(e));
		listeners.add(canvas, "pointerup", e -> if (e.pointerType != "touch") pointer(e));
		listeners.add(canvas, "pointercancel", e -> if (e.pointerType != "touch") stream.record(MouseLeave));
		listeners.add(canvas, "wheel", e -> {
			var event:js.html.WheelEvent = cast e;
			event.preventDefault();
			// Notches: Chromium and Firefox report about 100 pixels or 3 lines a notch.
			var scale = event.deltaMode == 0 ? 1 / 100 : event.deltaMode == 1 ? 1 / 3 : 1;
			stream.record(Wheel(event.deltaX * scale, -event.deltaY * scale));
		});
	}

	// The buttons that changed (a second button pressed while one is held arrives as a move), then the move.
	function pointer(event:PointerEvent):Void {
		var p = DomPointer.position(canvas, event);
		var held = event.buttons;
		// The DOM's bits are left 1, right 2, middle 4; the buttons are 0 left, 1 right, 2 middle.
		for (button in 0...3) {
			var bit = 1 << button,
				was = buttons & bit != 0,
				now = held & bit != 0;
			if (now != was)
				stream.record(now ? MouseDown(cast button, p.x, p.y) : MouseUp(cast button, p.x, p.y));
		}
		buttons = held;
		stream.record(MouseMove(p.x, p.y));
	}

	public function dispose():Void
		listeners.removeAll();
}
