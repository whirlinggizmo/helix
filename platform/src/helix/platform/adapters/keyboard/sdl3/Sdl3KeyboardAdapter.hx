package helix.platform.adapters.keyboard.sdl3;

import helix.platform.IKeyboard;
import helix.platform.adapters.shared.sdl3.Sdl3EventsBridge;

/** Provides `IKeyboard` on SDL3, natively: keys by their physical position, and typed text through SDL's text input.

	SDL lets go of each key still down as the window loses the keyboard, so its `KeyUp` arrives. */
class Sdl3KeyboardAdapter implements IKeyboard {
	var typing = false;

	/** Turns SDL's keyboard events on.

		@param options  The events adapter its events are delivered by. */
	public function new(options:Sdl3KeyboardAdapterOptions) {
		Sdl3EventsBridge.want(Sdl3EventsBridge.KEYBOARD, 1);
	}

	/** Gets or sets whether typed text arrives. While it is on, SDL's text input is started on the window: a phone shows its keyboard, and
		Windows with a gamepad plugged in may show its touch keyboard. */
	public var textInput(get, set):Bool;

	function get_textInput():Bool
		return typing;

	function set_textInput(on:Bool):Bool {
		Sdl3EventsBridge.setText(on ? 1 : 0);
		return typing = on;
	}

	public function dispose():Void {
		typing = false;
		Sdl3EventsBridge.want(Sdl3EventsBridge.KEYBOARD, 0);
	}
}
