package helix.platform.adapters.mouse.dom;

import helix.platform.CursorShape;
import helix.platform.IMouse;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.dom.DomActivation;
import helix.platform.adapters.shared.dom.DomListeners;
import helix.platform.adapters.shared.dom.DomPointer;
import js.Browser;
import js.html.CanvasElement;
import js.html.PointerEvent;

/** Provides `IMouse` in a browser page: the mouse's and a pen's buttons, moves and wheel over the canvas, in its framebuffer pixels.

	The canvas keeps a pressed mouse until it is let go, so a drag out of it still arrives. Its context menu is kept from showing. The cursor
	is the canvas's CSS cursor, and the lock is the browser's pointer lock on the canvas. */
class DomMouseAdapter implements IMouse {
	final stream:EventStream;
	final canvas:CanvasElement;
	final listeners = new DomListeners();
	// The buttons as last recorded (bit 0 left, 1 right, 2 middle), so a change is one down or up.
	var buttons = 0;
	// Where the mouse last was, in framebuffer pixels; while locked, where its moves have taken it.
	var lastX = 0.;
	var lastY = 0.;
	// Whether the next locked move is the first since the lock was asked for, whose distance Chromium reports as a jump from the canvas's
	// corner; it can come with the press that granted the lock, before the browser says the lock began.
	var lockBegan = false;
	// The lock asked for and not yet answered: what was asked, and its lambdas.
	var asking:Null<{locked:Bool, done:Null<Void->Void>, failed:Null<String->Void>}> = null;

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
		listeners.add(Browser.document, "pointerlockchange", _ -> answer(null));
		listeners.add(Browser.document, "pointerlockerror", _ -> answer("The browser refused to lock the mouse"));
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

	public var cursorVisible(get, set):Bool;

	var visible = true;

	function get_cursorVisible():Bool
		return visible;

	function set_cursorVisible(on:Bool):Bool {
		visible = on;
		applyCursor();
		return on;
	}

	public var cursorShape(get, set):CursorShape;

	// The shape asked for, shown while the cursor is.
	var asked = Arrow;

	function get_cursorShape():CursorShape
		return asked;

	function set_cursorShape(to:CursorShape):CursorShape {
		asked = to;
		applyCursor();
		return to;
	}

	// The canvas's CSS cursor for the shape, or none while hidden.
	function applyCursor():Void {
		canvas.style.cursor = !visible ? "none" : switch asked {
			case Text: "text";
			case Crosshair: "crosshair";
			case Pointer: "pointer";
			case ResizeHorizontal: "ew-resize";
			case ResizeVertical: "ns-resize";
			case ResizeDiagonalDown: "nwse-resize";
			case ResizeDiagonalUp: "nesw-resize";
			case Move: "move";
			case NotAllowed: "not-allowed";
			case Wait: "wait";
			case Progress: "progress";
			case _: "default";
		}
	}

	public var locked(get, never):Bool;

	function get_locked():Bool
		return Browser.document.pointerLockElement == canvas;

	public function requestLock(locked:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		var lockable:Dynamic = (cast canvas : Dynamic).requestPointerLock;
		if (lockable == null)
			return false;
		if (asking != null && asking.failed != null)
			asking.failed("Another lock was asked for");
		asking = {locked: locked, done: done, failed: failed};
		if (locked == this.locked) {
			answer(null);
			return true;
		}
		if (!locked) {
			Browser.document.exitPointerLock();
			return true;
		}
		// The lock wants a fresh press, as fullscreen does.
		DomActivation.ask(() -> {
			if (asking == null || !asking.locked || this.locked)
				return;
			lockBegan = true;
			var asked:Dynamic = (cast canvas : Dynamic).requestPointerLock();
			// A browser whose lock is a promise refuses through it, and also fires pointerlockerror; answer takes the first.
			if (asked != null && asked.then != null)
				asked.then(null,
					(error:Dynamic) -> answer(error != null
						&& error.message != null ? Std.string(error.message) : "The browser refused to lock the mouse"));
		});
		return true;
	}

	// Answers the lock asked for once the lock is as asked, or with why it couldn't be.
	function answer(refused:Null<String>):Void {
		var asked = asking;
		if (asked == null)
			return;
		if (refused == null && asked.locked != locked)
			return;
		asking = null;
		if (refused == null) {
			if (asked.done != null)
				asked.done();
		} else if (asked.failed != null)
			asked.failed(refused);
	}

	public function canSetPosition():Bool
		return false;

	public function setPosition(x:Float, y:Float):Bool
		return false;

	// The buttons that changed (a second button pressed while one is held arrives as a move), then the move: while locked, by the move's
	// own distance from where the mouse was, as the cursor is held still.
	function pointer(event:PointerEvent):Void {
		var p = DomPointer.position(canvas, event);
		if (locked) {
			var box = canvas.getBoundingClientRect(), first = lockBegan;
			lockBegan = false;
			p = first ? {x: lastX, y: lastY} : {
				x: lastX + event.movementX * canvas.width / box.width,
				y: lastY + event.movementY * canvas.height / box.height
			};
		}
		lastX = p.x;
		lastY = p.y;
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

	public function dispose():Void {
		listeners.removeAll();
		if (locked)
			Browser.document.exitPointerLock();
		canvas.style.cursor = "";
	}
}
