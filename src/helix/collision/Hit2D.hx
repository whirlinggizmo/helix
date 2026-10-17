package helix.collision;

/** What a 2D test found (Collide2D): where along a ray or a sweep (time, 0 at its start to 1 at its end), the point there, the surface's
	normal (a unit vector out of what was hit; 0, 0 when the test started inside), and how deep an overlap goes along that normal. One is kept
	and filled again, not made a test. */
class Hit2D {
	/** How far along the ray or sweep, 0 to 1. */
	public var time = 0.;

	/** The hit's x. */
	public var x = 0.;

	/** The hit's y. */
	public var y = 0.;

	/** The normal's x, out of what was hit. */
	public var normalX = 0.;

	/** The normal's y. */
	public var normalY = 0.;

	/** How deep an overlap goes along the normal (the least move apart); 0 for a ray or sweep that stops short. */
	public var depth = 0.;

	/** Nothing found yet. */
	public function new() {}

	/** Clears it. */
	public function reset():Void {
		time = 0;
		x = 0;
		y = 0;
		normalX = 0;
		normalY = 0;
		depth = 0;
	}
}
