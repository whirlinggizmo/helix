package helix.render3d;

/** The shape a node is picked by in place of what it draws (Node3D.hitArea), in the node's own units, moving, turning and scaling with it;
	never drawn. For something clicked but not seen (a bare Node3D with one), a thin model easier to hit (a door), or one tighter than its
	triangles. */
class HitArea3D {
	final round:Bool;
	final x:Float;
	final y:Float;
	final z:Float;
	final halfWidth:Float;
	final halfHeight:Float;
	final halfDepth:Float;

	function new(round:Bool, x:Float, y:Float, z:Float, halfWidth:Float, halfHeight:Float, halfDepth:Float) {
		this.round = round;
		this.x = x;
		this.y = y;
		this.z = z;
		this.halfWidth = halfWidth > 0 ? halfWidth : 0;
		this.halfHeight = halfHeight > 0 ? halfHeight : 0;
		this.halfDepth = halfDepth > 0 ? halfDepth : 0;
	}

	/** A box width x height x depth (below 0 is 0) centered on x, y, z. */
	public static function box(x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float):HitArea3D
		return new HitArea3D(false, x, y, z, width / 2, height / 2, depth / 2);

	/** A sphere of radius (below 0 is 0) centered on x, y, z. */
	public static function sphere(x:Float, y:Float, z:Float, radius:Float):HitArea3D
		return new HitArea3D(true, x, y, z, radius, radius, radius);

	// Where the ray from ox, oy, oz along dx, dy, dz (its node's own space) enters it, in steps of the direction: 0 when it starts inside,
	// infinity when it misses. The normal where it enters, in its node's space (not a unit vector), into normal.

	@:allow(helix.render3d.Renderer3D)
	function enter(ox:Float, oy:Float, oz:Float, dx:Float, dy:Float, dz:Float, normal:Array<Float>):Float {
		var sx = ox - x, sy = oy - y, sz = oz - z;
		if (round) {
			var a = dx * dx + dy * dy + dz * dz,
				b = sx * dx + sy * dy + sz * dz,
				c = sx * sx + sy * sy + sz * sz - halfWidth * halfWidth;
			if (c <= 0) {
				normal[0] = -dx;
				normal[1] = -dy;
				normal[2] = -dz;
				return 0;
			}
			var d = b * b - a * c;
			if (a <= 0 || d < 0 || b > 0)
				return Math.POSITIVE_INFINITY;
			var t = (-b - Math.sqrt(d)) / a;
			normal[0] = sx + dx * t;
			normal[1] = sy + dy * t;
			normal[2] = sz + dz * t;
			return t;
		}
		var lo = 0., hi = Math.POSITIVE_INFINITY, axisIn = -1, signIn = 0.;
		for (axis in 0...3) {
			var o = axis == 0 ? sx : axis == 1 ? sy : sz,
				d = axis == 0 ? dx : axis == 1 ? dy : dz,
				reach = axis == 0 ? halfWidth : axis == 1 ? halfHeight : halfDepth;
			if (Math.abs(d) < 1e-12) {
				if (o < -reach || o > reach)
					return Math.POSITIVE_INFINITY;
				continue;
			}
			var a = (-reach - o) / d, b = (reach - o) / d, sign = -1.;
			if (a > b) {
				var t = a;
				a = b;
				b = t;
				sign = 1;
			}
			if (a > lo) {
				lo = a;
				axisIn = axis;
				signIn = sign;
			}
			if (b < hi)
				hi = b;
			if (lo > hi)
				return Math.POSITIVE_INFINITY;
		}
		for (axis in 0...3)
			normal[axis] = axis == axisIn ? signIn : 0;
		if (axisIn < 0) {
			normal[0] = -dx;
			normal[1] = -dy;
			normal[2] = -dz;
		}
		return lo;
	}
}
