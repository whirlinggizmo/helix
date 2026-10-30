package helix.services.input;

import helix.platform.IEvents;
import helix.platform.IPollable;
import helix.platform.Key;
import helix.platform.MouseButton;
import helix.platform.PadAxis;
import helix.platform.PadButton;

/** Provides the keyboard, the mouse and the gamepads as state: what is held, and what went down or up this frame.

	The program constructs one over its `IEvents` and calls `poll` once a frame. The state then holds until the next poll. `poll` reads
	the events the last `IEvents.poll` delivered, so the two may be polled in either order. When `Input` is polled first, it is a frame
	behind.

	"Pressed" is true for the frame a key or button went down, once per press however long it is held. For named actions bound to
	several of these, use `Actions`.

	```haxe
	events.poll();
	input.poll();
	if (input.isKeyPressed(Space)) jump();
	var x = input.getPadAxis(0, LeftX);
	``` */
class Input implements IPollable {
	/** The most of a dead zone the calculation uses, so a stick keeps some travel past it: the rest is scaled by 1 / (1 - dead zone). */
	static inline final MOST_DEAD_ZONE = .95;

	/** The gamepad slots. */
	static inline final SLOTS = 4;

	final events:IEvents;
	// What is held, and what went down and up this frame: keys by Key, mouse buttons by MouseButton, pad buttons by slot * 32 + button.
	final keys = new Map<Int, Bool>();
	final keysPressed = new Map<Int, Bool>();
	final keysReleased = new Map<Int, Bool>();
	final mouse = new Map<Int, Bool>();
	final mousePressed = new Map<Int, Bool>();
	final mouseReleased = new Map<Int, Bool>();
	final pads = new Map<Int, Bool>();
	final padsPressed = new Map<Int, Bool>();
	final padsReleased = new Map<Int, Bool>();
	// Each slot's axes as this poll and the one before read them, slot * PadAxis.COUNT + axis.
	var axes = [for (_ in 0...SLOTS * PadAxis.COUNT) 0.];
	var lastAxes = [for (_ in 0...SLOTS * PadAxis.COUNT) 0.];

	/** Creates the state over the platform's events, with nothing held.

		@param events  The platform's events, whose last `poll` this one reads. */
	public function new(events:IEvents) {
		this.events = events;
	}

	/** Reads the events the last `IEvents.poll` delivered, updating what went down or up, the mouse's position and the wheel.

		Call it once a frame. When the window loses focus, every held key and mouse button is released. */
	public function poll():Void {
		keysPressed.clear();
		keysReleased.clear();
		mousePressed.clear();
		mouseReleased.clear();
		padsPressed.clear();
		padsReleased.clear();
		wheelX = 0;
		wheelY = 0;
		var swap = lastAxes;
		lastAxes = axes;
		axes = swap;
		for (slot in 0...SLOTS)
			for (axis in PadAxis.all)
				axes[slot * PadAxis.COUNT + axis] = events.getPadAxis(slot, axis);
		for (event in events.events)
			switch event {
				case KeyDown(key, repeat):
					if (!repeat && !keys.exists(key)) {
						keys.set(key, true);
						keysPressed.set(key, true);
					}
				case KeyUp(key):
					if (keys.remove(key))
						keysReleased.set(key, true);
				case MouseMove(x, y):
					mouseX = x;
					mouseY = y;
				case MouseDown(button, x, y):
					mouseX = x;
					mouseY = y;
					if (!mouse.exists(button)) {
						mouse.set(button, true);
						mousePressed.set(button, true);
					}
				case MouseUp(button, x, y):
					mouseX = x;
					mouseY = y;
					if (mouse.remove(button))
						mouseReleased.set(button, true);
				case Wheel(dx, dy):
					wheelX += dx;
					wheelY += dy;
				case PadButtonDown(slot, button):
					var id = slot * 32 + button;
					if (!pads.exists(id)) {
						pads.set(id, true);
						padsPressed.set(id, true);
					}
				case PadButtonUp(slot, button):
					var id = slot * 32 + button;
					if (pads.remove(id))
						padsReleased.set(id, true);
				case PadDisconnected(slot):
					for (id in [for (id in pads.keys()) id])
						if (Std.int(id / 32) == slot) {
							pads.remove(id);
							padsReleased.set(id, true);
						}
				case Activated:
					activated = true;
				case FocusLost:
					// What's held when the window loses the keyboard never sends its up, so it's let go here.
					release(keys, keysReleased);
					release(mouse, mouseReleased);
				case _:
			}
	}

	/** Returns whether a key is held.

		@param key  The key.
		@return  True from the frame it went down until the frame it went up. */
	public function isKeyDown(key:Key):Bool {
		return keys.exists(key);
	}

	/** Returns whether a key went down this frame.

		@param key  The key.
		@return  True for that frame alone. A key the OS repeats while it is held isn't pressed again. */
	public function isKeyPressed(key:Key):Bool {
		return keysPressed.exists(key);
	}

