import haxe.io.Bytes;
import helix.services.saves.Saves;

/** Checks Saves over a fake file system: a missing file loading as no values, values read and set by kind, a frame's changes written once
	at the poll, flush answered by the write that keeps what's set, a failed write retried only after a change, a file that isn't saves
	failing, reads before load throwing, and what is set or deleted before load held and made after the read, winning over the file. */
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
		check(throws(() -> saves.getInt("a", 0)), "before load: reads throw");
		var loads = 0;
		saves.load(() -> loads++);
		files.poll();
		check(loads == 1 && saves.loaded && !saves.hasKey("a"), "no file: loaded, no values");
		saves.load(() -> loads++);
		check(loads == 1, "a second load isn't answered during the call");
		saves.poll();
		check(loads == 2, "a second load once loaded: answered at the next poll");
		var both = new Saves(files), answers = 0;
		both.load(() -> answers++);
		both.load(() -> answers++);
		files.poll();
		check(answers == 2, "two loads at once: both answered by the one read");

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
		again.deleteKey("name");
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
		check(again.getKeys().join(",") == "level,sound,x", 'getKeys: every key, sorted: ${again.getKeys()}');

		again.deleteKeys();
		again.poll();
		files.poll();
		var cleared = new Saves(files);
		cleared.load(() -> {});
		files.poll();
		check(!cleared.hasKey("level") && !cleared.hasKey("sound") && cleared.getKeys().length == 0, "deleteKeys: none kept");

		files.files.set("bad.json", Bytes.ofString("not json"));
		var bad = new Saves(files, "bad.json");
		var why = null;
		bad.load(() -> {}, message -> why = message);
		files.poll();
		check(why != null && !bad.loaded, "a file that isn't saves fails");
		for (json in ["[1, 2]", "[]", '"text"', "3", "1.5", "true", "null"]) {
			files.files.set("shape.json", Bytes.ofString(json));
			var other = new Saves(files, "shape.json"), refused = null;
			other.load(() -> {}, message -> refused = message);
			files.poll();
			check(refused != null && !other.loaded, 'JSON that isn\'t an object fails: $json');
		}
		files.files.set("empty.json", Bytes.ofString("{}"));
		var empty = new Saves(files, "empty.json");
		empty.load(() -> {});
		files.poll();
		check(empty.loaded, "an empty object is saves");

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
		// Set and deleted before the read: held, made after it, over what the file kept, and written.
		files = new FakeFileSystem();
		var first = new Saves(files);
		first.load(() -> {});
		files.poll();
		first.setString("name", "Ada");
		first.setInt("level", 3);
		first.setBool("sound", false);
		first.poll();
		files.poll();
		var early = new Saves(files), writes = files.writes;
		early.setInt("level", 9);
		early.deleteKey("sound");
		early.setString("fresh", "yes");
		check(!early.pending && files.writes == writes, "before load: held, nothing pending");
		early.load(() -> {});
		files.poll();
		check(early.getInt("level", 0) == 9
			&& !early.hasKey("sound")
			&& early.getString("name", "") == "Ada"
			&& early.getString("fresh", "") == "yes",
			"held changes made after the read, over the file's values, the rest kept");
		check(early.pending, "the held changes are pending, to be written");
		early.poll();
		files.poll();
		var after = new Saves(files);
		after.load(() -> {});
		files.poll();
		check(after.getInt("level", 0) == 9 && !after.hasKey("sound"), "and written");
		var cleared = new Saves(files);
		cleared.setInt("kept", 1);
		cleared.deleteKeys();
		cleared.setInt("after", 2);
		cleared.load(() -> {});
		files.poll();
		check(!cleared.hasKey("kept") && !cleared.hasKey("name") && cleared.getInt("after", 0) == 2, "held in order: a reset, then a set");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
