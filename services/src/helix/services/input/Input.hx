package helix.services.input;

import haxe.exceptions.NotImplementedException;
import helix.platform.IEvents;
import helix.platform.IPollable;
import helix.platform.Key;
import helix.platform.MouseButton;
import helix.platform.PadAxis;
import helix.platform.PadButton;

/** Provides the keyboard, the mouse and the gamepads as state: what is held, and what went down or up this frame.

	The program constructs one over its `IEvents` and calls `poll` once a frame; the state then holds until the next poll. It reads the
	events the last `IEvents.poll` delivered, so the two may be polled in either order: polled before them, it is a frame behind. "Pressed" is true for the frame a key or button went down, once per press however long it's held. Named actions bound to several
	of these are `Actions`.

	```haxe
	events.poll();
	input.poll();
	if (input.isKeyPressed(Space)) jump();
	var x = input.getPadAxis(0, LeftX);
	``` */
class Input implements IPollable {
	/** Creates the state over the platform's events, with nothing held.

		@param events  The platform's events, whose last `poll` this one reads. */
	public function new(events:IEvents) {
		throw new NotImplementedException();
	}

	/** Reads the events the last `IEvents.poll` delivered: what went down or up, where the mouse is and the wheel; call once a frame. */
	public function poll():Void {
		throw new NotImplementedException();
	}

	/** Returns whether a key is held.

		@param key  The key.
		@return  True from the frame it went down until the frame it went up. */
	public function isKeyDown(key:Key):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a key went down this frame.

		@param key  The key.
		@return  True for that frame alone; a key the OS repeats while it's held isn't pressed again. */
	public function isKeyPressed(key:Key):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a key went up this frame.

		@param key  The key.
		@return  True for that frame alone. */
	public function isKeyReleased(key:Key):Bool {
		throw new NotImplementedException();
	}

	/** Gets the mouse's distance from the window's left edge, in framebuffer pixels, where it last was over the window. */
	public var mouseX(default, null):Float = 0;

	/** Gets the mouse's distance from the window's top edge, in framebuffer pixels, where it last was over the window. */
	public var mouseY(default, null):Float = 0;

	/** Gets the wheel's turn this frame, in notches: right positive. */
	public var wheelX(default, null):Float = 0;

	/** Gets the wheel's turn this frame, in notches: away from the player positive. */
	public var wheelY(default, null):Float = 0;

	/** Returns whether a mouse button is held.

		@param button  The button.
		@return  True from the frame it went down until the frame it went up. */
	public function isMouseDown(button:MouseButton):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a mouse button went down this frame.

		@param button  The button.
		@return  True for that frame alone. */
	public function isMousePressed(button:MouseButton):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a mouse button went up this frame.

		@param button  The button.
		@return  True for that frame alone. */
	public function isMouseReleased(button:MouseButton):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a gamepad's button is held.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True from the frame it went down until the frame it went up; false for an empty slot. */
	public function isPadButtonDown(slot:Int, button:PadButton):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a gamepad's button went down this frame.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True for that frame alone. */
	public function isPadButtonPressed(slot:Int, button:PadButton):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether a gamepad's button went up this frame.

		@param slot  The gamepad's slot, 0 to 3.
		@param button  The button.
		@return  True for that frame alone. */
	public function isPadButtonReleased(slot:Int, button:PadButton):Bool {
		throw new NotImplementedException();
	}

	/** Returns where a gamepad's stick or trigger is, past the dead zone.

		@param slot  The gamepad's slot, 0 to 3.
		@param axis  The stick's axis or the trigger.
		@return  A stick's axis -1 to 1 (right and down positive), a trigger 0 to 1; 0 inside `padDeadZone`, and the rest scaled so it
			still reaches 1; 0 for an empty slot. */
	public function getPadAxis(slot:Int, axis:PadAxis):Float {
		throw new NotImplementedException();
	}

	/** Gets or sets how far a stick or trigger moves before it counts, 0 to 1; 0.2 by default, which a worn stick resting off center stays
		inside. */
	public var padDeadZone(default, set):Float = 0.2;

	function set_padDeadZone(value:Float):Float {
		throw new NotImplementedException();
	}
}
