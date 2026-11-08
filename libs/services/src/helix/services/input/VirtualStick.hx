package helix.services.input;

import helix.math.Bounds2D;
import helix.math.Vector2D;

/** Represents one stick of a `VirtualGamepad`: its settings, and where a finger holds it.

	A finger landing in the stick's touch zone takes the stick, even from the finger holding it. A finger holding the other stick keeps
	the other stick. Where the two zones overlap, a landing finger takes the free stick, or the left stick if both are free. When the
	finger holding the stick lifts, a finger still down in the stick's zone takes the stick, without moving the knob.

	The stick lets go when the window changes size, when the stick is turned off, and when a physical gamepad replaces the virtual
	gamepad. A finger landing takes the stick again. Positions and sizes are framebuffer pixels. */
@:allow(helix.services.input.VirtualGamepad)
class VirtualStick {
	/** Gets or sets whether it's on the screen. Turned off, the stick lets go of its finger. */
	public var enabled(default, set):Bool = true;

	/** Gets or sets where a finger can land to take it. The zone follows changes to these bounds' fields. Null for its default: the
		window's left or right half with both sticks enabled, and the whole window with one, following the window's size. */
	public var touchZone:Null<Bounds2D> = null;

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

	/** Gets a value indicating whether a finger holds it. */
	public var held(get, never):Bool;

	/** Gets the id of the finger holding it, as `Touch` knows the finger. -1 while not held. */
	public var finger(default, null):Int = -1;

	/** Gets where it's pushed across, -1 (left) to 1 (right), within a circle of radius 1. 0 while not held. */
	public var x(default, null):Float = 0;

	/** Gets where it's pushed up and down, -1 (up) to 1 (down), within a circle of radius 1. 0 while not held. */
	public var y(default, null):Float = 0;

	/** Gets the base's distance from the window's left edge. While not held, it's the stick's home: the fixed base, or centered one and a
		half radii in from the touch zone's bottom outer corner. */
	public var baseX(default, null):Float = 0;

	/** Gets the base's distance from the window's top edge. */
	public var baseY(default, null):Float = 0;

	/** Gets the knob's distance from the window's left edge. It's the finger's position, held within the radius. While not held, it's
		the base's position. */
	public var knobX(default, null):Float = 0;

	/** Gets the knob's distance from the window's top edge. */
	public var knobY(default, null):Float = 0;

	// Which side of the screen its default zone and its home are on.
	final right:Bool;
	// Its zone this frame: its own, or its default.
	final zone = new Bounds2D();

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

	function set_deadZone(value:Float):Float
		return deadZone = value > 0 ? (value < 1 ? value : 1) : 0;

	// Lets go of its finger, and rests at its home.
	function release():Void {
		finger = -1;
		x = y = 0;
		knobX = baseX;
		knobY = baseY;
	}

	// Takes a finger at a point, its base where its placement puts it.
	function take(id:Int, atX:Float, atY:Float):Void {
		finger = id;
		if (basePlacement == Fixed)
			placeFixed();
		else {
			baseX = atX;
			baseY = atY;
		}
		moveTo(atX, atY);
	}

	// Takes a finger still down when its own lifts, the knob where it was: the base moves by as much as the finger is from the knob.
	function handTo(id:Int, atX:Float, atY:Float):Void {
		finger = id;
		if (basePlacement == Fixed)
			placeFixed();
		else {
			baseX += atX - knobX;
			baseY += atY - knobY;
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
		var push = radius > 0 ? length / radius : 0,
			dead = deadZone < .95 ? deadZone : .95;
		if (push <= dead || length == 0) {
			x = y = 0;
			return;
		}
		var scaled = (push - dead) / (1 - dead);
		x = dx / length * scaled;
		y = dy / length * scaled;
	}

	// Its zone this frame, from its own or from the window: a half with both sticks on the screen, else the whole window.
	function updateZone(width:Float, height:Float, alone:Bool):Void {
		var own = touchZone;
		if (own != null)
			zone.copyFrom(own);
		else if (alone)
			zone.set(0, 0, width, height);
		else if (right)
			zone.set(width / 2, 0, width, height);
		else
			zone.set(0, 0, width / 2, height);
	}

	// Rests at its home while not held: the fixed base, or one and a half radii in from its zone's bottom outer corner.
	function rest():Void {
		if (basePlacement == Fixed)
			placeFixed();
		else {
			baseX = right ? zone.maxX - radius * 1.5 : zone.minX + radius * 1.5;
			baseY = zone.maxY - radius * 1.5;
		}
		knobX = baseX;
		knobY = baseY;
	}

	function placeFixed():Void {
		var fixed = fixedBasePosition;
		baseX = fixed != null ? fixed.x : zone.centerX;
		baseY = fixed != null ? fixed.y : zone.centerY;
	}
}
