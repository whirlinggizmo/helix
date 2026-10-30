package helix.services.input;

import helix.platform.IEvents;
import helix.platform.IKeyboard;
import helix.platform.IPollable;
import helix.platform.Key;

/** Provides the keyboard as state: what is held, and what went down or up this frame.

	The program constructs one over its `IEvents` and its `IKeyboard`, and calls `poll` once a frame. The state then holds until the next poll. `poll` reads
	the events the last `IEvents.poll` delivered, so the two may be polled in either order. When the keyboard is polled first, it is a
	frame behind. "Pressed" is true for the frame a key went down, once per press however long it is held.

	```haxe
	var keyboard = new Keyboard(events, keyboardAdapter);
	// each frame:
	keyboard.poll();
	if (keyboard.isKeyPressed(Space)) jump();
	``` */
class Keyboard implements IPollable implements IActionDevice {
	final events:IEvents;
	final keyboard:IKeyboard;
	final held = new Map<Int, Bool>();
	final pressed = new Map<Int, Bool>();
	final released = new Map<Int, Bool>();

	/** Creates the keyboard over the platform's events and keyboard, with nothing held.

		@param events  The platform's events, whose last `poll` this one reads.
		@param keyboard  The platform's keyboard, whose keys those events carry. */
	public function new(events:IEvents, keyboard:IKeyboard) {
		this.events = events;
		this.keyboard = keyboard;
	}

	/** Gets or sets whether typed text arrives, as `IKeyboard.textInput`. A phone shows its keyboard while it is on. Defaults to false. */
	public var textInput(get, set):Bool;

	function get_textInput():Bool
		return keyboard.textInput;

	function set_textInput(on:Bool):Bool
		return keyboard.textInput = on;

	/** Gets the text typed this frame, in order, or "" when none was. Text is typed only while `textInput` is on. */
	public var text(default, null):String = "";

	/** Reads the events the last `IEvents.poll` delivered. Call it once a frame. When the window loses focus, every held key is released. */
	public function poll():Void {
		pressed.clear();
		released.clear();
		var typed:Null<StringBuf> = null;
		for (event in events.events)
			switch event {
				case Text(characters):
					if (typed == null)
						typed = new StringBuf();
					typed.add(characters);
				case KeyDown(key, repeat):
					if (!repeat && !held.exists(key)) {
						held.set(key, true);
						pressed.set(key, true);
					}
				case KeyUp(key):
					if (held.remove(key))
						released.set(key, true);
				case FocusLost:
					// A key held when the window loses the keyboard never sends its up, so it's let go here.
					for (key in held.keys())
						released.set(key, true);
					held.clear();
				case _:
			}
		text = typed == null ? "" : typed.toString();
	}

	/** Returns whether a key is held.

		@param key  The key.
		@return  True from the frame it went down until the frame it went up. */
	public function isKeyDown(key:Key):Bool {
		return held.exists(key);
	}

	/** Returns whether a key went down this frame.

		@param key  The key.
		@return  True for that frame alone. A key the OS repeats while it is held isn't pressed again. */
	public function isKeyPressed(key:Key):Bool {
		return pressed.exists(key);
	}

	/** Returns whether a key went up this frame.

		@param key  The key.
		@return  True for that frame alone. */
	public function isKeyReleased(key:Key):Bool {
		return released.exists(key);
	}

	@:noCompletion
	public function reads(binding:Binding):Bool
		return binding.match(Keyboard(_));

	@:noCompletion
	public function getValue(binding:Binding):Float
		return switch binding {
			case Keyboard(key): isKeyDown(key) ? 1 : 0;
			case _: 0;
		}

	@:noCompletion
	public function wasDown(binding:Binding):Bool
		return switch binding {
			case Keyboard(key): (isKeyDown(key) || isKeyReleased(key)) && !isKeyPressed(key);
			case _: false;
		}

	@:noCompletion
	public function isPressed(binding:Binding):Bool
		return switch binding {
			case Keyboard(key): isKeyPressed(key);
			case _: false;
		}

	@:noCompletion
	public function isReleased(binding:Binding):Bool
		return switch binding {
			case Keyboard(key): isKeyReleased(key);
			case _: false;
		}
}
