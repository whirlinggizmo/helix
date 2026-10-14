package helix.adapters.testharness.stdio;

import helix.debug.ITestHarness;

/** The native test harness: a published result is a JSON line on stdout, also written to the file HELIX_RESULT names. */
class StdioTestHarness implements ITestHarness {
	/** The process's harness. */
	public function new() {}

	public function publish(value:Dynamic):Void {
		var json = haxe.Json.stringify(value);
		Sys.println(json);
		var path = Sys.getEnv("HELIX_RESULT");
		if (path != null)
			sys.io.File.saveContent(path, json + "\n");
	}
}
