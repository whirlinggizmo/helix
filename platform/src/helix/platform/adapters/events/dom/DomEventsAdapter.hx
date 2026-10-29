package helix.platform.adapters.events.dom;

import helix.platform.Event;
import helix.platform.IEvents;
import helix.platform.PadAxis;
import helix.platform.PadButton;
import helix.platform.adapters.shared.dom.DomPage;
import js.Browser;
import js.html.CanvasElement;

/** Provides `IEvents` in a browser page.

	It alone listens to the page: keys and typed text from the window; mouse buttons, moves, fingers and the wheel from the canvas, in its
	framebuffer pixels; focus and the page's visibility; the viewport's size, which the canvas follows; a lost WebGL context; the device's
	orientation while wanted. Each listener only records; `poll` hands over what was recorded since the last one. Gamepads are read at
	`poll`, in the W3C standard layout: a page sees a pad only after a button press on it. */
class DomEventsAdapter implements IEvents {
	var canvas:CanvasElement;
	// Recorded by the listeners since the last poll, then what that poll delivered.
	var recorded:Array<Event> = [];
	var delivered:Array<Event> = [];
	// The mouse's buttons as last recorded (bit 0 left, 1 right, 2 middle), so a change is one down or up.
	var mouseButtons = 0;
	// The keys down, released at a focus lost: a page gets no keyup for a key let go while it hasn't the keyboard.
	var held:Array<Int> = [];
	// The pads in slots 0 to 3 as of the last poll: the browser's gamepad, or null.
	var pads:Array<Dynamic> = [null, null, null, null];
	// Each slot's buttons as the last poll read them: a page has no button events, so a change between polls is one.
	var padHeld:Array<Array<Bool>> = [for (_ in 0...4) [for (_ in 0...PadButton.COUNT) false]];
	var hidden = false;

	/** Starts listening to the page and the canvas the program draws in.

		@param options  The canvas's id.
		@throws String  No canvas has that id. */
	public function new(options:DomEventsAdapterOptions) {
		canvas = DomPage.canvas(options.canvasId);
		var window = Browser.window, document = Browser.document;
		hidden = document.hidden;
		DomPage.focused = document.hasFocus() && !hidden;
		window.addEventListener("blur", _ -> focus(false));
		window.addEventListener("focus", _ -> focus(!document.hidden));
		document.addEventListener("visibilitychange", _ -> {
			if (document.hidden != hidden) {
				hidden = document.hidden;
				recorded.push(hidden ? Hidden : Shown);
			}
			focus(!document.hidden && document.hasFocus());
		});
		window.addEventListener("resize", _ -> {
			DomPage.fit(canvas);
			recorded.push(Resized(canvas.width, canvas.height));
		});
		canvas.addEventListener("webglcontextlost", e -> {
			e.preventDefault();
			recorded.push(GraphicsLost);
		});
		window.addEventListener("keydown", e -> {
			var event:js.html.KeyboardEvent = cast e,
				key = codes.get(event.code);
			if (key != null) {
				if (held.indexOf(key) < 0)
					held.push(key);
				recorded.push(KeyDown(cast key, event.repeat));
				// The page keeps its own shortcuts and the function keys; the program gets the rest.
				if (!(event.ctrlKey || event.metaKey || event.altKey) && !(key >= 290 && key <= 314))
					event.preventDefault();
			}
			// Typed characters: event.key is one character (or a surrogate pair) once the layout is applied.
			if (event.key != null && (event.key.length == 1 || event.key.length == 2 && StringTools.fastCodeAt(event.key, 0) >= 0xD800))
				recorded.push(Text(event.key));
		});
		window.addEventListener("keyup", e -> {
			var event:js.html.KeyboardEvent = cast e,
				key = codes.get(event.code);
			if (key != null) {
				held.remove(key);
				recorded.push(KeyUp(cast key));
			}
		});
		canvas.addEventListener("contextmenu", e -> e.preventDefault());
		canvas.addEventListener("pointerdown", e -> {
			var event:js.html.PointerEvent = cast e;
			canvas.setPointerCapture(event.pointerId);
			// Prevented, the press doesn't move the keyboard's focus, so the canvas takes it: in a frame (itch.io's page) the keys go to
			// the page the player clicked.
			event.preventDefault();
			canvas.focus();
			pointer(event, true);
		});
		canvas.addEventListener("pointermove", e -> pointer(cast e, true));
		canvas.addEventListener("pointerup", e -> pointer(cast e, false));
		canvas.addEventListener("pointercancel", e -> {
			var event:js.html.PointerEvent = cast e;
			if (event.pointerType == "touch") {
				var p = position(event);
				recorded.push(TouchUp(event.pointerId, p.x, p.y));
			} else
				recorded.push(MouseLeave);
		});
		canvas.addEventListener("wheel", e -> {
			var event:js.html.WheelEvent = cast e;
			event.preventDefault();
			// Notches: Chromium and Firefox report about 100 pixels or 3 lines a notch.
			var scale = event.deltaMode == 0 ? 1 / 100 : event.deltaMode == 1 ? 1 / 3 : 1;
			recorded.push(Wheel(event.deltaX * scale, -event.deltaY * scale));
		}, {passive: false});
	}

