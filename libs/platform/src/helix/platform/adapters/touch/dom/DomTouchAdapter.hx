package helix.platform.adapters.touch.dom;

import helix.platform.ITouch;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.dom.DomListeners;
import helix.platform.adapters.shared.dom.DomPointer;
import js.html.CanvasElement;
import js.html.PointerEvent;

/** Provides `ITouch` in a browser page: fingers on the canvas, in its framebuffer pixels.

	The canvas keeps a finger until it lifts, so one sliding off it still arrives. While it exists the canvas's `touch-action` is `none`,
	so the browser doesn't take a moving finger to scroll or zoom the page, which would cancel it; one the browser takes anyway arrives as
	its `TouchUp`. */
class DomTouchAdapter implements ITouch {
	final stream:EventStream;
	final canvas:CanvasElement;
	final listeners = new DomListeners();
	// The fingers down, by the browser's pointer id.
	var fingers:Array<Int> = [];
	// The canvas's touch-action before, put back at dispose.
	final touchAction:String;

	public var available(get, never):Bool;

	function get_available():Bool
		return js.Syntax.code("(navigator.maxTouchPoints || 0) > 0");

	/** Starts listening to fingers on the canvas.

		@param options  The events adapter its events are delivered by. */
	public function new(options:DomTouchAdapterOptions) {
		stream = options.events.stream;
		canvas = options.events.canvas;
		touchAction = canvas.style.touchAction;
		canvas.style.touchAction = "none";
		listeners.add(canvas, "pointerdown", e -> {
			if (e.pointerType != "touch")
				return;
			DomPointer.capture(canvas, e);
			finger(e, true);
		});
		listeners.add(canvas, "pointermove", e -> if (e.pointerType == "touch") finger(e, true));
		listeners.add(canvas, "pointerup", e -> if (e.pointerType == "touch") finger(e, false));
		listeners.add(canvas, "pointercancel", e -> if (e.pointerType == "touch") finger(e, false));
	}

	function finger(event:PointerEvent, down:Bool):Void {
		var p = DomPointer.position(canvas, event);
		var known = fingers.indexOf(event.pointerId) >= 0;
		if (!down) {
			if (fingers.remove(event.pointerId))
				stream.record(TouchUp(event.pointerId, p.x, p.y));
		} else if (known)
			stream.record(TouchMove(event.pointerId, p.x, p.y));
		else if (event.type == "pointerdown") {
			fingers.push(event.pointerId);
			stream.record(TouchDown(event.pointerId, p.x, p.y));
		}
	}

	public function dispose():Void {
		listeners.removeAll();
		canvas.style.touchAction = touchAction;
	}
}
