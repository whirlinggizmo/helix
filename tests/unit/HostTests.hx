import helix.core.Jobs;
import helix.host.FrameClock;
import helix.host.Identity;

class HostTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	public static function main():Void {
		check(Identity.cleanName("My Game") == "My Game", "A plain name is kept");
		check(Identity.cleanName("a/b:c*d") == "a_b_c_d", "Characters no file system takes become _");
		check(Identity.cleanName("  .hidden. ") == "hidden", "Leading and trailing dots and spaces go");
		check(Identity.cleanName("con") == "_con" && Identity.cleanName("COM3.txt") == "_COM3.txt" && Identity.cleanName("COM0") == "COM0",
			"Windows device names");
		check(Identity.cleanName(" . ") == null && Identity.cleanName([for (_ in 0...128) "x"].join("")) == null, "Refused, never cut");
		var identity = new Identity("blocks", "HeliX");
		check(identity.getCompany() == "HeliX" && identity.getProduct() == "blocks", "Identity keeps its names");
		var threw = try {
			new Identity("...");
			false;
		} catch (_:Dynamic)
			true;
		check(threw, "An identity that cleans to nothing throws");
		var cache = helix.adapters.store.filesystem.FileSystemStoreAdapter.getCacheDirectory(identity.getCompany(), identity.getProduct());
		// Windows' is the program's own folder under %LOCALAPPDATA%, its cache inside it.
		var ending = Sys.systemName() == "Windows" ? "HeliX/blocks/cache" : "HeliX/blocks";
		check(cache != null && StringTools.endsWith(cache, ending), "A cache directory under the user's");
		var clock = new FrameClock();
		clock.frame(10);
		check(Math.abs(clock.getDelta() - 1 / 60) < 1e-12 && clock.getElapsed() == 0, "The first frame: 1/60 and nothing elapsed");
		clock.frame(10.25);
		check(clock.getDelta() == FrameClock.MAX_DELTA
			&& Math.abs(clock.getElapsed() - .25) < 1e-12, "A stall: the delta held, the elapsed time whole");
		clock.frame(10.25);
		check(clock.getDelta() == FrameClock.MIN_DELTA && clock.getElapsed() == 0, "No time passed: the least delta");
		// The job pool: a cap, completion at a later poll, and every operation, queued or running, completing once at shutdown.
		var jobs = new Jobs(1), results:Array<String> = [], aborted = false;
		jobs.add(job -> job.setAbort(() -> aborted = true), r -> results.push("a:" + r), "cancelled");
		jobs.add(job -> job.finish("done"), r -> results.push("b:" + r), "cancelled");
		jobs.poll();
		check(results.length == 0 && jobs.getRunning().length == 1, "One at a time; nothing completes during the call");
		jobs.shutdown();
		check(results.join(",") == "a:cancelled,b:cancelled"
			&& aborted, "Shutdown completes the running and the queued, aborting the running");
		jobs.add(_ -> {}, r -> results.push("c:" + r), "cancelled", "refused");
		jobs.poll();
		check(results[2] == "c:refused", "Refused once shut down");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
