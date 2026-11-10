package helix.raylib;

/** Represents how one stick of a virtual gamepad starts and looks (`VirtualGamepadOptions`). A field left out takes the gamepad's options, or their default.
	Positions and sizes are in the screen's pixels.

	A stick captures a finger landing in its touch zone, even while it has captured another, and releases the earlier finger. A finger the
	other stick captured stays with the other stick. Where the two zones overlap, the stick that is not currently capturing a finger
	captures the landing finger, or the left stick when both are free. The stick releases its finger when the window changes size, and
	when a physical gamepad replaces the virtual gamepad. */
@:structInit class VirtualStickOptions {
	/** Gets or sets a value indicating whether the stick is enabled. Defaults to true. A disabled stick reads 0, is hidden, and ignores
		fingers. */
	@:optional public var enabled:Null<Bool>;

	/** Gets or sets where the stick captures a landing finger. The zone follows changes to this rectangle's fields. Defaults to the screen's left or right
		half with both sticks enabled and read by fingers, and the whole screen with one. The default follows the screen's size. */
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

	/** Gets or sets a value indicating whether the stick's hint is visible until the first touch. */
	@:optional public var hintVisible:Null<Bool>;

	/** Gets or sets a value indicating whether the stick is visible. A stick that isn't visible still reads. Defaults to true. */
	@:optional public var visible:Null<Bool>;

	/** Gets or sets the ring around the base. */
	@:optional public var baseOutlineColor:Null<Color>;

	/** Gets or sets the disc inside the ring. */
	@:optional public var baseFillColor:Null<Color>;

	/** Gets or sets the knob, the disc under the finger. Defaults to the base outline color, a little more opaque. */
	@:optional public var knobColor:Null<Color>;

	/** Gets or sets the image of the base, drawn in place of the ring and the disc. */
	@:optional public var baseTexture:Null<Texture2D>;

	/** Gets or sets the image of the knob, drawn in place of the knob's disc. */
	@:optional public var knobTexture:Null<Texture2D>;
}
