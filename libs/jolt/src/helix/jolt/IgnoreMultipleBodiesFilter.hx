package helix.jolt;

/** Represents every body but a list of them. */
class IgnoreMultipleBodiesFilter extends BodyFilter {
	/** Creates a filter that skips no body. */
	public function new() {
		super();
		throw "not built yet";
	}

	/** Skips a body.

		@param inBodyID  The body. */
	public function IgnoreBody(inBodyID:BodyID):Void {
		throw "not built yet";
	}

	/** Removes every body from the list, so the filter skips no body. */
	public function Clear():Void {
		throw "not built yet";
	}
}