	function focus(value:Bool):Void {
		if (value == DomPage.focused)
			return;
		DomPage.focused = value;
		if (!value) {
			for (key in held)
				recorded.push(KeyUp(cast key));
			held = [];
		}
		recorded.push(value ? FocusGained : FocusLost);
	}

	function position(event:js.html.PointerEvent):{x:Float, y:Float} {
		var box = canvas.getBoundingClientRect();
		return {x: (event.clientX - box.left) * canvas.width / box.width, y: (event.clientY - box.top) * canvas.height / box.height};
	}

	// A finger down, moved or lifted; or the mouse's buttons that changed (a second button pressed while one is held arrives as a move),
	// then its move.
	var fingers:Array<Int> = [];

	function pointer(event:js.html.PointerEvent, down:Bool):Void {
		var p = position(event);
		if (event.pointerType == "touch") {
			var known = fingers.indexOf(event.pointerId) >= 0;
			if (!down) {
				fingers.remove(event.pointerId);
				recorded.push(TouchUp(event.pointerId, p.x, p.y));
			} else if (known)
				recorded.push(TouchMove(event.pointerId, p.x, p.y));
			else {
				fingers.push(event.pointerId);
				recorded.push(TouchDown(event.pointerId, p.x, p.y));
			}
			return;
		}
		var held = event.buttons;
		// The DOM's bits are left 1, right 2, middle 4; the buttons are 0 left, 1 right, 2 middle.
		for (button in 0...3) {
			var bit = 1 << button,
				was = mouseButtons & bit != 0,
				now = held & bit != 0;
			if (now != was)
				recorded.push(now ? MouseDown(cast button, p.x, p.y) : MouseUp(cast button, p.x, p.y));
		}
		mouseButtons = held;
		recorded.push(MouseMove(p.x, p.y));
	}

	public function poll():Void {
		delivered.resize(0);
		for (event in recorded)
			delivered.push(event);
		recorded.resize(0);
		var list:Dynamic = Browser.navigator.getGamepads();
		for (slot in 0...4) {
			var pad:Dynamic = list != null && slot < list.length ? list[slot] : null;
			if (pad != null && !pad.connected)
				pad = null;
			if (pad != null && pads[slot] == null)
				delivered.push(PadConnected(slot));
			else if (pad == null && pads[slot] != null)
				delivered.push(PadDisconnected(slot));
			pads[slot] = pad;
			var held = padHeld[slot];
			for (i in 0...PadButton.COUNT) {
				var down = pad != null && isPadButtonDown(slot, cast i);
				if (down != held[i] && pad != null)
					delivered.push(down ? PadButtonDown(slot, cast i) : PadButtonUp(slot, cast i));
				held[i] = down;
			}
		}
	}

	public var events(get, never):Array<Event>;

	function get_events():Array<Event>
		return delivered;

	public function wait(timeout:Float):Void {}

	/** Does nothing: the window's keys type on a computer either way, and a phone's keyboard needs a focused input element. */
	public function setTextInput(on:Bool):Void {}

	public var activated(get, never):Bool;

	function get_activated():Bool {
		var activation:Dynamic = js.Syntax.code("navigator.userActivation");
		return activation == null || activation.hasBeenActive;
	}

	public function isPadConnected(slot:Int):Bool
		return slot >= 0 && slot < 4 && pads[slot] != null;

	public function getPadName(slot:Int):String
		return isPadConnected(slot) ? pads[slot].id : "";

	public function isPadButtonDown(slot:Int, button:PadButton):Bool {
		if (!isPadConnected(slot))
			return false;
		var buttons:Dynamic = pads[slot].buttons, i:Int = button;
		return i < buttons.length && buttons[i].pressed;
	}

	public function getPadAxis(slot:Int, axis:PadAxis):Float {
		if (!isPadConnected(slot))
			return 0;
		var pad:Dynamic = pads[slot], i:Int = axis;
		// The triggers are the standard layout's buttons 6 and 7, read by their value.
		if (i >= 4)
			return pad.buttons.length > i + 2 ? pad.buttons[i + 2].value : 0;
		return pad.axes.length > i ? pad.axes[i] : 0;
	}

	// Reading the device's orientation (deviceorientation), and waiting for a tap to ask for it where the browser wants one (iOS).
	var tiltListener:Null<Dynamic->Void>;
	var tiltAsking:Null<Dynamic->Void>;

