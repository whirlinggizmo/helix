import helix.math.Bounds2D;
import helix.math.Vector2D;
import helix.services.input.Gamepads;
import helix.services.input.Touch;
import helix.services.input.VirtualGamepad;

/** Checks VirtualGamepad over fake events, devices and window (800 by 600): unplugged with the hint until the first touch; a floating
	stick on each half read through Gamepads; the dead zone; a finger landing on a held stick taking it over; a blocked bound; a lift
	handing the stick to a finger still down; a fixed stick pushed from its base; a following base; a resize letting go; and a physical
	gamepad replacing the virtual one until the next touch after it leaves. */
class VirtualGamepadTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	static function main():Void {
		var events = new FakeEvents(),
			devices = new FakeDevices(),
			window = new FakeWindow();
		devices.gamepadConnected = false;
		var touch = new Touch(events, devices);
		var pause = new Bounds2D().set(700, 0, 800, 100);
		var virtualGamepad = new VirtualGamepad(touch, window, devices, 0, {blockedBounds: [pause]});
		var gamepads = new Gamepads(events, virtualGamepad);
		gamepads.deadZone = 0;
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			touch.poll();
			virtualGamepad.poll();
			gamepads.poll();
		}

		frame();
		check(!virtualGamepad.pluggedIn && virtualGamepad.hintVisible && !gamepads.isConnected(0), "before a touch: unplugged, the hint shown");
		check(near(virtualGamepad.left.baseX, 90) && near(virtualGamepad.left.baseY, 510) && near(virtualGamepad.right.baseX, 710),
			"each stick's home: one and a half radii in from its half's bottom outer corner");

		devices.touchScreen = false;
		check(!virtualGamepad.hintVisible && !touch.available, "no touch screen: no hint");
		devices.touchScreen = true;

		frame([TouchDown(1, 200, 300)]);
		check(virtualGamepad.pluggedIn
			&& !virtualGamepad.hintVisible
			&& gamepads.isConnected(0)
			&& gamepads.getName(0) == "Virtual gamepad",
			"the first touch plugs it in");
		check(virtualGamepad.left.held && virtualGamepad.left.finger == 1 && near(virtualGamepad.left.baseX, 200),
			"the left half's finger takes the left stick");
		frame([TouchMove(1, 230, 300)]);
		check(near(gamepads.getAxis(0, LeftX), (30 / 60 - .12) / .88)
			&& gamepads.getAxis(0, LeftY) == 0, "half a radius right reads past the dead zone");
		frame([TouchMove(1, 203, 300)]);
		check(gamepads.getAxis(0, LeftX) == 0, "a resting thumb stays in the dead zone");
		frame([TouchMove(1, 390, 300)]);
		check(near(virtualGamepad.left.knobX, 260)
			&& near(gamepads.getAxis(0, LeftX), 1), "a push past the radius holds the knob at it, reading 1");

		frame([TouchDown(2, 600, 400)]);
		check(virtualGamepad.right.held && virtualGamepad.right.finger == 2, "the right half's finger takes the right stick");
		frame([TouchMove(2, 600, 340)]);
		check(near(gamepads.getAxis(0, RightY), -1) && near(gamepads.getAxis(0, LeftX), 1), "both sticks read at once");

		frame([TouchDown(3, 750, 50)]);
		check(virtualGamepad.right.finger == 2, "a finger within a blocked bound stays free");
		frame([TouchUp(3, 750, 50)]);

		frame([TouchDown(4, 100, 100)]);
		check(virtualGamepad.left.finger == 4 && near(virtualGamepad.left.baseX, 100), "a finger landing in the zone takes the stick over");
		frame([TouchUp(4, 100, 100)]);
		check(virtualGamepad.left.finger == 1, "its lift hands the stick to the finger still down in the zone");

		frame([TouchUp(1, 390, 300), TouchUp(2, 600, 340)]);
		check(!virtualGamepad.left.held && gamepads.getAxis(0, LeftX) == 0 && near(virtualGamepad.left.baseX, 90), "let go: 0, back home");

		virtualGamepad.right.basePlacement = Fixed;
		virtualGamepad.right.fixedBasePosition = new Vector2D(700, 500);
		frame([TouchDown(5, 500, 500)]);
		check(near(virtualGamepad.right.baseX, 700)
			&& near(gamepads.getAxis(0, RightX), -1), "a fixed stick is pushed from its base toward the finger");
		frame([TouchUp(5, 500, 500)]);

		virtualGamepad.left.basePlacement = Following;
		frame([TouchDown(6, 200, 300)]);
		frame([TouchMove(6, 360, 300)]);
		check(near(virtualGamepad.left.baseX, 300), "a following base is pulled along past the radius");
		window.logicalWidth = 600;
		frame([TouchMove(6, 360, 300)]);
		check(!virtualGamepad.left.held, "a resize lets go");
		frame([TouchUp(6, 360, 300)]);
		window.logicalWidth = 800;
		frame();

		devices.gamepadConnected = true;
		frame([TouchDown(7, 200, 300)]);
		check(virtualGamepad.physicalConnected
			&& !virtualGamepad.pluggedIn
			&& !virtualGamepad.left.held
			&& gamepads.getName(0) == "Fake",
			"a physical gamepad replaces it, and its sticks ignore touches");
		frame([TouchUp(7, 200, 300)]);
		devices.gamepadConnected = false;
		frame();
		check(!virtualGamepad.pluggedIn && virtualGamepad.hintVisible, "the physical gamepad gone: unplugged until a touch");
		frame([TouchDown(8, 200, 300)]);
		check(virtualGamepad.pluggedIn, "the next touch plugs it in again");

		virtualGamepad.enabled = false;
		frame();
		check(!virtualGamepad.pluggedIn && !gamepads.isConnected(0) && !virtualGamepad.left.held, "disabled: unplugged");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
