package helix.jolt;

/** Specifies the space a constraint's points and axes are in. */
enum abstract EConstraintSpace(Int) {
	/** Each body's own, from its center of mass. */
	var EConstraintSpace_LocalToBodyCOM = 0;

	/** The world's, as the bodies are placed when the constraint is made. */
	var EConstraintSpace_WorldSpace = 1;
}