	/** Returns whether a key went up this frame.

		@param key  The key.
		@return  True for that frame alone. */
	public function isKeyReleased(key:Key):Bool {
		return keysReleased.exists(key);
	}

	/** Gets a value indicating whether the player has pressed a key or a mouse button, or lifted a finger, yet, on any target.

		A page can start audio, ask for tilt and go fullscreen only after that, so a game's "press any key" start waits for it the same way
		everywhere. A gamepad's press doesn't count, as a browser doesn't take one as the player's. It stays true once set. */
	public var activated(default, null):Bool = false;

	/** Gets the mouse's distance from the window's left edge, in framebuffer pixels, where it was last over the window. */
	public var mouseX(default, null):Float = 0;

	/** Gets the mouse's distance from the window's top edge, in framebuffer pixels, where it was last over the window. */
	public var mouseY(default, null):Float = 0;

	/** Gets the wheel's horizontal turn this frame, in notches, positive to the right. */
	public var wheelX(default, null):Float = 0;

	/** Gets the wheel's vertical turn this frame, in notches, positive away from the player. */
	public var wheelY(default, null):Float = 0;

	/** Returns whether a mouse button is held.

		@param button  The button.
		@return  True from the frame it went down until the frame it went up. */
	public function isMouseDown(button:MouseButton):Bool {
		return mouse.exists(button);
	}

	/** Returns whether a mouse button went down this frame.

		@param button  The button.
		@return  True for that frame alone. */
	public function isMousePressed(button:MouseButton):Bool {
		return mousePressed.exists(button);
	}

	/** Returns whether a mouse button went up this frame.

		@param button  The button.
		@return  True for that frame alone. */
	public function isMouseReleased(button:MouseButton):Bool {
		return mouseReleased.exists(button);
	}

	/** Returns whether a gamepad's button is held.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True from the frame it went down until the frame it went up; false for an empty slot. */
	public function isPadButtonDown(slot:Int, button:PadButton):Bool {
		return pads.exists(slot * 32 + button);
	}

	/** Returns whether a gamepad's button went down this frame.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True for that frame alone. */
	public function isPadButtonPressed(slot:Int, button:PadButton):Bool {
		return padsPressed.exists(slot * 32 + button);
	}

	/** Returns whether a gamepad's button went up this frame.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True for that frame alone. */
	public function isPadButtonReleased(slot:Int, button:PadButton):Bool {
		return padsReleased.exists(slot * 32 + button);
	}

	/** Returns where a gamepad's stick or trigger is, past the dead zone.

		A stick's axis is -1 to 1, with right and down positive. A trigger is 0 to 1. Inside `padDeadZone` the value is 0, and beyond it
		the value is scaled so it still reaches 1. A stick's dead zone is a circle, so a diagonal push isn't cut off where one axis alone
		would be.

		@param slot  The gamepad's slot, 0 to 3.
		@param axis  The stick's axis or the trigger.
		@return  The axis's value, or 0 for an empty slot or one outside 0 to 3. */
	public function getPadAxis(slot:Int, axis:PadAxis):Float {
		return pastDeadZone(axes, slot, axis);
	}

	/** Returns the axis as the poll before this one read it, which `Actions` uses to tell when it was pushed. */
	@:allow(helix.services.input)
	function getLastPadAxis(slot:Int, axis:PadAxis):Float {
		return pastDeadZone(lastAxes, slot, axis);
	}

	function pastDeadZone(from:Array<Float>, slot:Int, axis:PadAxis):Float {
		if (slot < 0 || slot >= SLOTS)
			return 0;
		var value = from[slot * PadAxis.COUNT + axis];
		var dead = padDeadZone < MOST_DEAD_ZONE ? padDeadZone : MOST_DEAD_ZONE;
		switch axis {
			case LeftX | LeftY | RightX | RightY:
				// A stick's dead zone is a circle, so a diagonal push isn't cut where one axis alone would be.
				var other = from[
					slot * PadAxis.COUNT + switch axis {
						case LeftX: LeftY;
						case LeftY: LeftX;
						case RightX: RightY;
						case _: RightX;
					}
				];
				var length = Math.sqrt(value * value + other * other);
				if (length <= dead)
					return 0;
				var scaled = value * Math.min(1, (length - dead) / (1 - dead)) / length;
				return scaled < -1 ? -1 : scaled > 1 ? 1 : scaled;
			case _:
				return value <= dead ? 0 : Math.min(1, (value - dead) / (1 - dead));
		}
	}

	/** Gets or sets how far a stick or trigger moves before it counts, 0 to 1. Clamped to that range. Defaults to 0.2.

		The default is large enough that a worn stick resting off center stays inside it. A dead zone past 0.95 acts as 0.95, so the stick
		keeps some travel. */
	public var padDeadZone(default, set):Float = 0.2;

	function set_padDeadZone(value:Float):Float {
		return padDeadZone = value > 0 ? (value < 1 ? value : 1) : 0;
	}

	static function release(held:Map<Int, Bool>, released:Map<Int, Bool>):Void {
		for (id in held.keys())
			released.set(id, true);
		held.clear();
	}
}
