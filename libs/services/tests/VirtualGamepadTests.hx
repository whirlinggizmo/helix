import helix.math.Bounds2D;
import helix.math.Vector2D;
import helix.services.input.Gamepads;
import helix.services.input.Tilt;
import helix.services.input.Touch;
import helix.services.input.VirtualGamepad;

/** Checks VirtualGamepad over fake events, devices and window (800 by 600): unplugged with the hint until the first touch; a floating
	stick on each half read through Gamepads; the dead zone; a finger landing on a held stick taking it over; a blocked bound; a lift
	handing the stick to a finger still down; a fixed stick pushed from its base; a following base; a resize letting go; a physical
	gamepad replacing the virtual one until the next touch after it leaves; and buttons: shown from the start, pressed by the first touch,
	slid off and onto, a button turned off, kept from the sticks, and released by a physical gamepad; the diamond; and a tilt
	stick. */
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
		var tilt = new Tilt(events, devices);
		gamepads.deadZone = 0;
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			touch.poll();
			tilt.poll();
			virtualGamepad.poll();
			gamepads.poll();
		}

		frame();
		check(!virtualGamepad.pluggedIn && virtualGamepad.hintVisible && !gamepads.isConnected(0), "before a touch: unplugged, the hint shown");
		check(near(virtualGamepad.left.baseX, 90) && near(virtualGamepad.left.baseY, 510) && near(virtualGamepad.right.baseX, 710),
			"each stick's home: one and a half radii in from its half's bottom outer corner");

		devices.touchAvailable = false;
		check(!virtualGamepad.hintVisible && !touch.available, "no touch: no hint");
		devices.touchAvailable = true;

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

		// Buttons: A (South) at (700, 500), radius 40; B (West) at (600, 500), radius 30; X (North) off.
		virtualGamepad.enabled = true;
		frame([TouchUp(8, 200, 300)]);
		virtualGamepad.configure({
			buttons: [
				{button: South, position: new Vector2D(700, 500)},
				{button: West, position: new Vector2D(600, 500), radius: 30},
				{button: North, position: new Vector2D(100, 100), enabled: false}
			]
		});
		frame();
		check(virtualGamepad.visible && !virtualGamepad.pluggedIn && !gamepads.isButtonDown(0, South), "buttons: shown before a touch, and up");
		devices.touchAvailable = false;
		check(!virtualGamepad.visible, "no touch: no buttons shown");
		devices.touchAvailable = true;
		frame([TouchDown(9, 705, 505)]);
		check(virtualGamepad.pluggedIn && gamepads.isButtonPressed(0, South) && gamepads.isButtonDown(0, South) && !virtualGamepad.right.held
			&& virtualGamepad.capturesFinger(9),
			"the first touch on a button plugs the virtual gamepad in and presses the button, and the stick doesn't take the finger");
		frame();
		check(gamepads.isButtonDown(0, South) && !gamepads.isButtonPressed(0, South), "held: down, pressed once");
		frame([TouchMove(9, 760, 505)]);
		check(!gamepads.isButtonDown(0, South) && gamepads.isButtonReleased(0, South) && !virtualGamepad.right.held,
			"sliding off releases the button, and the finger stays a button finger");
		frame([TouchMove(9, 605, 505)]);
		check(gamepads.isButtonPressed(0, West) && !gamepads.isButtonDown(0, South), "sliding onto another button presses it");
		frame([TouchMove(9, 700, 500)]);
		check(gamepads.isButtonReleased(0, West) && gamepads.isButtonPressed(0, South), "B slid onto A: B released, A pressed");
		frame([TouchUp(9, 700, 500)]);
		check(gamepads.isButtonReleased(0, South) && virtualGamepad.capturesFinger(9), "lifting lets go, and the finger is held this frame");
		frame();
		check(!virtualGamepad.capturesFinger(9), "the lifted finger is free the frame after");
		frame([TouchDown(10, 100, 100)]);
		check(virtualGamepad.left.held && !gamepads.isButtonDown(0, North), "a finger on a button turned off takes the stick");
		frame([TouchUp(10, 100, 100)]);
		frame([TouchDown(11, 650, 300), TouchDown(12, 700, 500)]);
		frame([TouchUp(11, 650, 300)]);
		check(!virtualGamepad.right.held && gamepads.isButtonDown(0, South), "a stick's finger lifting doesn't hand the stick to a button finger");
		devices.gamepadConnected = true;
		frame();
		check(gamepads.isButtonReleased(0, South) && !virtualGamepad.visible, "a physical gamepad releases the virtual buttons and hides them");
		devices.gamepadConnected = false;
		frame([TouchUp(12, 700, 500)]);
		virtualGamepad.configure({buttons: [{button: East}, {button: Start}]});
		frame([TouchDown(13, 724, 460)]);
		check(gamepads.isButtonDown(0, East) && !virtualGamepad.buttons[1].placed,
			"East without a position, in the diamond 3.5 radii in from the corner; Start without one, unplaced");
		frame([TouchUp(13, 724, 460)]);

		// A tilt stick: the left stick reads the tilt past its dead zone, and the right stick's default zone is the whole window.
		virtualGamepad.tilt = tilt;
		virtualGamepad.configure({left: {tilt: true}});
		frame([TouchDown(14, 100, 300)]);
		check(virtualGamepad.right.held && !virtualGamepad.left.held && gamepads.getAxis(0, LeftX) == 0,
			"a finger on the left half goes to the right stick; the tilt stick reads 0 before the tilt is on");
		frame([TouchUp(14, 100, 300)]);
		tilt.requestAccess();
		frame([TiltState(On), Tilt(10, 5, 0)]);
		var started = haxe.Timer.stamp();
		while (haxe.Timer.stamp() - started < .6) {}
		frame([Tilt(10, 5, 0)]);
		check(!tilt.calibrating && gamepads.getAxis(0, LeftX) == 0, "level taken: the tilt stick reads 0 at level");
		frame([Tilt(10, 20, 0)]);
		check(near(gamepads.getAxis(0, LeftX), (.5 - .12) / (1 - .12)) && gamepads.getAxis(0, LeftY) == 0,
			"15 degrees of 30 across: 0.5, past the dead zone of 0.12");
		devices.gamepadConnected = true;
		frame();
		check(gamepads.getAxis(0, LeftX) == 0, "a physical gamepad replaces the tilt stick too");
		devices.gamepadConnected = false;
		frame([Tilt(10, 20, 0)]);
		check(virtualGamepad.pluggedIn && gamepads.getAxis(0, LeftX) > 0 && virtualGamepad.hintVisible,
			"the physical gamepad gone: the tilt plugs the virtual gamepad in without a touch, the finger stick's hint still shown");
		var stick = virtualGamepad.left;
		check(near(stick.baseX, 90)
			&& near(stick.baseY, 510)
			&& near(stick.knobX, stick.baseX + stick.x * 60)
			&& near(stick.knobY, stick.baseY),
			"the tilt stick's base at its home, its knob pushed from the base by the tilt");
		frame([Tilt(40, 40, 0)]);
		check(near(gamepads.getAxis(0, LeftX), Math.sqrt(.5)) && near(gamepads.getAxis(0, LeftY), Math.sqrt(.5)),
			"a full tilt both ways: held to a circle of radius 1");
		virtualGamepad.configure({right: {tilt: true}});
		frame([Tilt(10, 20, 0), TouchDown(15, 700, 300)]);
		check(near(gamepads.getAxis(0, RightX), (.5 - .12) / (1 - .12)) && gamepads.getAxis(0, LeftX) == 0 && virtualGamepad.left.held,
			"the right stick as the tilt stick: RightX reads the tilt, a finger on the right half goes to the left stick");
		frame([TouchUp(15, 700, 300)]);
		virtualGamepad.configure({});
		frame([TouchDown(16, 100, 300), TouchDown(17, 700, 300)]);
		check(virtualGamepad.left.finger == 16 && virtualGamepad.right.finger == 17, "tilt turned off: the sticks' zones are the halves again");
		frame([TouchUp(16, 100, 300), TouchUp(17, 700, 300)]);
		tilt.calibrate();
		check(tilt.calibrating, "taking level again");
		tilt.releaseAccess();
		check(!tilt.calibrating, "the tilt released while level is being taken: not calibrating");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
