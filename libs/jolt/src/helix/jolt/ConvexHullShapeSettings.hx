package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

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

	override function make():Int {
		var base = Io.bulk(mPoints.length * 12);
		for (n in 0...mPoints.length) {
			Io.setBulkF(base, n * 3, mPoints[n].x);
			Io.setBulkF(base, n * 3 + 1, mPoints[n].y);
			Io.setBulkF(base, n * 3 + 2, mPoints[n].z);
		}
		return Hj.shapeConvexHull(mPoints.length, mMaxConvexRadius, mHullTolerance, mDensity, mUserData);
	}
}
