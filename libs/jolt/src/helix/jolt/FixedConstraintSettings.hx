package helix.jolt;

/** Represents a constraint holding two bodies together, as if welded. */
class FixedConstraintSettings extends TwoBodyConstraintSettings<TwoBodyConstraint> {
	/** Gets or sets a value indicating whether the weld is where the bodies are when the constraint is made, the points and axes
		ignored. Defaults to false. */
	public var mAutoDetectPoint:Bool = false;

	/** Gets or sets the weld's point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the weld's point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Creates the settings. */
	public function new() {
		super();
		throw "not built yet";
	}
}
