package helix.raylib;

/** Represents how a virtual gamepad starts and looks (`EnableVirtualGamepad`, in `helix.raylib.extras.VirtualGamepad`). Every field has a default, so options set
	only what they change. Its placement, dead zone, hint and colors are both sticks' defaults, and its colors the buttons' too. A field set
	in a stick's or a button's own options replaces it for that stick or button.
	Positions and sizes are in the screen's pixels. */
@:structInit class VirtualGamepadOptions {
	/** Gets or sets where each stick's base goes: `VIRTUAL_STICK_BASE_FLOATING`, `VIRTUAL_STICK_BASE_FOLLOWING` or `VIRTUAL_STICK_BASE_FIXED`.
		Defaults to `VIRTUAL_STICK_BASE_FLOATING`. */
	@:optional public var basePlacement:Null<Int>;

	/** Gets or sets how far each stick's knob moves before the stick reads, as a share of the radius, 0 to 1. A push past the dead zone reads from 0.
		Defaults to 0.12. A game's own dead zone applies on top. */
	@:optional public var deadZone:Null<Float>;

	/** Gets or sets a value indicating whether each floating or following stick's hint is visible until the first touch. The hint is a
		fainter copy of the stick at rest, centered one and a half radii in from the touch zone's bottom outer corner, on a device with touch.
		Defaults to true. */
	@:optional public var hintVisible:Null<Bool>;

	/** Gets or sets each stick's ring around the base. Defaults to `Fade(LIGHTGRAY, 0.5)`. The hint is this ring, fainter. */
	@:optional public var baseOutlineColor:Null<Color>;

	/** Gets or sets each stick's disc inside the ring. Defaults to `BLANK`. */
	@:optional public var baseFillColor:Null<Color>;

	/** Gets or sets each stick's knob, the disc under the finger, 0.4 of the radius. Defaults to the stick's base outline color, a little
		more opaque. */
	@:optional public var knobColor:Null<Color>;

	/** Gets or sets each stick's image of the base, drawn in place of the ring and the disc, scaled to the base's diameter and tinted by the
		base outline color. With a base texture, the base outline color defaults to `WHITE`. */
	@:optional public var baseTexture:Null<Texture2D>;

	/** Gets or sets each stick's image of the knob, drawn in place of the knob's disc, scaled to the knob's diameter and tinted by the knob
		color. With a knob texture, the knob color defaults to `WHITE`. */
	@:optional public var knobTexture:Null<Texture2D>;

	/** Gets or sets the font every button's label is drawn in. Defaults to the default font (`GetFontDefault`). */
	@:optional public var font:Null<Font>;

	/** Gets or sets bounds where a landing finger stays a free finger, even within a stick's touch zone, such as a raygui button's bounds.
		The blocked bounds follow changes to these rectangles' fields. A finger holding a stick keeps the stick when the finger moves into
		a blocked bound. */
	@:optional public var blockedBounds:Null<Array<Rectangle>>;

	/** Gets or sets the left stick, read as `GAMEPAD_AXIS_LEFT_X` and `GAMEPAD_AXIS_LEFT_Y`. */
	@:optional public var left:Null<VirtualStickOptions>;

	/** Gets or sets the right stick, read as `GAMEPAD_AXIS_RIGHT_X` and `GAMEPAD_AXIS_RIGHT_Y`. */
	@:optional public var right:Null<VirtualStickOptions>;

	/** Gets or sets the buttons, each read as a gamepad button. A finger landing on a button presses the button, even within a stick's
		touch zone. Defaults to `[]`. */
	@:optional public var buttons:Null<Array<VirtualButtonOptions>>;
}