	/** Listens to the device's orientation while on.

		Where the browser asks for leave (iOS), it is asked at the player's next tap, which shows its prompt. A page that isn't secure gets no
		readings (TiltState 6). No reading within a second and a half of the page having its focus is reported unavailable (TiltState 5),
		though it goes on listening: a phone's sensor may start late. */
	public function setTiltWanted(on:Bool):Void {
		var window:Dynamic = Browser.window;
		if (!on) {
			if (tiltListener != null)
				window.removeEventListener("deviceorientation", tiltListener);
			tiltListener = null;
			stopAsking();
			return;
		}
		if (window.isSecureContext == false) {
			recorded.push(TiltState(6));
			return;
		}
		if (window.DeviceOrientationEvent == null) {
			recorded.push(TiltState(5));
			return;
		}
		var listen = () -> {
			if (tiltListener != null)
				return;
			var read = false;
			tiltListener = e -> {
				// A reading without numbers (a sensor starting, or none) is passed over.
				if (e.beta == null || e.gamma == null)
					return;
				read = true;
				var angle:Float = js.Syntax.code("(screen.orientation && screen.orientation.angle) || window.orientation || 0");
				recorded.push(Tilt(e.beta, e.gamma, angle));
			};
			window.addEventListener("deviceorientation", tiltListener);
			// Chrome gives no readings while the page hasn't its focus, and its prompt takes it until the player's next tap: the time is
			// counted from then.
			var count = () -> haxe.Timer.delay(() -> if (!read && tiltListener != null) recorded.push(TiltState(5)), 1500);
			if (Browser.document.hasFocus())
				count();
			else {
				var focused:Dynamic->Void = null;
				focused = _ -> {
					window.removeEventListener("focus", focused);
					count();
				};
				window.addEventListener("focus", focused);
			}
		};
		if (!Std.isOfType(window.DeviceOrientationEvent.requestPermission, js.lib.Function)) {
			listen();
			return;
		}
		askTiltAtNextTap(listen);
	}

	// Asks for the tilt inside the next tap's own event, the only place the browser lets it be asked. An event whose press is already spent
	// (going fullscreen on the same tap spends it) is passed over: asked there, Chrome answers "denied" without asking the player. A
	// failed ask asks again at the next tap.
	function askTiltAtNextTap(listen:Void->Void):Void {
		var window:Dynamic = Browser.window;
		stopAsking();
		tiltAsking = _ -> {
			var activation:Dynamic = js.Syntax.code("navigator.userActivation");
			if (activation != null && !activation.isActive)
				return;
			stopAsking();
			(window.DeviceOrientationEvent.requestPermission() : js.lib.Promise<String>).then(answer -> {
				if (answer == "granted")
					listen();
				else
					recorded.push(TiltState(4));
				return null;
			}, _ -> {
				askTiltAtNextTap(listen);
				return null;
			});
		};
		for (name in ["touchend", "click"])
			window.addEventListener(name, tiltAsking, true);
	}

	function stopAsking():Void {
		if (tiltAsking == null)
			return;
		var window:Dynamic = Browser.window;
		for (name in ["touchend", "click"])
			window.removeEventListener(name, tiltAsking, true);
		tiltAsking = null;
	}

	/** Does nothing: the page's listeners go with it. */
	public function dispose():Void {}

	// KeyboardEvent.code to the Key at its place on the keyboard, by Key's numbers.
	static final codes:Map<String, Int> = {
		var m = new Map<String, Int>();
		for (i in 0...26)
			m.set("Key" + String.fromCharCode(65 + i), 65 + i);
		for (i in 0...10) {
			m.set("Digit" + i, 48 + i);
			m.set("Numpad" + i, 320 + i);
		}
		for (i in 1...26)
			m.set("F" + i, 289 + i);
		var named:Map<String, Int> = [
			"Space" => 32,
			"Quote" => 39,
			"Comma" => 44,
			"Minus" => 45,
			"Period" => 46,
			"Slash" => 47,
			"Semicolon" => 59,
			"Equal" => 61,
			"BracketLeft" => 91,
			"Backslash" => 92,
			"BracketRight" => 93,
			"Backquote" => 96,
			"IntlBackslash" => 161,
			"IntlRo" => 162,
			"Escape" => 256,
			"Enter" => 257,
			"Tab" => 258,
			"Backspace" => 259,
			"Insert" => 260,
			"Delete" => 261,
			"ArrowRight" => 262,
			"ArrowLeft" => 263,
			"ArrowDown" => 264,
			"ArrowUp" => 265,
			"PageUp" => 266,
			"PageDown" => 267,
			"Home" => 268,
			"End" => 269,
			"CapsLock" => 280,
			"ScrollLock" => 281,
			"NumLock" => 282,
			"PrintScreen" => 283,
			"Pause" => 284,
			"NumpadDecimal" => 330,
			"NumpadDivide" => 331,
			"NumpadMultiply" => 332,
			"NumpadSubtract" => 333,
			"NumpadAdd" => 334,
			"NumpadEnter" => 335,
			"NumpadEqual" => 336,
			"ShiftLeft" => 340,
			"ShiftRight" => 340,
			"ControlLeft" => 341,
			"ControlRight" => 341,
			"AltLeft" => 342,
			"AltRight" => 342,
			"MetaLeft" => 343,
			"MetaRight" => 343,
			"ContextMenu" => 348
		];
		for (code => key in named)
			m.set(code, key);
		m;
	};
}
