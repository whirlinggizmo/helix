package helix.services.input;

import helix.platform.Key;
import helix.platform.MouseButton;
import helix.platform.GamepadAxis;
import helix.platform.GamepadButton;

/** Specifies what an action is bound to (`Actions.bind`). */
enum Binding {
	/** A key. */
	Keyboard(key:Key);

	/** A mouse button. */
	Mouse(button:MouseButton);

	/** A gamepad's button, by the gamepad's slot, 0 to 3. */
	Gamepad(slot:Int, button:GamepadButton);

	/** One side of a gamepad's stick axis or trigger, by the gamepad's slot, 0 to 3.

		The binding is down while the axis is past the dead zone on that side, and its value is how far past. */
	Axis(slot:Int, axis:GamepadAxis, direction:AxisDirection);

	/** One side of the device's tilt (`Tilt.getAxis`): down while it's tilted that way, its value how far. */
	Tilt(axis:TiltAxis, direction:AxisDirection);
}
