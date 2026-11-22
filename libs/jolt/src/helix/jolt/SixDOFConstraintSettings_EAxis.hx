package helix.jolt;

/** Specifies one of a six degrees of freedom constraint's axes. */
enum abstract SixDOFConstraintSettings_EAxis(Int) {
	/** Moving along x. */
	var SixDOFConstraintSettings_EAxis_TranslationX = 0;

	/** Moving along y. */
	var SixDOFConstraintSettings_EAxis_TranslationY = 1;

	/** Moving along z. */
	var SixDOFConstraintSettings_EAxis_TranslationZ = 2;

	/** Turning about x. */
	var SixDOFConstraintSettings_EAxis_RotationX = 3;

	/** Turning about y. */
	var SixDOFConstraintSettings_EAxis_RotationY = 4;

	/** Turning about z. */
	var SixDOFConstraintSettings_EAxis_RotationZ = 5;
}
