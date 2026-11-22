package helix.jolt;

/** Represents a constraint holding a point of one body to a point of another, the bodies free to turn: a ball joint. */
class PointConstraintSettings extends TwoBodyConstraintSettings<TwoBodyConstraint> {
	/** Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Creates the settings. */
	public function new() {
		super();
		throw "not built yet";
	}
}
