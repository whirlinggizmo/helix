import helix.raylib.Raylib.*;
import helix.raylib.internal.Runtime;
import helix.services.time.Time;

/** Checks the program's loop rewrite (helix-raylib's Loop): a `while` whose condition calls `WindowShouldClose()` among others, a `do`-`while`,
	and a `while (true)` that breaks on it, each run once a frame with `continue` ending a frame and `break` the loop, and what follows each
	loop run once after it. In a page the frames are the test's own; natively the loop runs them. */
@:access(helix.raylib.internal.Runtime)
class LoopTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		Runtime.system = new FakeSystem();
		Runtime.time = new Time(Runtime.system);
		#if js
		var pending:Array<Float->Void> = [];
		Runtime.requestFrame = f -> pending.push(f);
		function drain():Void {
			while (pending.length > 0)
				pending.shift()(0);
		}
		#else
		function drain():Void {}
		#end
		for (shape in [LoopShapes.whileAnd, LoopShapes.doWhile, LoopShapes.whileTrue]) {
			Runtime.shouldClose = false;
			LoopShapes.log = [];
			shape(3);
			drain();
			check(LoopShapes.log.join(",") == "0,2,after", 'frames 0 and 2 ran, 1 continued, the loop ended at 3, then what follows: ${LoopShapes.log}');
		}
		Runtime.shouldClose = false;
		LoopShapes.log = [];
		LoopShapes.doWhile(0);
		drain();
		check(LoopShapes.log.join(",") == "0,after", 'a do-while runs its body once before its condition: ${LoopShapes.log}');
		Runtime.shouldClose = false;
		LoopShapes.log = [];
		LoopShapes.whileAnd(0);
		drain();
		check(LoopShapes.log.join(",") == "after", 'a while whose condition is false at once runs no frame: ${LoopShapes.log}');
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}

/** The loop's shapes, rewritten as a program's main class is. */
@:build(helix.raylib.internal.Loop.build())
class LoopShapes {
	public static var log:Array<String>;

	public static function whileAnd(frames:Int):Void {
		var i = -1;
		while (!WindowShouldClose() && i + 1 < frames) {
			i++;
			if (i == 1)
				continue;
			log.push('$i');
		}
		log.push("after");
	}

	public static function doWhile(frames:Int):Void {
		var i = -1;
		do {
			i++;
			if (i == 1)
				continue;
			log.push('$i');
		} while (!WindowShouldClose() && i + 1 < frames);
		log.push("after");
	}

	public static function whileTrue(frames:Int):Void {
		var i = -1;
		while (true) {
			if (WindowShouldClose())
				break;
			i++;
			if (i >= frames)
				break;
			if (i == 1)
				continue;
			log.push('$i');
		}
		log.push("after");
	}
}
