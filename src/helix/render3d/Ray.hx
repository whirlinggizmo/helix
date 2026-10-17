package helix.render3d;

/** A ray in the world: where it starts and the way it goes (a unit vector). Camera3D.computeRay makes one through a pixel; Stage3D.pick follows
	one. */
class Ray {
	var ox = 0.;
	var oy = 0.;
	var oz = 0.;
	var dx = 0.;
	var dy = 0.;
	var dz = -1.;

	/** A ray from the origin down -z. */
	public function new() {}

	/** Where it starts, x. */
	public var originX(get, never):Float;

	function get_originX():Float
		return ox;

	/** Where it starts, y. */
	public var originY(get, never):Float;

	function get_originY():Float
		return oy;

	/** Where it starts, z. */
	public var originZ(get, never):Float;

	function get_originZ():Float
		return oz;

	/** The way it goes, x (a unit vector's). */
	public var directionX(get, never):Float;

	function get_directionX():Float
		return dx;

	/** The way it goes, y. */
	public var directionY(get, never):Float;

	function get_directionY():Float
		return dy;

	/** The way it goes, z. */
	public var directionZ(get, never):Float;

	function get_directionZ():Float
		return dz;

	/** Starts it at x, y, z going along dx, dy, dz (made a unit vector). False, changing nothing, for a direction of length 0 or one that isn't
		finite. */
	public function set(x:Float, y:Float, z:Float, dx:Float, dy:Float, dz:Float):Bool {
		var length = Math.sqrt(dx * dx + dy * dy + dz * dz);
		if (!(length > 0) || !Math.isFinite(length) || !Math.isFinite(x + y + z))
			return false;
		ox = x;
		oy = y;
		oz = z;
		this.dx = dx / length;
		this.dy = dy / length;
		this.dz = dz / length;
		return true;
	}

	/** The point distance along it, axis 0 (x), 1 (y) or 2 (z). */
	public function at(distance:Float, axis:Int):Float
		return axis == 0 ? ox + dx * distance : axis == 1 ? oy + dy * distance : oz + dz * distance;
}
