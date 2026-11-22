package helix.jolt;

/** Represents what a convex hull is built from: the smallest convex shape around a set of points. */
class ConvexHullShapeSettings extends ConvexShapeSettings {
	/** Gets or sets the points, in meters. */
	public var mPoints:Array<Vec3> = [];

	/** Gets or sets the most the hull's edges are rounded, in meters. Defaults to 0.05. */
	public var mMaxConvexRadius:Float = 0.05;

	/** Gets or sets how far a point may be from the hull built, in meters. Defaults to 0.001. */
	public var mHullTolerance:Float = 0.001;

	/** Creates the settings with no points. */
	public function new() {
		super();
	}
}
