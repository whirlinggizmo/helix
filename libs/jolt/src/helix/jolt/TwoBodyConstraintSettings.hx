package helix.jolt;

/** Represents what a constraint between two bodies is made from, passed to `BodyInterface.CreateConstraint`, which returns the
	constraint as `T`. */
class TwoBodyConstraintSettings<T:TwoBodyConstraint> extends ConstraintSettings {
	/** Gets or sets the space the points and axes are in. Defaults to `EConstraintSpace_WorldSpace`. */
	public var mSpace:EConstraintSpace = EConstraintSpace_WorldSpace;

	function new() {
		super();
	}
}
