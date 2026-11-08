package helix.raylib;

/** Represents how one stick of a virtual gamepad starts and looks (`VirtualGamepadOptions`). A field left out takes the gamepad's options, or their default.
	Positions and sizes are in the screen's pixels.

	A finger landing in the stick's touch zone takes the stick, even from the finger holding it. A finger holding the other stick keeps
	the other stick. Where the two zones overlap, a landing finger takes the free stick, or the left stick if both are free. The stick
	lets go when the window changes size, and when a physical gamepad replaces the virtual gamepad. */
@:structInit class VirtualStickOptions {
	/** Gets or sets a value indicating whether the stick is on the screen. Defaults to true. */
	@:optional public var enabled:Null<Bool>;

	/** Gets or sets where a finger can land to take it. The zone follows changes to this rectangle's fields. Defaults to the screen's left or right
		half with both sticks enabled, and the whole screen with one. The default follows the screen's size. */
	@:optional public var touchZone:Null<Rectangle>;

	/** Gets or sets where the base goes. */
	@:optional public var basePlacement:Null<Int>;

	/** Gets or sets where the base stays with `VIRTUAL_STICK_BASE_FIXED`. The base follows changes to this vector's fields. Defaults to the touch
		zone's center. */
	@:optional public var fixedBasePosition:Null<Vector2>;

	/** Gets or sets how far the knob travels for a full push. Defaults to 60. */
	@:optional public var radius:Null<Float>;

	/** Gets or sets how far the knob moves before the stick reads, as a share of the radius. */
	@:optional public var deadZone:Null<Float>;

	/** Gets or sets a value indicating whether the stick draws a hint until the first touch. */
	@:optional public var drawHint:Null<Bool>;

	/** Gets or sets the ring around the base. */
	@:optional public var baseOutlineColor:Null<Color>;

	/** Gets or sets the disc inside the ring. */
	@:optional public var baseFillColor:Null<Color>;

	/** Gets or sets the knob, the disc under the finger. Defaults to the base outline color, a little more opaque. */
	@:optional public var knobColor:Null<Color>;
}
