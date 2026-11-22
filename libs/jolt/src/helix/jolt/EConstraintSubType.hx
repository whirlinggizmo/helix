package helix.jolt;

/** Specifies a constraint's kind. */
enum abstract EConstraintSubType(Int) {
	/** Made by `FixedConstraintSettings`. */
	var EConstraintSubType_Fixed = 0;

	/** Made by `PointConstraintSettings`. */
	var EConstraintSubType_Point = 1;

	/** Made by `HingeConstraintSettings`. */
	var EConstraintSubType_Hinge = 2;

	/** Made by `SliderConstraintSettings`. */
	var EConstraintSubType_Slider = 3;

	/** Made by `DistanceConstraintSettings`. */
	var EConstraintSubType_Distance = 4;

	/** Made by `ConeConstraintSettings`. */
	var EConstraintSubType_Cone = 5;

	/** A swing twist constraint, for a ragdoll's joints. */
	var EConstraintSubType_SwingTwist = 6;

	/** Made by `SixDOFConstraintSettings`. */
	var EConstraintSubType_SixDOF = 7;
}
