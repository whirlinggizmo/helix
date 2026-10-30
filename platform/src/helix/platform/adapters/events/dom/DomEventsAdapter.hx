package helix.platform.adapters.events.dom;

import helix.platform.Event;
import helix.platform.IEvents;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.dom.DomListeners;
import helix.platform.adapters.shared.dom.DomPage;
import js.Browser;
import js.html.CanvasElement;

/** Provides `IEvents` in a browser page.

	It listens to the page's focus and visibility, the viewport's size, which the canvas follows, and a lost WebGL context, and for the
	player's first press anywhere in the page, until it comes. Each listener only records; `poll` hands over what was recorded since the
	last one. The device adapters built over it (`DomKeyboardAdapter`, `DomMouseAdapter`, `DomTouchAdapter`, `DomGamepadsAdapter`,
	`DomTiltAdapter`) add their events to the same records. */
class DomEventsAdapter implements IEvents {
	@:allow(helix.platform.adapters)
	final canvas:CanvasElement;
	@:allow(helix.platform.adapters)
	final stream = new EventStream();
	final listeners = new DomListeners();
	final pressListeners = new DomListeners();
	var hidden = false;

	/** Starts listening to the page and the canvas the program draws in.

		@param options  The canvas's id.
		@throws String  No canvas has that id. */
	public function new(options:DomEventsAdapterOptions) {
		canvas = DomPage.canvas(options.canvasId);
		var window = Browser.window, document = Browser.document;
		hidden = document.hidden;
		DomPage.focused = document.hasFocus() && !hidden;
		listeners.add(window, "blur", _ -> focus(false));
		listeners.add(window, "focus", _ -> focus(!document.hidden));
		listeners.add(document, "visibilitychange", _ -> {
			if (document.hidden != hidden) {
				hidden = document.hidden;
				stream.record(hidden ? Hidden : Shown);
			}
			focus(!document.hidden && document.hasFocus());
		});
		listeners.add(window, "resize", _ -> {
			DomPage.fit(canvas);
			stream.record(Resized(canvas.width, canvas.height));
		});
		listeners.add(canvas, "webglcontextlost", e -> {
			e.preventDefault();
			stream.record(GraphicsLost);
		});
		// The first press, heard before the page's elements and the device adapters, so Unlocked comes before that press's own event: a
		// key or a mouse button going down, or a finger lifting, as a browser counts them.
		var press = (e:Dynamic) -> {
			pressListeners.removeAll();
			stream.record(Unlocked);
		};
		pressListeners.add(window, "keydown", e -> if (!e.repeat) press(e), true);
		pressListeners.add(window, "pointerdown", e -> if (e.pointerType != "touch") press(e), true);
		pressListeners.add(window, "pointerup", e -> if (e.pointerType == "touch") press(e), true);
	}

	function focus(value:Bool):Void {
		if (value == DomPage.focused)
			return;
		DomPage.focused = value;
		stream.record(value ? FocusGained : FocusLost);
	}

	public function poll():Void {
		stream.begin();
		stream.end();
	}

	public var unlocked(get, never):Bool;

	function get_unlocked():Bool
		return stream.unlocked;

	public var events(get, never):Array<Event>;

	function get_events():Array<Event>
		return stream.delivered;

	public function wait(timeout:Float):Void {}

	public function dispose():Void {
		listeners.removeAll();
		pressListeners.removeAll();
	}
}
