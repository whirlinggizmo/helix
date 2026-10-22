package helix.math;

/** A point in 3D, x, y, z, in whatever space its maker says: what a computation of a point returns (Camera3D.project, Ray3D.pointAt),
	into one given for reuse. Its 3D is its dimensions, as Bounds3D's is, not the display kind (docs/CONVENTIONS.md). */
class Point3D {
	/** Its x. */
	public var x:Float;

	/** Its y. */
	public var y:Float;

	/** Its z. */
	public var z:Float;

	/** The point x, y, z, 0 for each not given. */
	public function new(x = 0., y = 0., z = 0.) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/** Sets it to x, y, z; returns it. */
	public function set(x:Float, y:Float, z:Float):Point3D {
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	/** Sets it to other's; returns it. */
	public function copyFrom(other:Point3D):Point3D {
		x = other.x;
		y = other.y;
		z = other.z;
		return this;
	}
}
