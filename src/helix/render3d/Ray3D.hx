package helix.render3d;

/** A ray in the world: where it starts and the way it goes (a unit vector). Camera3D.computeRay makes one through a pixel; Renderer3D.pick follows
	one. */
class Ray3D {
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

	/** The point distance along it, into out (a new one when not given), returned. Given out, it allocates nothing. */
	public function pointAt(distance:Float, ?out:helix.math.Point3D):helix.math.Point3D
		return (out != null ? out : new helix.math.Point3D()).set(ox + dx * distance, oy + dy * distance, oz + dz * distance);

	/** How far along it it meets the plane of points p where nx * p.x + ny * p.y + nz * p.z = d (the normal nx, ny, nz, any length), from
		its origin on: NaN when it runs along the plane or away from it (the plane behind it). With pointAt, where on the ground a click
		landed, where nothing was there to pick. */
	public function hitPlane(nx:Float, ny:Float, nz:Float, d:Float):Float {
		var across = nx * dx + ny * dy + nz * dz;
		if (Math.abs(across) < 1e-12)
			return Math.NaN;
		var distance = (d - (nx * ox + ny * oy + nz * oz)) / across;
		return distance >= 0 ? distance : Math.NaN;
	}

	/** How far along it it reaches the height y (the plane y = y, the ground at 0): hitPlane(0, 1, 0, y). NaN when it never does. */
	public function hitHeight(y:Float):Float
		return hitPlane(0, 1, 0, y);
}
