package helix.services.input;

import helix.platform.IEvents;
import helix.platform.IMouse;
import helix.platform.IPollable;
import helix.platform.MouseButton;

/** Provides the mouse as state: where it is, its wheel, and which buttons are held or went down or up this frame.

	The program constructs one over its `IEvents` and its `IMouse`, and calls `poll` once a frame, as `Keyboard` is. "Pressed" is true for the frame a
	button went down.

	```haxe
	var mouse = new Mouse(events, mouseAdapter);
	// each frame:
	mouse.poll();
	if (mouse.isButtonPressed(Left)) fire(mouse.x, mouse.y);
	``` */
class Mouse implements IPollable implements IActionDevice {
	final events:IEvents;
	final held = new Map<Int, Bool>();
	final pressed = new Map<Int, Bool>();
	final released = new Map<Int, Bool>();

	/** Creates the mouse over the platform's events and mouse, with nothing held.

		@param events  The platform's events, whose last `poll` this one reads.
		@param mouse  The platform's mouse, whose buttons and moves those events carry. */
	public function new(events:IEvents, mouse:IMouse) {
		this.events = events;
	}

	/** Gets the mouse's distance from the window's left edge, in framebuffer pixels, where it last was over the window. */
	public var x(default, null):Float = 0;

	/** Gets the mouse's distance from the window's top edge, in framebuffer pixels, where it last was over the window. */
	public var y(default, null):Float = 0;

	/** Gets how far the wheel turned this frame, in notches, right positive. */
	public var wheelX(default, null):Float = 0;

	/** Gets how far the wheel turned this frame, in notches, away from the player positive. */
	public var wheelY(default, null):Float = 0;

	/** Reads the events the last `IEvents.poll` delivered. Call it once a frame. When the window loses focus, every held button is
		released. */
	public function poll():Void {
		pressed.clear();
		released.clear();
		wheelX = 0;
		wheelY = 0;
		for (event in events.events)
			switch event {
				case MouseMove(atX, atY):
					x = atX;
					y = atY;
				case MouseDown(button, atX, atY):
					x = atX;
					y = atY;
					if (!held.exists(button)) {
						held.set(button, true);
						pressed.set(button, true);
					}
				case MouseUp(button, atX, atY):
					x = atX;
					y = atY;
					if (held.remove(button))
						released.set(button, true);
				case Wheel(dx, dy):
					wheelX += dx;
					wheelY += dy;
				case FocusLost:
					for (button in held.keys())
						released.set(button, true);
					held.clear();
				case _:
			}
	}

	/** Returns whether a button is held.

		@param button  The button.
		@return  True from the frame it went down until the frame it went up. */
	public function isButtonDown(button:MouseButton):Bool {
		return held.exists(button);
	}

	/** Returns whether a button went down this frame.

		@param button  The button.
		@return  True for that frame alone. */
	public function isButtonPressed(button:MouseButton):Bool {
		return pressed.exists(button);
	}

	/** Returns whether a button went up this frame.

		@param button  The button.
		@return  True for that frame alone. */
	public function isButtonReleased(button:MouseButton):Bool {
		return released.exists(button);
	}

	@:noCompletion
	public function reads(binding:Binding):Bool
		return binding.match(Mouse(_));

	@:noCompletion
	public function getValue(binding:Binding):Float
		return switch binding {
			case Mouse(button): isButtonDown(button) ? 1 : 0;
			case _: 0;
		}

	@:noCompletion
	public function wasDown(binding:Binding):Bool
		return switch binding {
			case Mouse(button): (isButtonDown(button) || isButtonReleased(button)) && !isButtonPressed(button);
			case _: false;
		}

	@:noCompletion
	public function isPressed(binding:Binding):Bool
		return switch binding {
			case Mouse(button): isButtonPressed(button);
			case _: false;
		}

	@:noCompletion
	public function isReleased(binding:Binding):Bool
		return switch binding {
			case Mouse(button): isButtonReleased(button);
			case _: false;
		}
}
