package helix.services.input;

import helix.platform.IEvents;
import helix.platform.IGamepads;
import helix.platform.IPollable;
import helix.platform.PadAxis;
import helix.platform.PadButton;

/** Provides the gamepads as state, in slots 0 to 3: which buttons are held or went down or up this frame, and where each stick and trigger
	is, past a dead zone.

	The program constructs one over its `IEvents` and its `IGamepads`, and calls `poll` once a frame, as `Keyboard` is. A pad's axes are read once a poll, so
	they hold still for the frame. A pad that disconnects lets go of its buttons.

	```haxe
	var pads = new Gamepads(events, gamepadsAdapter);
	// each frame:
	pads.poll();
	if (pads.isButtonPressed(0, South)) jump();
	var x = pads.getAxis(0, LeftX);
	``` */
class Gamepads implements IPollable implements IActionDevice {
	/** The most of a dead zone the calculation uses, so a stick keeps some travel past it: the rest is scaled by 1 / (1 - dead zone). */
	static inline final MOST_DEAD_ZONE = .95;

	/** The gamepad slots. */
	static inline final SLOTS = 4;

	final events:IEvents;
	final gamepads:IGamepads;
	// Buttons held, and went down and up this frame, by slot * 32 + button.
	final held = new Map<Int, Bool>();
	final pressed = new Map<Int, Bool>();
	final released = new Map<Int, Bool>();
	// Each slot's axes as this poll and the one before read them, slot * PadAxis.COUNT + axis.
	var axes = [for (_ in 0...SLOTS * PadAxis.COUNT) 0.];
	var lastAxes = [for (_ in 0...SLOTS * PadAxis.COUNT) 0.];

	/** Creates the gamepads over the platform's events and gamepads, with nothing held.

		@param events  The platform's events, whose last `poll` this one reads.
		@param gamepads  The platform's gamepads, whose buttons those events carry and whose sticks and triggers are read. */
	public function new(events:IEvents, gamepads:IGamepads) {
		this.events = events;
		this.gamepads = gamepads;
	}

	/** Reads the events the last `IEvents.poll` delivered, and every pad's axes. Call it once a frame. */
	public function poll():Void {
		pressed.clear();
		released.clear();
		var swap = lastAxes;
		lastAxes = axes;
		axes = swap;
		for (slot in 0...SLOTS)
			for (axis in PadAxis.all)
				axes[slot * PadAxis.COUNT + axis] = gamepads.getAxis(slot, axis);
		for (event in events.events)
			switch event {
				case PadButtonDown(slot, button):
					var id = slot * 32 + button;
					if (!held.exists(id)) {
						held.set(id, true);
						pressed.set(id, true);
					}
				case PadButtonUp(slot, button):
					var id = slot * 32 + button;
					if (held.remove(id))
						released.set(id, true);
				case PadDisconnected(slot):
					for (id in [for (id in held.keys()) id])
						if (Std.int(id / 32) == slot) {
							held.remove(id);
							released.set(id, true);
						}
				case _:
			}
	}

	/** Returns whether a gamepad is in a slot.

		@param slot  The slot, 0 to 3.
		@return  True when one is connected there. */
	public function isConnected(slot:Int):Bool {
		return gamepads.isConnected(slot);
	}

	/** Returns a gamepad's name, as its maker gives it.

		@param slot  The slot, 0 to 3.
		@return  The name, or "" for an empty slot. */
	public function getName(slot:Int):String {
		return gamepads.getName(slot);
	}

	/** Returns whether a button is held.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True from the frame it went down until the frame it went up. False for an empty slot. */
	public function isButtonDown(slot:Int, button:PadButton):Bool {
		return held.exists(slot * 32 + button);
	}

	/** Returns whether a button went down this frame.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True for that frame alone. */
	public function isButtonPressed(slot:Int, button:PadButton):Bool {
		return pressed.exists(slot * 32 + button);
	}

	/** Returns whether a button went up this frame.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True for that frame alone. */
	public function isButtonReleased(slot:Int, button:PadButton):Bool {
		return released.exists(slot * 32 + button);
	}

	/** Returns where a stick's axis or a trigger is, past the dead zone.

		A stick's dead zone is a circle, so a diagonal push isn't cut off where one axis alone would be.
		@param slot  The gamepad's slot, 0 to 3.
		@param axis  The stick's axis or the trigger.
		@return  A stick's axis -1 to 1, right and down positive; a trigger 0 to 1. 0 inside `deadZone`, and beyond it scaled so it still
			reaches 1. 0 for an empty slot or one past 3. */
	public function getAxis(slot:Int, axis:PadAxis):Float {
		return pastDeadZone(axes, slot, axis);
	}

	/** Gets or sets how far a stick or trigger moves before it counts, 0 to 1. Clamped to that range. Defaults to 0.2.

		The default is large enough that a worn stick resting off center stays inside it. A dead zone past 0.95 acts as 0.95, so the stick
		keeps some travel. */
	public var deadZone(default, set):Float = 0.2;

	function set_deadZone(value:Float):Float {
		return deadZone = value > 0 ? (value < 1 ? value : 1) : 0;
	}

	@:noCompletion
	public function reads(binding:Binding):Bool
		return binding.match(Pad(_, _) | Axis(_, _, _));

	@:noCompletion
	public function getValue(binding:Binding):Float
		return switch binding {
			case Pad(slot, button): isButtonDown(slot, button) ? 1 : 0;
			case Axis(slot, axis, direction): side(getAxis(slot, axis), direction);
			case _: 0;
		}

	@:noCompletion
	public function wasDown(binding:Binding):Bool
		return switch binding {
			case Pad(slot, button): (isButtonDown(slot, button) || isButtonReleased(slot, button)) && !isButtonPressed(slot, button);
			case Axis(slot, axis, direction): side(pastDeadZone(lastAxes, slot, axis), direction) > 0;
			case _: false;
		}

	@:noCompletion
	public function isPressed(binding:Binding):Bool
		return switch binding {
			case Pad(slot, button): isButtonPressed(slot, button);
			case Axis(_, _, _): getValue(binding) > 0 && !wasDown(binding);
			case _: false;
		}

	@:noCompletion
	public function isReleased(binding:Binding):Bool
		return switch binding {
			case Pad(slot, button): isButtonReleased(slot, button);
			case Axis(_, _, _): wasDown(binding) && getValue(binding) == 0;
			case _: false;
		}

	// How far a value is toward a direction, 0 or more.
	static function side(value:Float, direction:AxisDirection):Float {
		var toward = direction == Negative ? -value : value;
		return toward > 0 ? toward : 0;
	}

	function pastDeadZone(from:Array<Float>, slot:Int, axis:PadAxis):Float {
		if (slot < 0 || slot >= SLOTS)
			return 0;
		var value = from[slot * PadAxis.COUNT + axis];
		var dead = deadZone < MOST_DEAD_ZONE ? deadZone : MOST_DEAD_ZONE;
		switch axis {
			case LeftX | LeftY | RightX | RightY:
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
}
