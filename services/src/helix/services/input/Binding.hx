package helix.services.input;

import helix.platform.Key;
import helix.platform.MouseButton;
import helix.platform.PadAxis;
import helix.platform.PadButton;

/** Specifies what an action is bound to (`Actions.bind`). */
enum Binding {
	/** A key. */
	Keyboard(key:Key);

	/** A mouse button. */
	Mouse(button:MouseButton);

	/** A gamepad's button, in a slot, 0 to 3. */
	Pad(slot:Int, button:PadButton);

	/** One side of a gamepad's stick axis or trigger, in a slot, 0 to 3: down while it's past the dead zone that way, its value how far. */
	Axis(slot:Int, axis:PadAxis, direction:AxisDirection);
}
