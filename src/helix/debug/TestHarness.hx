package helix.debug;

/** Where results go for the check that launched the program (an autopilot's final state, a test's checks). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from ITestHarness's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.debug.ITestHarness))
class TestHarness {
	/** The harness forwarded to: the profile's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):ITestHarness;
}
