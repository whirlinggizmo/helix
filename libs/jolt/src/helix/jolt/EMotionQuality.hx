package helix.jolt;

/** Specifies how a moving body's motion is tested for collisions. */
enum abstract EMotionQuality(Int) {
	/** Tested where the body is at each step, so a fast, thin body may pass through another. */
	var EMotionQuality_Discrete = 0;

	/** Cast along its motion each step, so a fast body stops at what it would pass through: a bullet. */
	var EMotionQuality_LinearCast = 1;
}
