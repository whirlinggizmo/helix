import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Runtime;
import helix.services.input.Mouse;
import helix.services.input.Touch;
import helix.services.screen.Screen;

/** Checks a finger read as the mouse over fakes (services' `FakeSystem`, `FakeWindow`, `FakeEvents` and `FakeDevices`): a finger down
	holds the left button at its position, its lift releases it, and a finger landing and lifting within a frame presses and releases
	it there. */
@:access(helix.raylib.internal.Runtime)
class TouchTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var events = new FakeEvents(),
			devices = new FakeDevices(),
			window = new FakeWindow();
		Runtime.system = new FakeSystem();
		Runtime.window = window;
		Runtime.events = events;
		Runtime.screen = new Screen(window, events);
		Runtime.touchService = new Touch(events, devices);
		Runtime.mouseService = new Mouse(events, devices);
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			Runtime.touch().poll();
			Runtime.mouse().poll();
		}

		frame();
		frame([TouchDown(1, 200, 300)]);
		var held = GetMousePosition();
		check(IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && IsMouseButtonDown(MOUSE_BUTTON_LEFT) && held.x == 200 && held.y == 300,
			"a finger landing presses the mouse there");
		frame([TouchUp(1, 200, 300)]);
		check(IsMouseButtonReleased(MOUSE_BUTTON_LEFT) && !IsMouseButtonDown(MOUSE_BUTTON_LEFT), "its lift releases the mouse");

		frame([TouchDown(9, 120, 140), TouchUp(9, 120, 140)]);
		var tap = GetMousePosition();
		check(IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && IsMouseButtonReleased(MOUSE_BUTTON_LEFT) && tap.x == 120 && tap.y == 140,
			"a finger landing and lifting within a frame presses and releases the mouse there");
		frame();
		check(!IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && !IsMouseButtonReleased(MOUSE_BUTTON_LEFT), "the frame after the tap: neither");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
