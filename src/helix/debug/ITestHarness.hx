package helix.debug;

/** How a program hands its result to the check that launched it (an autopilot's final state, a test's checks). A test hook only: a game's
	profile can plug in one that does nothing. */
interface ITestHarness {
	/** Hands value (JSON-able) to the check: window.result in a browser; natively a JSON line on stdout, also written to the file
		HELIX_RESULT names. */
	public function publish(value:Dynamic):Void;
}
