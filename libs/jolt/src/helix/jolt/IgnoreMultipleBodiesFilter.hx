package helix.jolt;

/** Represents every body but a list of them. */
class IgnoreMultipleBodiesFilter extends BodyFilter {
	/** Creates a filter that skips no body. */
	public function new() {
		super();
		kind = 2;
	}

	/** Skips a body.

		@param inBodyID  The body. */
	public function IgnoreBody(inBodyID:BodyID):Void {
		ids.push(inBodyID.GetIndexAndSequenceNumber());
	}

	/** Removes every body from the list, so the filter skips no body. */
	public function Clear():Void {
		ids.resize(0);
	}

	@:allow(helix.jolt) var ids:Array<Int> = [];
}
