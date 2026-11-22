package helix.jolt;

/** Represents a constraint letting two bodies move apart along one axis, without turning: a drawer, a piston. */
class SliderConstraintSettings extends TwoBodyConstraintSettings<SliderConstraint> {
	/** Gets or sets a value indicating whether the point is where the bodies are when the constraint is made. Defaults to false. */
	public var mAutoDetectPoint:Bool = false;

	/** Gets or sets the slider's point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the slider's axis on the first body. Defaults to (1, 0, 0). */
	public var mSliderAxis1:Vec3;

	/** Gets or sets an axis at right angles to the slider's on the first body. Defaults to (0, 1, 0). */
	public var mNormalAxis1:Vec3;

	/** Gets or sets the slider's point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the slider's axis on the second body. Defaults to (1, 0, 0). */
	public var mSliderAxis2:Vec3;

	/** Gets or sets an axis at right angles to the slider's on the second body. Defaults to (0, 1, 0). */
	public var mNormalAxis2:Vec3;

	/** Gets or sets the lowest position, in meters. Defaults to minus the largest float: no limit. */
	public var mLimitsMin:Float = -3.4028234663852886e38;

	/** Gets or sets the highest position, in meters. Defaults to the largest float: no limit. */
	public var mLimitsMax:Float = 3.4028234663852886e38;

	/** Gets or sets the spring at the positions' limits. Rigid by default. */
	public var mLimitsSpringSettings:SpringSettings;

	/** Gets or sets the friction force that slows the slider, in newtons. Defaults to 0. */
	public var mMaxFrictionForce:Float = 0;

	/** Gets or sets the motor: by default with no force limit, and off until the constraint's `SetMotorState`. */
	public var mMotorSettings:MotorSettings;

	/** Creates the settings. */
	public function new() {
		super();
		throw "not built yet";
	}
}
