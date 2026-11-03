package helix.platform.adapters.keyboard.dom;

import helix.platform.IKeyboard;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.dom.DomListeners;
import js.Browser;

/** Provides `IKeyboard` in a browser page: keys and typed text from the window.

	A key still down when the page loses the keyboard arrives as a `KeyUp` just before `FocusLost`, as a page gets no keyup for a key let go
	while it hasn't the keyboard. The page keeps its own shortcuts (with Ctrl, Meta or Alt) and the function keys; the program gets the
	rest. */
class DomKeyboardAdapter implements IKeyboard {
	final stream:EventStream;
	final listeners = new DomListeners();
	// The keys down, released at a focus lost.
	var held:Array<Int> = [];
	final release:Void->Void;

	/** Starts listening to the keyboard.

		@param options  The events adapter its events are delivered by. */
	public function new(options:DomKeyboardAdapterOptions) {
		stream = options.events.stream;
		var window = Browser.window;
		listeners.add(window, "keydown", e -> {
			var event:js.html.KeyboardEvent = cast e,
				key = codes.get(event.code);
			if (key != null) {
				if (held.indexOf(key) < 0)
					held.push(key);
				stream.record(KeyDown(cast key, event.repeat));
				if (!(event.ctrlKey || event.metaKey || event.altKey) && !(key >= 290 && key <= 314))
					event.preventDefault();
			}
			// Typed characters: event.key is one character (or a surrogate pair) once the layout is applied.
			if (textInput
				&& event.key != null
				&& (event.key.length == 1 || event.key.length == 2 && StringTools.fastCodeAt(event.key, 0) >= 0xD800))
				stream.record(Text(event.key));
		});
		listeners.add(window, "keyup", e -> {
			var event:js.html.KeyboardEvent = cast e,
				key = codes.get(event.code);
			if (key != null) {
				held.remove(key);
				stream.record(KeyUp(cast key));
			}
		});
		release = () -> {
			var keys = held;
			held = [];
			for (key in keys)
				stream.record(KeyUp(cast key));
		};
		stream.focusLosses.push(release);
	}

	/** Gets or sets whether typed text arrives. A computer's keys type while it is on; a phone shows no keyboard, which needs a focused
		input element. */
	public var textInput(get, set):Bool;

	var typing = false;

	function get_textInput():Bool
		return typing;

	function set_textInput(on:Bool):Bool
		return typing = on;

	public function dispose():Void {
		listeners.removeAll();
		stream.focusLosses.remove(release);
	}

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
