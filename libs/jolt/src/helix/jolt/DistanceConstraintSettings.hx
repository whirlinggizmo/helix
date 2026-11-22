package helix.jolt;

/** Represents a constraint keeping two points of two bodies within a range of distances: a rope, a rod, a spring. */
class DistanceConstraintSettings extends TwoBodyConstraintSettings<DistanceConstraint> {
	/** Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the shortest distance, in meters, or -1 for the distance when the constraint is made. Defaults to -1. */
	public var mMinDistance:Float = -1;

	/** Gets or sets the longest distance, in meters, or -1 for the distance when the constraint is made. Defaults to -1. */
	public var mMaxDistance:Float = -1;

	/** Gets or sets the spring at the distances' limits. Rigid by default. */
	public var mLimitsSpringSettings:SpringSettings;

	/** Creates the settings. */
	public function new() {
		super();
		throw "not built yet";
	}
}
