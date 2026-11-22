package helix.jolt;

/** Specifies how a spring's strength is set. */
enum abstract ESpringMode(Int) {
	/** By `SpringSettings.mFrequency` and `mDamping`. */
	var ESpringMode_FrequencyAndDamping = 0;

	/** By `SpringSettings.mStiffness` and `mDamping`. */
	var ESpringMode_StiffnessAndDamping = 1;

	/** By `SpringSettings.mStiffness` divided by the mass, and `mDamping`. */
	var ESpringMode_MassNormalizedStiffnessAndDamping = 2;
}
