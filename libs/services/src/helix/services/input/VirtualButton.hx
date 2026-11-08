package helix.services.input;

import helix.math.Vector2D;
import helix.platform.GamepadButton;

/** Represents one on-screen button of a `VirtualGamepad`, read as a gamepad button.

	The buttons capture a finger landing on one of them, even within a stick's touch zone, until the finger lifts. A button is down while
	a finger the buttons captured is within its circle, including a finger that slid there from another button. Positions and sizes are
	framebuffer pixels. */
@:allow(helix.services.input.VirtualGamepad)
class VirtualButton {
	/** Gets or sets whether it's enabled. Disabled, the button is up and ignores fingers. */
	public var enabled:Bool = true;

	/** Gets or sets the gamepad button it's read as. */
	public var button:GamepadButton;

	/** Gets or sets its center. The center follows changes to this vector's fields. Null for its place in a diamond of the four face
		buttons (`South`, `East`, `West` and `North`) at the window's bottom-right corner, following the window's size: the diamond's center
		three and a half radii in from the corner, each face button 1.6 radii from that center. Another button without a position is up and
		ignores fingers. */
	public var position:Null<Vector2D>;

	/** Gets or sets its radius, the reach of a finger landing on it, in framebuffer pixels. */
	public var radius:Float;

	/** Gets a value indicating whether a finger the buttons captured is within its circle. */
	public var down(default, null):Bool = false;

	/** Gets its center's distance from the window's left edge, this frame: its position, or its place in the diamond. */
	public var centerX(default, null):Float = 0;

	/** Gets its center's distance from the window's top edge, this frame. */
	public var centerY(default, null):Float = 0;

	/** Gets a value indicating whether it has a center this frame: a position, or a place in the diamond. */
	public var placed(default, null):Bool = false;

	function new(button:GamepadButton, position:Null<Vector2D>, radius:Float) {
		this.button = button;
		this.position = position;
		this.radius = radius;
	}

	// Its center this frame, from its position or its place in the diamond in a window of a size.
	function place(width:Float, height:Float):Void {
		var own = position;
		if (own != null) {
			centerX = own.x;
			centerY = own.y;
			placed = true;
			return;
		}
		var across = button == East ? 1.6 : button == West ? -1.6 : 0,
			down = button == South ? 1.6 : button == North ? -1.6 : 0;
		placed = across != 0 || down != 0;
		centerX = width - radius * (3.5 - across);
		centerY = height - radius * (3.5 - down);
	}

	// Whether it reads fingers this frame: enabled, with a center.
	function active():Bool
		return enabled && placed;

	// Whether a point is within its circle.
	function contains(atX:Float, atY:Float):Bool {
		var dx = atX - centerX, dy = atY - centerY;
		return dx * dx + dy * dy <= radius * radius;
	}
}
