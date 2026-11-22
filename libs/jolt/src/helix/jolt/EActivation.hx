package helix.jolt;

/** Specifies whether a call wakes a body. */
enum abstract EActivation(Int) {
	/** Wakes the body. */
	var EActivation_Activate = 0;

	/** Leaves the body asleep or awake as it is. */
	var EActivation_DontActivate = 1;
}
