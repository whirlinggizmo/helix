import helix.raylib.Raylib.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.services.saves.Saves;
import helix.services.screen.Screen;
import helix.services.time.Time;

/** Checks the calls a page waits for (helix-raylib's Wait), written as raylib's programs write them: a loop calling `EndDrawing()` in a
	function of its own, one frame an iteration, with `continue` and `break`, a `do`-`while`, and loops over a range and an array; the clipboard written, then read; a compiled shader loaded; `WaitTime`; a frame ended in a function the loop
	calls; a load in a function returning its value, used as a statement, a value, an argument and in a string; functions calling each
	other; a method of an object, and one overriding it that calls it; a `throw` after a wait caught by the caller; and a function reaching no wait, which returns its value at
	once, as do functions calling each other that reach none. In a page the frames come from the test's own timer and a function that waits returns at its first wait; natively each call
	returns when it is done. On graphics, a window and files of the test's own. */
@:access(helix.raylib.internal.Runtime)
class WaitTests {
	public static var checks = 0;

	public static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function report(_:Int):Void {
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		// No key ends the program, which has no keyboard.
		Runtime.exitKey = 0;
		Runtime.system = new FakeSystem();
		Runtime.time = new Time(Runtime.system);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var window = new FakeWindow();
		Runtime.window = window;
		Runtime.events = new FakeEvents();
		Runtime.screen = new Screen(window, Runtime.events);
		var files = new FakeFileSystem();
		Runtime.polled.push(files);
		Runtime.saves = new Saves(files);
		Runtime.polled.push(Runtime.saves);
		var shipped = new FakeFileSystem();
		shipped.write("glow.shader", haxe.Resource.getBytes("glow.shader"), () -> {}, e -> throw e);
		Runtime.polled.push(shipped);
		Runtime.clipboardAdapter = new WaitClipboard();
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(shipped)]);
		Runtime.polled.push(Runtime.assets);

		var doubled:Dynamic = WaitShapes.plain(4);
		check(doubled == 8, 'a function reaching no wait returns its value at once: $doubled');
		var counted:Dynamic = WaitShapes.ping(5);
		check(counted == 5, 'functions calling each other that reach no wait return their value at once: $counted');
		#if js
		Runtime.requestFrame = f -> haxe.Timer.delay(() -> f(0), 0);
		WaitShapes.log = [];
		var first:Dynamic = WaitShapes.doWhile(2);
		check(Std.isOfType(first, js.lib.Promise) && WaitShapes.log.join(",") == "0",
			'in a page a function that waits returns at its first wait: ${WaitShapes.log}');
		(first : js.lib.Promise<Int>).then(_ -> (WaitShapes.all() : Dynamic)).then(report, error -> {
			js.Syntax.code("console.log({0})", Std.string(error));
			js.Syntax.code("process.exit(1)");
		});
		#else
		report(WaitShapes.all());
		#end
	}
}

/** The shapes, built as a program's classes are. */
@:build(helix.raylib.internal.Wait.build())
@:access(helix.raylib.internal.Runtime)
class WaitShapes {
	public static var log:Array<String>;

	/** Runs every shape and checks it.

		@return  The checks made. */
	public static function all():Int {
		log = [];
		var before = Runtime.frames;
		var ran = loop(3);
		WaitTests.check(log.join(",") == "0,2,after" && ran == 3, 'frames 0 and 2 ran, 1 continued, the loop broke at 3, then what follows: $log');
		WaitTests.check(Runtime.frames - before == 3, 'each iteration is one frame: ${Runtime.frames - before}');

		log = [];
		before = Runtime.frames;
		WaitTests.check(doWhile(2) == 2 && log.join(",") == "0,1,after", 'a do-while runs its body before its condition: $log');
		WaitTests.check(Runtime.frames - before == 2, 'a do-while\'s iteration is one frame: ${Runtime.frames - before}');

		log = [];
		WaitTests.check(SaveFileText("a.txt", "one") && SaveFileText("b.txt", "two"), "SaveFileText returns once the file is written");
		WaitTests.check(text("a.txt") == "one" && text("none.txt") == "none", "a load in a function returns its value");
		WaitTests.check(joined() == "one two one", 'a function that waits is called as a value, an argument and in a string: ${joined()}');
		WaitTests.check(log.join(",") == "a.txt,none.txt,a.txt,b.txt,a.txt,a.txt,b.txt,a.txt", 'each load ends before the next begins: $log');

		before = Runtime.frames;
		WaitTests.check(even(4) && !even(3) && odd(3), "functions calling each other wait alike");
		WaitTests.check(Runtime.frames - before == 2, 'the two that reached 0 as even ended a frame: ${Runtime.frames - before}');

		var counter = new WaitCounter();
		WaitTests.check(counter.count(2) == 2 && counter.count(3) == 5, "a method that waits keeps its object");
		before = Runtime.frames;
		var doubler:WaitCounter = new WaitDoubler();
		var doubled = doubler.count(2);
		WaitTests.check(doubled == 5 && Runtime.frames - before == 4, 'an override that waits calls the function it overrides: $doubled');

		before = Runtime.frames;
		var within = nested(4);
		WaitTests.check(within == "4 one 2 3 3" && Runtime.frames - before == 7, 'functions declared in a function wait when called by their names: $within');

		before = Runtime.frames;
		var steps = ranged(2);
		WaitTests.check(steps == 2 && Runtime.frames - before == 6,
			'loops over a range and an array wait in each iteration: $steps, ${Runtime.frames - before} frames');

		var copied = copy("copied");
		WaitTests.check(copied == "copied 0", 'the clipboard is written before it is read: $copied');
		var glow = LoadCompiledShader("glow.shader");
		var missing = LoadCompiledShader("none.shader");
		WaitTests.check(glow.id != 0 && missing.id == 0, 'LoadCompiledShader returns the shader, or an empty one: ${glow.id} ${missing.id}');

		var fake = Runtime.system;
		Runtime.system = new WaitClock();
		var waited = waited(.05);
		Runtime.system = fake;
		WaitTests.check(waited >= .045 && waited < 1, 'WaitTime returns once the time has passed: $waited s');

		before = Runtime.frames;
		WaitTests.check(caught() == "caught after a frame", 'a throw after a wait is caught by the caller: ${caught()}');
		WaitTests.check(Runtime.frames - before == 2, 'the frame before each throw ended: ${Runtime.frames - before}');
		return WaitTests.checks;
	}

