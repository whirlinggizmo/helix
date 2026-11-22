package helix.jolt;

/** Specifies a constraint's family. */
enum abstract EConstraintType(Int) {
	/** A constraint on one body. */
	var EConstraintType_Constraint = 0;

	/** A constraint between two bodies. */
	var EConstraintType_TwoBodyConstraint = 1;
}
