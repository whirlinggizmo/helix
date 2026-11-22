package helix.jolt;

/** Represents a constraint holding a point of one body to another, the second body's axis kept within a cone about the first's: a
	shoulder. */
class ConeConstraintSettings extends TwoBodyConstraintSettings<ConeConstraint> {
	/** Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the cone's axis on the first body. Defaults to (1, 0, 0). */
	public var mTwistAxis1:Vec3;

	/** Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the axis on the second body kept in the cone. Defaults to (1, 0, 0). */
	public var mTwistAxis2:Vec3;

	/** Gets or sets half the cone's angle, in radians, 0 to pi. Defaults to 0. */
	public var mHalfConeAngle:Float = 0;

	/** Creates the settings. */
	public function new() {
		super();
		throw "not built yet";
	}
}
