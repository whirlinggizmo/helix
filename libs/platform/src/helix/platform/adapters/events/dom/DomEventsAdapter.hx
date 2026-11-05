package helix.platform.adapters.events.dom;

import helix.platform.Event;
import helix.platform.IEvents;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.PollAnswers;
import helix.platform.adapters.shared.dom.DomListeners;
import helix.platform.adapters.shared.dom.DomPage;
import js.Browser;
import js.html.CanvasElement;

/** Provides `IEvents` in a browser page.

	It listens to the page's focus and visibility, the viewport's size, which the canvas follows, a lost WebGL context and files dropped on
	the canvas, and for the player's first press anywhere in the page, until it comes. Each listener only records; `poll` hands over what was recorded since the
	last one, after which the window's requests answer, and the mouse's and the clipboard's whose answer was known at once. The device adapters built over it (`DomKeyboardAdapter`, `DomMouseAdapter`, `DomTouchAdapter`, `DomGamepadsAdapter`,
	`DomTiltAdapter`) add their events to the same records. */
class DomEventsAdapter implements IEvents {
	@:allow(helix.platform.adapters)
	final canvas:CanvasElement;
	@:allow(helix.platform.adapters)
	final stream = new EventStream();
	final listeners = new DomListeners();
	final pressListeners = new DomListeners();
	var hidden = false;
	// The files dropped since the last poll.
	var dropping:Array<js.html.File> = [];

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
			// Cancelled, so the browser restores the context (the graphics adapter cancels it too, for a program without events).
			e.preventDefault();
			stream.record(GraphicsLost);
		});
		listeners.add(canvas, "webglcontextrestored", _ -> stream.record(GraphicsRestored));
		// A drop's files, which the canvas takes rather than the page opening them; a dragged directory is no file. Every drop since the
		// last poll is one FilesDropped, delivered at the poll's end.
		listeners.add(canvas, "dragover", e -> e.preventDefault());
		listeners.add(canvas, "drop", e -> {
			e.preventDefault();
			var transfer:js.html.DataTransfer = e.dataTransfer;
			if (transfer == null)
				return;
			if (transfer.items == null) {
				for (i in 0...transfer.files.length)
					dropping.push(transfer.files[i]);
				return;
			}
			for (i in 0...transfer.items.length) {
				var item:Dynamic = transfer.items[i];
				if (item.kind != "file")
					continue;
				var entry:Dynamic = item.webkitGetAsEntry == null ? null : item.webkitGetAsEntry();
				var file:js.html.File = item.getAsFile();
				if (file != null && (entry == null || !entry.isDirectory))
					dropping.push(file);
			}
		});
		stream.polls.push(() -> if (dropping.length > 0) {
			DomPage.dropped = dropping;
			dropping = [];
			stream.deliver(FilesDropped(DomPage.dropped.length));
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
		PollAnswers.poll();
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
