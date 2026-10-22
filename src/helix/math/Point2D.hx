package helix.math;

/** A point in 2D, x, y, in whatever space its maker says: what a computation of a point returns (Camera3D.project, Ray3D.pointAt),
	into one given for reuse. Its 2D is its dimensions, as Bounds2D's is, not the display kind (docs/CONVENTIONS.md). */
class Point2D {
	/** Its x. */
	public var x:Float;

	/** Its y. */
	public var y:Float;

	/** The point x, y, 0 for each not given. */
	public function new(x = 0., y = 0.) {
		this.x = x;
		this.y = y;
	}

	/** Sets it to x, y; returns it. */
	public function set(x:Float, y:Float):Point2D {
		this.x = x;
		this.y = y;
		return this;
	}

	/** Sets it to other's; returns it. */
	public function copyFrom(other:Point2D):Point2D {
		x = other.x;
		y = other.y;
		return this;
	}
}
