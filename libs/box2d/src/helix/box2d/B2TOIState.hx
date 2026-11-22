package helix.box2d;

/** The result of a time of impact computation, `B2TOIOutput.state`. */
enum abstract B2TOIState(Int) to Int {
	/** The computation didn't finish or hasn't run. */
	var b2_toiStateUnknown = 0;

	/** The root finder failed, and the fraction is the last time known to be safe. */
	var b2_toiStateFailed = 1;

	/** The shapes already overlap at the start of the sweep, and the fraction is 0. */
	var b2_toiStateOverlapped = 2;

	/** The shapes come within the target separation, and the fraction is when. */
	var b2_toiStateHit = 3;

	/** The shapes stay separated for the whole sweep, and the fraction is the sweep's end. */
	var b2_toiStateSeparated = 4;
}
