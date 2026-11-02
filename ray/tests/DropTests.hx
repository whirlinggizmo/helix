import haxe.io.Bytes;
import helix.ray.Raylib.*;
import helix.ray.internal.MemoryFiles;
import helix.ray.internal.Runtime;

/** Checks helix-ray's dropped files, which a program naming `IsFileDropped` or `LoadDroppedFiles` links (docs/DECISIONS.md 15): the
	drop's reading is set as the program starts, so a drop before either is first called is read; a drop's files are listed under
	helix-ray's own paths, which the assets read; the next drop's replace them; `UnloadDroppedFiles` lets go of the list, the files staying;
	a dropped file that isn't text read by `LoadFileTextAsync` as raylib's `LoadFileText` reads it. On
	a window whose dropped files the test sets (services' `FakeWindow`), without events: a drop is given as `Runtime`'s poll gives one. */
@:access(helix.ray.internal.Runtime)
class DropTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function pump(done:Void->Bool) {
		for (_ in 0...10000) {
			if (done())
				return;
			Runtime.pollAll();
			var now = Runtime.waiting;
			Runtime.waiting = [];
			for (f in now)
				f();
		}
		throw "never answered";
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		check(Runtime.dropping != null, "naming IsFileDropped sets the drop's reading as the program starts");
		var window = new FakeWindow();
		Runtime.window = window;
		Runtime.memory = new MemoryFiles();
		Runtime.polled.push(Runtime.memory);
		Runtime.assets = new helix.services.assets.Assets({sources: [FileSystem(Runtime.memory)]});
		check(!IsFileDropped() && LoadDroppedFiles().count == 0, "nothing dropped yet");

		window.dropped.push({name: "level 1.txt", bytes: Bytes.ofString("one")});
		window.dropped.push({name: "art.png", bytes: Bytes.ofString("two")});
		Runtime.dropping(2);
		var first = LoadDroppedFiles();
		check(IsFileDropped()
			&& first.count == 2
			&& first.paths[0] == "helix-ray-dropped/1/level_1.txt"
			&& first.paths[1] == "helix-ray-dropped/2/art.png",
			'a drop listed under its own paths: ${first.paths}');
		var read:Bytes = null;
		Runtime.assets.load(first.paths[0], bytes -> read = bytes, e -> throw e);
		pump(() -> read != null);
		check(read.toString() == "one", "a dropped file's path reads it");

		UnloadDroppedFiles(first);
		check(!IsFileDropped(), "UnloadDroppedFiles lets go of the list");
		var again:Bytes = null;
		Runtime.assets.load(first.paths[1], bytes -> again = bytes, e -> throw e);
		pump(() -> again != null);
		check(again.toString() == "two", "and the files stay");

		window.dropped.resize(0);
		window.dropped.push({name: "", bytes: Bytes.ofString("three")});
		Runtime.dropping(1);
		var second = LoadDroppedFiles();
		check(second.count == 1 && second.paths[0] == "helix-ray-dropped/3/file", 'the next drop replaces it: ${second.paths}');
		var gone:Null<String> = null;
		Runtime.assets.load(first.paths[1], _ -> throw "the last drop's file still read", e -> gone = e);
		pump(() -> gone != null);
		check(gone != null, "the last drop's files are let go");

		// A dropped file that isn't text, read as text: as raylib's LoadFileText, up to its first NUL, never refused; what isn't UTF-8
		// (which a browser's Bytes.toString throws a RangeError for) read as U+FFFD.
		Runtime.saves = new helix.services.saves.Saves(Runtime.memory);
		window.dropped.resize(0);
		window.dropped.push({name: "noise.bin", bytes: Bytes.ofHex("61fffb9062006364")});
		Runtime.dropping(1);
		var text:Null<String> = null;
		LoadFileTextAsync(LoadDroppedFiles().paths[0], t -> text = t, e -> throw e);
		pump(() -> text != null);
		check(text == "a\u{FFFD}\u{FFFD}\u{FFFD}b", 'a binary file read as text: up to its NUL, U+FFFD for what isn\'t UTF-8: $text');

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
