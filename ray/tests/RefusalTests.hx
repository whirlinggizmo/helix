import helix.ray.Raylib.*;
import helix.ray.internal.Runtime;
import helix.services.input.Gamepads;
import helix.services.input.Mouse;
import helix.services.screen.Screen;

/** Checks helix-ray's warnings when the platform refuses a request: `SetMousePosition` where the cursor can't be moved (a page) and where
	the system refuses, and `SetGamepadVibration` on a pad that can't shake. Each warns once a run for each reason, however often it is
	called; the position asked for is still recorded, as raylib's; an empty pad slot and a request granted warn of nothing. On devices the
	test sets (services' `FakeDevices`), the program's log taken by the test. */
@:access(helix.ray.internal.Runtime)
@:access(helix.ray.raylib.RCore)
class RefusalTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var warnings:Array<String> = [];
		SetTraceLogLevel(LOG_WARNING);
		SetTraceLogCallback((level, text) -> if (level == LOG_WARNING) warnings.push(text));
		var events = new FakeEvents();
		Runtime.events = events;
		Runtime.screen = new Screen(new FakeWindow(), events);

		var granting = new FakeDevices();
		use(granting);
		SetMousePosition(10, 20);
		SetGamepadVibration(0, 1, 1, 1);
		check(warnings.length == 0, 'a request granted warns of nothing: $warnings');

		var refusing = new RefusingDevices();
		use(refusing);
		refusing.movable = false;
		for (_ in 0...3)
			SetMousePosition(30, 40);
		check(warnings.length == 1 && warnings[0].indexOf("page") >= 0, 'a page refusing warns once, naming it: $warnings');
		check(helix.ray.raylib.RCore.lastPointerX == 30
			&& helix.ray.raylib.RCore.lastPointerY == 40, "the position asked for is recorded");
		refusing.movable = true;
		for (_ in 0...3)
			SetMousePosition(50, 60);
		check(warnings.length == 2
			&& warnings[1].indexOf("system refused") >= 0, 'the system refusing warns once more, naming it: $warnings');

		SetGamepadVibration(1, 1, 1, 1);
		check(warnings.length == 2, 'an empty slot is passed over, as raylib\'s: $warnings');
		for (_ in 0...3)
			SetGamepadVibration(0, 1, 1, 1);
		check(warnings.length == 3 && warnings[2].indexOf("SetGamepadVibration") >= 0, 'a pad that can\'t shake warns once: $warnings');
		SetMousePosition(70, 80);
		SetGamepadVibration(0, 1, 1, 1);
		check(warnings.length == 3, 'each reason warns once a run: $warnings');
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// Sets the mouse and gamepads helix-ray reads to the fake's.
	static function use(devices:FakeDevices):Void {
		Runtime.mouseAdapter = devices;
		Runtime.mouseService = new Mouse(Runtime.events, devices);
		Runtime.gamepadsAdapter = devices;
		Runtime.gamepadsService = new Gamepads(Runtime.events, devices);
	}
}

/** The fake's devices refusing: the cursor doesn't move, the pad doesn't shake. */
class RefusingDevices extends FakeDevices {
	/** Gets or sets what `canSetPosition` answers: false as a page has it, true where the system refuses. */
	public var movable = false;

	override public function canSetPosition():Bool
		return movable;

	override public function setPosition(x:Float, y:Float):Bool
		return false;

	override public function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool
		return false;
}