	/** Returns its argument doubled, reaching no wait.

		@param n  The number.
		@return  Twice it. */
	public static function plain(n:Int):Int {
		return n * 2;
	}

	/** Counts down to 0 through `pong`, reaching no wait.

		@param n  The count.
		@return  The count. */
	public static function ping(n:Int):Int {
		return n == 0 ? 0 : pong(n - 1) + 1;
	}

	static function pong(n:Int):Int {
		return n == 0 ? 0 : ping(n - 1) + 1;
	}

	// Ends a frame.
	static function frame():Void {
		BeginDrawing();
		EndDrawing();
	}

	static function loop(frames:Int):Int {
		var i = -1;
		while (!WindowShouldClose()) {
			i++;
			if (i == 1) {
				frame();
				continue;
			}
			if (i >= frames)
				break;
			log.push('$i');
			frame();
		}
		log.push("after");
		return i;
	}

	/** Runs frames in a `do`-`while`, each ended in the loop's own body.

		@param frames  How many.
		@return  The frames run. */
	public static function doWhile(frames:Int):Int {
		var i = 0;
		do {
			log.push('$i');
			BeginDrawing();
			EndDrawing();
		} while (++i < frames);
		log.push("after");
		return i;
	}

	static function text(fileName:String):String {
		log.push(fileName);
		var text = LoadFileText(fileName);
		return text == null ? "none" : text;
	}

	static function spaced(a:String, b:String):String {
		return a + " " + b;
	}

	static function joined():String {
		var both = spaced(text("a.txt"), text("b.txt"));
		return '$both ${text("a.txt")}';
	}

	static function even(n:Int):Bool {
		if (n == 0) {
			frame();
			return true;
		}
		return odd(n - 1);
	}

	static function odd(n:Int):Bool {
		return n == 0 ? false : even(n - 1);
	}

	static function nested(frames:Int):String {
		var ended = 0;
		function step():Void {
			frame();
			ended++;
		}
		var twice = () -> {
			step();
			step();
			return ended;
		};
		var read = function(fileName:String) return LoadFileText(fileName);
		function next(n:Int):Int
			return n + 1;
		function down(n:Int):Int {
			frame();
			return n == 0 ? 0 : down(n - 1) + 1;
		}
		while (twice() < frames) {}
		return '$ended ${read("a.txt")} ${next(1)} ${read("a.txt").length} ${down(2) + 1}';
	}

	static function ranged(frames:Int):Int {
		var ended = 0;
		function step():Void {
			frame();
			ended++;
		}
		for (_ in 0...frames)
			frame();
		for (_ in 0...frames)
			step();
		for (_ in [0, 1])
			frame();
		return ended;
	}

	static function copy(text:String):String {
		SetClipboardText(text);
		return '${GetClipboardText()} ${GetClipboardImage().width}';
	}

	static function waited(seconds:Float):Float {
		var start = haxe.Timer.stamp();
		WaitTime(seconds);
		return haxe.Timer.stamp() - start;
	}

	static function failing():Void {
		frame();
		throw "after a frame";
	}

	static function caught():String {
		try {
			failing();
		} catch (error:String) {
			return 'caught $error';
		}
		return "not thrown";
	}
}

/** An object whose method waits. */
@:build(helix.raylib.internal.Wait.build())
class WaitCounter {
	var total = 0;

	/** Creates one that counted nothing. */
	public function new() {}

	/** Runs frames, counting each.

		@param frames  How many.
		@return  The frames counted so far. */
	public function count(frames:Int):Int {
		for (_ in 0...frames) {
			BeginDrawing();
			EndDrawing();
			total++;
		}
		return total;
	}
}

/** Counts its frames twice over, by calling the function it overrides. */
@:build(helix.raylib.internal.Wait.build())
class WaitDoubler extends WaitCounter {
	/** Creates one that counted nothing. */
	public function new() {
		super();
	}

	override public function count(frames:Int):Int {
		super.count(frames);
		return super.count(frames) + 1;
	}
}

/** A clipboard answering at the next poll, as a page's does: its text kept, and no image. */
class WaitClipboard implements helix.platform.IClipboard {
	var text = "";

	/** Creates an empty one. */
	public function new() {}

	public function requestText(read:String->Void, ?failed:String->Void):Bool {
		Runtime.later(() -> read(text));
		return true;
	}

	public function setText(text:String, ?done:Void->Void, ?failed:String->Void):Void {
		Runtime.later(() -> {
			this.text = text;
			if (done != null)
				done();
		});
	}

	public function requestImage(read:haxe.io.Bytes->Void, ?failed:String->Void):Bool {
		Runtime.later(() -> if (failed != null) failed("no image"));
		return true;
	}

	public function setImage(png:haxe.io.Bytes, ?done:Void->Void, ?failed:String->Void):Void {
		Runtime.later(() -> if (failed != null) failed("no images"));
	}

	public function dispose():Void {}
}

/** A system whose clock is the real one, for a wait timed by it. */
class WaitClock extends FakeSystem {
	override public function getTime():Float
		return haxe.Timer.stamp();
}
