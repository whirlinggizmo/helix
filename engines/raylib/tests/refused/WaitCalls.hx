import helix.raylib.*;
import helix.raylib.Raylib.*;

/** A program calling what waits where a call can't wait, which doesn't build on any target: `helix.py test` builds it for JS and
	natively and checks that each is refused with its own message: `EndDrawing` and a file call in a function used as a value, a function of
	the program's that waits called in one and used as a value, a file call in a constructor and in a variable's initial value, a
	function that waits declared by an interface and overriding one that doesn't, one of two functions calling each other called in a function used as a value, and `EndDrawing` in a function declared in a function and called by one used as a value. */
@:build(helix.raylib.internal.Wait.build())
class WaitCalls {
	static var saved = LoadFileText("best.txt");

	static function frame():Void {
		BeginDrawing();
		EndDrawing();
	}

	static function main():Void {
		InitWindow(320, 200, "refused");
		var end = () -> EndDrawing();
		var load = (name:String) -> LoadFileData(name);
		var written = ["one", "two"].map(text -> SaveFileText("copy.txt", text));
		var later = () -> frame();
		var value = frame;
		var hero = new WaitHero();
		WaitTurns.tick(2);
		var ends = [end];
		var files = ["hero.png"].map(load);
		var laters = [later];
		WaitSteps.run();
		CloseWindow();
	}
}

@:build(helix.raylib.internal.Wait.build())
class WaitHero implements WaitShown {
	final found:Bool;

	public function new() {
		found = FileExists("hero.glb");
	}

	public function show():Void {
		BeginDrawing();
		EndDrawing();
	}
}

interface WaitShown {
	function show():Void;
}

@:build(helix.raylib.internal.Wait.build())
class WaitBase {
	public function new() {}

	public function update():Void {}
}

@:build(helix.raylib.internal.Wait.build())
class WaitLoader extends WaitBase {
	override public function update():Void {
		var text = LoadFileText("level.txt");
	}
}

@:build(helix.raylib.internal.Wait.build())
class WaitTurns {
	public static function tick(turns:Int):Void {
		if (turns > 0)
			tock(turns - 1);
		EndDrawing();
	}

	static function tock(turns:Int):Void {
		var again = [() -> tick(turns)];
		tick(turns);
	}
}

@:build(helix.raylib.internal.Wait.build())
class WaitSteps {
	public static function run():Void {
		function step():Void {
			EndDrawing();
		}
		var twice = () -> {
			step();
			step();
		};
		var steps = [twice];
	}
}
