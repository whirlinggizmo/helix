import haxe.io.Bytes;
import helix.services.saves.Saves;

/** Checks Saves over a fake file system: a missing file loading as no values, values read and set by kind, a frame's changes written once
	at the poll, flush answered by the write that keeps what's set, a failed write retried only after a change, a file that isn't saves
	failing, and reads and sets before load throwing. */
class SavesTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function throws(f:Void->Void):Bool
		return try {
			f();
			false;
		} catch (_:String)
			true;

	static function main():Void {
		var files = new FakeFileSystem();
		var saves = new Saves(files);
		check(throws(() -> saves.setInt("a", 1)) && throws(() -> saves.getInt("a", 0)), "before load: reads and sets throw");
		var loads = 0;
		saves.load(() -> loads++);
		files.poll();
		check(loads == 1 && saves.loaded && !saves.has("a"), "no file: loaded, no values");

		saves.setString("name", "Ada");
		saves.setInt("level", 3);
		saves.setFloat("x", 1.5);
		saves.setBool("sound", false);
		check(saves.pending && files.writes == 0, "set: pending, not written yet");
		saves.poll();
		check(files.writes == 1 && saves.pending, "the poll writes the frame's changes as one file");
		saves.poll();
		check(files.writes == 1, "one write at a time");
		files.poll();
		check(!saves.pending, "written: nothing pending");

		var again = new Saves(files);
		again.load(() -> {});
		files.poll();
		check(again.getString("name", "") == "Ada"
			&& again.getInt("level", 0) == 3
			&& again.getFloat("x", 0) == 1.5
			&& !again.getBool("sound", true),
			"loaded back by kind");
		check(again.getInt("name", -1) == -1 && again.getBool("level", true) && again.getFloat("name", 2) == 2, "the wrong kind: the fallback");
		check(again.getFloat("level", 0) == 3, "a whole number reads as a number");
		check(throws(() -> again.setFloat("x", Math.NaN)), "a value that isn't finite is refused");

		var flushed = 0;
		again.setInt("level", 4);
		again.flush(() -> flushed++);
		check(files.writes == 2, "flush writes at once");
		again.setInt("level", 5);
		again.flush(() -> flushed++);
		files.poll();
		check(flushed == 1 && files.writes == 3, "a flush during a write waits for the write after, started when the first ends");
		files.poll();
		check(flushed == 2 && !again.pending, "and is answered by it");
		again.flush(() -> flushed++);
		check(flushed == 2, "nothing pending: answered at the next poll, not during the call");
		again.poll();
		check(flushed == 3 && files.writes == 3, "answered then, nothing written");

		var failures = [];
		files.failWrites = true;
		again.remove("name");
		again.flush(() -> {}, message -> failures.push(message));
		files.poll();
		check(failures.length == 1 && again.pending, "a failed write: failed called, still pending");
		var before = files.writes;
		again.poll();
		check(files.writes == before, "not retried every frame");
		files.failWrites = false;
		again.setBool("sound", true);
		again.poll();
		files.poll();
		check(!again.pending && files.writes == before + 1, "retried after a change");

		again.clearValues();
		again.poll();
		files.poll();
		var cleared = new Saves(files);
		cleared.load(() -> {});
		files.poll();
		check(!cleared.has("level") && !cleared.has("sound"), "clearValues: none kept");

		files.files.set("bad.json", Bytes.ofString("not json"));
		var bad = new Saves(files, "bad.json");
		var why = null;
		bad.load(() -> {}, message -> why = message);
		files.poll();
		check(why != null && !bad.loaded, "a file that isn't saves fails");

		files.failReads = true;
		var unread = new Saves(files, "other.json");
		var readFailure = null;
		unread.load(() -> {}, message -> readFailure = message);
		files.poll();
		check(readFailure == "read failed" && !unread.loaded, "a read that fails fails the load");
		files.failReads = false;

		var gone = new Saves(files);
		gone.load(() -> {});
		files.poll();
		gone.setInt("a", 1);
		var answered = false;
		gone.flush(() -> answered = true);
		gone.dispose();
		files.poll();
		check(!answered && files.files.exists("saves.json"), "disposed after a flush: the write finishes, nothing is called");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
