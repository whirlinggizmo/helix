package helix.services.input;

import helix.math.Vector2D;
import helix.platform.GamepadButton;

/** Represents how one button of a `VirtualGamepad` starts. Positions and sizes are framebuffer pixels. */
@:structInit
class VirtualButtonOptions {
	/** Gets the gamepad button it's read as. */
	public final button:GamepadButton;

	/** Gets its center. Defaults to its place in the diamond of the face buttons (`VirtualButton.position`). */
	@:optional public final position:Null<Vector2D>;

	/** Gets a value indicating whether it's enabled. Defaults to true. */
	@:optional public final enabled:Null<Bool>;

	/** Gets its radius. Defaults to 40 times the window's pixel ratio. */
	@:optional public final radius:Null<Float>;
}
