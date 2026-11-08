package helix.services.input;

import helix.math.Bounds2D;
import helix.math.Vector2D;

/** Represents one stick of a `VirtualGamepad`: its settings, and the finger it captured.

	A stick captures a finger landing in its touch zone, even while it has captured another, and releases the earlier finger. A finger the
	other stick captured stays with the other stick. Where the two zones overlap, the stick that is not currently capturing a finger
	captures the landing finger, or the left stick when both are free. When the finger a stick captured lifts, the stick captures a finger
	still down in its zone, without moving the knob. Fingers the buttons (`VirtualButton`) captured stay with the buttons.

	The stick releases its finger when the window changes size, when the stick is disabled, and when a physical gamepad replaces the
	virtual gamepad. The next finger landing in its zone is captured again. Positions and sizes are framebuffer pixels.

	A stick with `tilt` reads the tilt in place of a finger, and captures none. */
@:allow(helix.services.input.VirtualGamepad)
class VirtualStick {
	/** Gets or sets whether it's enabled. Disabled, the stick reads 0, ignores fingers and releases the finger it captured. */
	public var enabled(default, set):Bool = true;

	/** Gets or sets where the stick captures a landing finger. The zone follows changes to these bounds' fields. Null for its default: the
		window's left or right half with both sticks enabled and read by fingers, and the whole window with one, following the window's
		size. */
	public var touchZone:Null<Bounds2D> = null;

	/** Gets or sets whether the stick reads the virtual gamepad's tilt (`VirtualGamepad.tilt`) in place of a finger: `Tilt.getAxis(X)` as
		x and `Tilt.getAxis(Y)` as y, past the stick's dead zone. A tilt stick ignores fingers. Defaults to false. */
	public var tilt(default, set):Bool = false;

	/** Gets or sets where the base goes. */
	public var basePlacement:VirtualStickBase = Floating;

	/** Gets or sets where the base stays with `Fixed` placement. The base follows changes to this vector's fields. Null for the touch
		zone's center. */
	public var fixedBasePosition:Null<Vector2D> = null;

	/** Gets or sets how far the knob travels for a full push, in framebuffer pixels. */
	public var radius:Float = 60;

	/** Gets or sets how far the knob moves before the stick reads, as a share of the radius, 0 to 1. A push past the dead zone reads
		from 0. Clamped to that range. `Gamepads.deadZone` applies after it. */
	public var deadZone(default, set):Float = .12;

	/** Gets a value indicating whether it has captured a finger. */
	public var held(get, never):Bool;

	/** Gets the id of the finger holding it, as `Touch` knows the finger. -1 while not held. */
	public var finger(default, null):Int = -1;

	/** Gets where it's pushed across, -1 (left) to 1 (right), within a circle of radius 1. 0 while a stick read by fingers isn't held. */
	public var x(default, null):Float = 0;

	/** Gets where it's pushed up and down, -1 (up) to 1 (down), within a circle of radius 1. 0 while a stick read by fingers isn't
		held. */
	public var y(default, null):Float = 0;

	/** Gets the base's distance from the window's left edge. While not held, and for a tilt stick, the base is at the stick's home: the fixed base, or centered one and a
		half radii in from the touch zone's bottom outer corner. */
	public var baseX(default, null):Float = 0;

	/** Gets the base's distance from the window's top edge. */
	public var baseY(default, null):Float = 0;

	/** Gets the knob's distance from the window's left edge. The knob is at the finger's position, held within the radius, and for a tilt
		stick at the base moved by `x` and `y` times the radius. While a stick read by fingers isn't held, the knob is at the base. */
	public var knobX(default, null):Float = 0;

	/** Gets the knob's distance from the window's top edge. */
	public var knobY(default, null):Float = 0;

	// Which side of the screen its default zone and its home are on; its zone this frame, its own or its default; and the finger that
	// lifted from it this frame, -1 for none.
	final right:Bool;
	final zone = new Bounds2D();
	var lifted = -1;

	function new(right:Bool) {
		this.right = right;
	}

	function get_held():Bool
		return finger >= 0;

	function set_enabled(value:Bool):Bool {
		if (!value)
			release();
		return enabled = value;
	}

	// Reads a tilt past the dead zone, or 0 without one, the base at its home and the knob pushed from it.
	function readTilt(source:Null<Tilt>):Void {
		release();
		var dx = source != null ? source.getAxis(X) : 0.,
			dy = source != null ? source.getAxis(Y) : 0.,
			length = Math.sqrt(dx * dx + dy * dy);
		var push = length > 0 ? Gamepads.beyond(length < 1 ? length : 1, deadZone) / length : 0;
		x = dx * push;
		y = dy * push;
		knobX = baseX + x * radius;
		knobY = baseY + y * radius;
	}

	function set_tilt(value:Bool):Bool {
		if (value)
			release();
		return tilt = value;
	}

	function set_deadZone(value:Float):Float
		return deadZone = value > 0 ? (value < 1 ? value : 1) : 0;

	// Lets go of its finger, at rest at its home: the fixed base, or one and a half radii in from its zone's bottom outer corner.
	function release():Void {
		if (finger >= 0)
			lifted = finger;
		finger = -1;
		x = y = 0;
		if (basePlacement == Fixed)
			placeFixed();
		else {
			baseX = right ? zone.maxX - radius * 1.5 : zone.minX + radius * 1.5;
			baseY = zone.maxY - radius * 1.5;
		}
		knobX = baseX;
		knobY = baseY;
	}

	// Takes a finger at a point. Landing, the base goes where its placement puts it; handed over, the knob stays where it was, the base
	// moving by as much as the finger is from the knob.
	function take(id:Int, atX:Float, atY:Float, handed:Bool):Void {
		finger = id;
		if (basePlacement == Fixed)
			placeFixed();
		else if (handed) {
			baseX += atX - knobX;
			baseY += atY - knobY;
		} else {
			baseX = atX;
			baseY = atY;
		}
		moveTo(atX, atY);
	}

	// Follows its finger to a point: the knob within the radius, the base pulled along when following, and the push past the dead zone.
	function moveTo(atX:Float, atY:Float):Void {
		var dx = atX - baseX,
			dy = atY - baseY,
			length = Math.sqrt(dx * dx + dy * dy);
		if (length > radius && radius > 0) {
			if (basePlacement == Following) {
				baseX = atX - dx / length * radius;
				baseY = atY - dy / length * radius;
			}
			dx *= radius / length;
			dy *= radius / length;
			length = radius;
		}
		knobX = baseX + dx;
		knobY = baseY + dy;
		var push = length > 0 ? Gamepads.beyond(length / radius, deadZone) / length : 0;
		x = dx * push;
		y = dy * push;
	}

	// Its zone this frame, from its own or from the window: a half with both sticks on the screen, else the whole window.
	function updateZone(width:Float, height:Float, alone:Bool):Void {
		var own = touchZone;
		if (own != null)
			zone.copyFrom(own);
		else
			zone.set(right && !alone ? width / 2 : 0, 0, !right && !alone ? width / 2 : width, height);
	}

	function placeFixed():Void {
		var fixed = fixedBasePosition;
		baseX = fixed != null ? fixed.x : zone.centerX;
		baseY = fixed != null ? fixed.y : zone.centerY;
	}
}
