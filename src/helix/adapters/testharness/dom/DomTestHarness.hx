package helix.adapters.testharness.dom;

import helix.debug.ITestHarness;

/** The browser's test harness: a published result is window.result, which a check's headless browser reads. */
class DomTestHarness implements ITestHarness {
	/** The page's harness. */
	public function new() {}

	public function publish(value:Dynamic):Void
		js.Syntax.code("window.result={0}", value);
}
