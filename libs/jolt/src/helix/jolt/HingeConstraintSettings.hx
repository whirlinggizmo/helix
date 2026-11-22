package helix.jolt;

/** Represents a constraint letting two bodies turn about one axis: a door, a wheel. */
class HingeConstraintSettings extends TwoBodyConstraintSettings<HingeConstraint> {
	/** Gets or sets the hinge's point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the hinge's axis on the first body. Defaults to (0, 1, 0). */
	public var mHingeAxis1:Vec3;

	/** Gets or sets an axis at right angles to the hinge's on the first body, from which the angle is measured. Defaults to (1, 0, 0). */
	public var mNormalAxis1:Vec3;

	/** Gets or sets the hinge's point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the hinge's axis on the second body. Defaults to (0, 1, 0). */
	public var mHingeAxis2:Vec3;

	/** Gets or sets an axis at right angles to the hinge's on the second body. Defaults to (1, 0, 0). */
	public var mNormalAxis2:Vec3;

	/** Gets or sets the smallest angle, in radians, -pi to 0. Defaults to -pi: no limit. */
	public var mLimitsMin:Float = -Math.PI;

	/** Gets or sets the largest angle, in radians, 0 to pi. Defaults to pi: no limit. */
	public var mLimitsMax:Float = Math.PI;

	/** Gets or sets the spring at the angles' limits. Rigid by default. */
	public var mLimitsSpringSettings:SpringSettings;

	/** Gets or sets the friction torque that slows the hinge, in newton meters. Defaults to 0. */
	public var mMaxFrictionTorque:Float = 0;

	/** Gets or sets the motor: by default with no force limit, and off until the constraint's `SetMotorState`. */
	public var mMotorSettings:MotorSettings;

	/** Creates the settings. */
	public function new() {
		super();
		throw "not built yet";
	}
}
