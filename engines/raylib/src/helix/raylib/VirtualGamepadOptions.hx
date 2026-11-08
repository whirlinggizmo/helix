package helix.raylib;

/** Represents how a virtual gamepad starts and looks (`EnableVirtualGamepad`, in `helix.raylib.extras.VirtualGamepad`). Every field has a default, so options set
	only what they change. Each field here is both sticks' default. A field set in a stick's own options replaces it for that stick.
	Positions and sizes are in the screen's pixels. */
@:structInit class VirtualGamepadOptions {
	/** Gets or sets where each stick's base goes: `VIRTUAL_STICK_BASE_FLOATING`, `VIRTUAL_STICK_BASE_FOLLOWING` or `VIRTUAL_STICK_BASE_FIXED`.
		Defaults to `VIRTUAL_STICK_BASE_FLOATING`. */
	@:optional public var basePlacement:Null<Int>;

	/** Gets or sets how far each stick's knob moves before the stick reads, as a share of the radius, 0 to 1. A push past the dead zone reads from 0.
		Defaults to 0.12. A game's own dead zone applies on top. */
	@:optional public var deadZone:Null<Float>;

	/** Gets or sets a value indicating whether each stick draws a hint until the first touch. The hint is a faint ring of the stick's radius, at the fixed base, or
		centered one and a half radii in from the touch zone's bottom outer corner. Drawn only where `IsTouchScreenAvailable` is true.
		Defaults to true. */
	@:optional public var drawHint:Null<Bool>;

	/** Gets or sets each stick's ring around the base. Defaults to `Fade(LIGHTGRAY, 0.5)`. The hint is this ring, fainter. */
	@:optional public var baseOutlineColor:Null<Color>;

	/** Gets or sets each stick's disc inside the ring. Defaults to `BLANK`. */
	@:optional public var baseFillColor:Null<Color>;

	/** Gets or sets each stick's knob, the disc under the finger. Defaults to the stick's base outline color, a little more opaque. */
	@:optional public var knobColor:Null<Color>;

	/** Gets or sets the bounds cut out of the sticks' touch zones, such as a pause button's. A finger landing within a blocked bound stays a free finger.
		The blocked bounds follow changes to these rectangles' fields. A finger holding a stick keeps the stick when the finger moves into
		a blocked bound. */
	@:optional public var blockedBounds:Null<Array<Rectangle>>;

	/** Gets or sets the left stick, read as `GAMEPAD_AXIS_LEFT_X` and `GAMEPAD_AXIS_LEFT_Y`. */
	@:optional public var left:Null<VirtualStickOptions>;

	/** Gets or sets the right stick, read as `GAMEPAD_AXIS_RIGHT_X` and `GAMEPAD_AXIS_RIGHT_Y`. */
	@:optional public var right:Null<VirtualStickOptions>;
}
