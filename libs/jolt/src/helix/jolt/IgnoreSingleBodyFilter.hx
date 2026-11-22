package helix.jolt;

/** Represents every body but one: a ray cast from a body that skips the body casting it. */
class IgnoreSingleBodyFilter extends BodyFilter {
	/** Creates the filter.

		@param inBodyID  The body skipped. */
	public function new(inBodyID:BodyID) {
		super();
		kind = 1;
		value = inBodyID.GetIndexAndSequenceNumber();
	}
}
