package helix.raylib;

/** Represents one on-screen button of a virtual gamepad (`VirtualGamepadOptions.buttons`), read as a gamepad button. Positions and sizes
	are in the screen's pixels.

	The buttons capture a finger landing on one of them, even within a stick's touch zone, until the finger lifts. A button is down while a
	finger the buttons captured is within its circle, including a finger that slid there from another button. The mouse follows the free
	fingers.

	The buttons are drawn at `EndDrawing` while the virtual gamepad is enabled, on a device with touch. The buttons are hidden while a
	physical gamepad is in the virtual gamepad's slot. */
@:structInit class VirtualButtonOptions {
	/** Gets or sets the gamepad button the button is read as, such as `GAMEPAD_BUTTON_RIGHT_FACE_DOWN`. */
	public var button:Int;

	/** Gets or sets the button's center. The center follows changes to this vector's fields. Defaults to the button's place in a diamond of
		the four face buttons (`GAMEPAD_BUTTON_RIGHT_FACE_*`) at the screen's bottom-right corner, following the screen's size: the diamond's
		center three and a half radii in from the corner, each face button 1.6 radii from that center. Another button without a position is
		up and isn't drawn. */
	@:optional public var position:Null<Vector2>;

	/** Gets or sets a value indicating whether the button is enabled. Defaults to true. A disabled button is up, hidden, and ignores
		fingers. */
	@:optional public var enabled:Null<Bool>;

	/** Gets or sets a value indicating whether the button is visible. A button that isn't visible still reads. Defaults to true. */
	@:optional public var visible:Null<Bool>;

	/** Gets or sets the button's radius, the reach of a finger landing on the button. Defaults to 40. */
	@:optional public var radius:Null<Float>;

	/** Gets or sets the text drawn at the button's center, in the gamepad's font (`VirtualGamepadOptions.font`), as tall as the radius, or
		smaller to fit within the button's width. Defaults to "A", "B", "X" or "Y" for
		the face buttons (`GAMEPAD_BUTTON_RIGHT_FACE_DOWN`, `_RIGHT`, `_LEFT` and `_UP`), and "" for another button. */
	@:optional public var label:Null<String>;

	/** Gets or sets the ring's color. Defaults to the gamepad's base outline color. */
	@:optional public var outlineColor:Null<Color>;

	/** Gets or sets the color of the disc inside the ring, drawn while the button is down. Defaults to the gamepad's knob color. */
	@:optional public var fillColor:Null<Color>;

	/** Gets or sets the label's color. Defaults to the ring's color while the button is up, and `Fade(BLACK, 0.6)` while the button is
		down. */
	@:optional public var labelColor:Null<Color>;

	/** Gets or sets the image of the button while up, drawn in place of the ring, scaled to the button's diameter and tinted by the
		outline color. With a texture, the outline color defaults to `WHITE`. The label is drawn over the image. */
	@:optional public var texture:Null<Texture2D>;

	/** Gets or sets the image of the button while down, drawn in place of the ring and the disc. Defaults to the texture, tinted by the
		fill color. */
	@:optional public var downTexture:Null<Texture2D>;
}
