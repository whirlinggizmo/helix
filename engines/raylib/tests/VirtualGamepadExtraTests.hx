import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.VirtualGamepad.*;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.VirtualGamepads;
import helix.services.input.Gamepads;
import helix.services.input.Mouse;
import helix.services.input.Tilt;
import helix.services.input.Touch;
import helix.services.screen.Screen;

/** Checks `extras.VirtualGamepad` over fakes (services' `FakeSystem`, `FakeWindow`, `FakeEvents` and `FakeDevices`): unplugged until
	the first touch; then gamepad 0, virtual, its left stick read through `GetGamepadAxisMovement`; a finger holding a stick leaving the mouse
	up and the touch functions, and a free finger tapping a blocked bound as a click there; a physical gamepad replacing it; disabled, unplugged; and a button pressed and released through raylib's
	gamepad functions, following its position, in a design's pixels too;
	the default diamond; a button and a stick that aren't visible still reading; the sticks' read-backs; and the tilt's status and a tilt
	stick. */
@:access(helix.raylib.internal.Runtime)
class VirtualGamepadExtraTests {
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
		devices.gamepadConnected = false;
		Runtime.system = new FakeSystem();
		Runtime.window = window;
		Runtime.events = events;
		Runtime.screen = new Screen(window, events);
		var touch = new Touch(events, devices);
		Runtime.touchService = touch;
		Runtime.mouseService = new Mouse(events, devices);
		Runtime.gamepadsAdapter = devices;
		Runtime.gamepadsService = new Gamepads(events, devices);
		Runtime.tiltService = new Tilt(events, devices);
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			touch.poll();
			Runtime.tilt().poll();
			Runtime.mouse().poll();
			var pad = VirtualGamepads.inSlot(0);
			if (pad != null)
				pad.poll();
			Runtime.gamepads().poll();
		}

		var pause = new Rectangle(736, 0, 64, 64);
		EnableVirtualGamepad(0, {blockedBounds: [pause], right: {basePlacement: VIRTUAL_STICK_BASE_FIXED}});
		frame();
		check(!IsGamepadAvailable(0) && !IsGamepadVirtual(0) && Runtime.ending != null, "enabled: unplugged until a touch, drawn as each frame ends");

		frame([TouchDown(1, 200, 300)]);
		check(IsGamepadAvailable(0) && IsGamepadVirtual(0) && GetGamepadName(0) == "Virtual gamepad", "the first touch plugs it in as gamepad 0");
		check(!IsMouseButtonDown(MOUSE_BUTTON_LEFT)
			&& !IsMouseButtonPressed(MOUSE_BUTTON_LEFT), "a finger holding a stick isn't the mouse");
		frame([TouchMove(1, 260, 300)]);
		check(GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) == 1 && GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_TRIGGER) == -1,
			"a full push reads 1, and the triggers rest at -1");

		frame([TouchDown(2, 760, 30)]);
		var mouse = GetMousePosition();
		check(IsMouseButtonPressed(MOUSE_BUTTON_LEFT)
			&& mouse.x == 760
			&& mouse.y == 30, "a free finger in a blocked bound is a click there");
		check(GetTouchPointCount() == 1 && GetTouchPosition(0).x == 760, "the touch functions list the free finger alone");
		frame([TouchUp(2, 760, 30)]);
		check(IsMouseButtonReleased(MOUSE_BUTTON_LEFT), "its lift releases the mouse");
		frame([TouchDown(4, 760, 30), TouchUp(4, 760, 30)]);
		check(IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && IsMouseButtonReleased(MOUSE_BUTTON_LEFT),
			"a free finger tapping within a frame, while a stick holds another, presses and releases the mouse");
		frame([TouchUp(1, 260, 300)]);
		check(!IsMouseButtonReleased(MOUSE_BUTTON_LEFT) && GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) == 0,
			"the stick's finger lifting leaves the mouse alone");

		frame([TouchDown(3, 500, 300)]);
		check(GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X) < -.9, "a fixed right stick, its base at its zone's center, pushed left");
		frame([TouchUp(3, 500, 300)]);

		devices.gamepadConnected = true;
		frame();
		check(IsGamepadAvailable(0) && !IsGamepadVirtual(0) && GetGamepadName(0) == "Fake", "a physical gamepad replaces it");
		devices.gamepadConnected = false;
		frame();
		check(!IsGamepadAvailable(0), "the physical gamepad gone: unplugged until a touch");

		frame([TouchDown(4, 200, 300)]);
		DisableVirtualGamepad(0);
		frame([TouchUp(4, 200, 300)]);
		check(!IsGamepadAvailable(0) && !IsGamepadVirtual(0), "disabled: unplugged");

		// A button, read through raylib's gamepad functions, its position and radius in the screen's pixels.
		var at = new Vector2(700, 400);
		EnableVirtualGamepad(0, {buttons: [{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN, position: at, label: "A"}]});
		frame([TouchDown(5, 730, 400)]);
		check(IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN)
			&& IsGamepadButtonDown(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN)
			&& !IsMouseButtonDown(MOUSE_BUTTON_LEFT),
			"a button finger presses the button, and isn't the mouse");
		frame([TouchUp(5, 730, 400)]);
		check(IsGamepadButtonReleased(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN), "lifting releases the button");
		at.x = 100;
		frame([TouchDown(6, 100, 400)]);
		check(IsGamepadButtonDown(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN), "the button follows its position's fields");
		frame([TouchUp(6, 100, 400)]);
		Runtime.screen.setDesignSize(400, 300, Stretch);
		at.x = 200;
		at.y = 150;
		frame([TouchDown(7, 470, 300)]);
		check(IsGamepadButtonDown(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN), "a design's pixels: the center and radius scaled to the framebuffer's");
		frame([TouchUp(7, 470, 300)]);
		Runtime.screen = new Screen(window, events);

		// The default diamond, 3.5 radii in from the bottom-right corner, each face button 1.6 radii from its center; a button off the
		// diamond without a position is up; a stick that isn't visible still reads; and the read-backs.
		EnableVirtualGamepad(0, {
			left: {visible: false},
			right: {enabled: false},
			buttons: [
				{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN},
				{button: GAMEPAD_BUTTON_RIGHT_FACE_UP, visible: false},
				{button: GAMEPAD_BUTTON_MIDDLE_RIGHT}
			]
		});
		frame([TouchDown(8, 660, 524)]);
		check(IsGamepadButtonDown(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN), "A at its place in the diamond");
		frame([TouchUp(8, 660, 524)]);
		frame([TouchDown(9, 660, 396)]);
		check(IsGamepadButtonDown(0, GAMEPAD_BUTTON_RIGHT_FACE_UP), "a button that isn't visible still reads");
		frame([TouchUp(9, 660, 396)]);
		frame([TouchDown(10, 400, 300)]);
		check(!IsGamepadButtonDown(0, GAMEPAD_BUTTON_MIDDLE_RIGHT)
			&& IsVirtualStickHeld(0, VIRTUAL_STICK_LEFT)
			&& !IsVirtualStickHeld(0, VIRTUAL_STICK_RIGHT),
			"Start without a position is up, and the finger takes the left stick");
		frame([TouchMove(10, 430, 300)]);
		var base = GetVirtualStickBase(0, VIRTUAL_STICK_LEFT),
			knob = GetVirtualStickKnob(0, VIRTUAL_STICK_LEFT);
		check(base.x == 400 && base.y == 300 && knob.x == 430 && knob.y == 300 && IsVirtualGamepadVisible(0),
			'the base and knob read back in the screen\'s pixels: $base, $knob');
		frame([TouchUp(10, 430, 300)]);

		// The tilt's status, and a tilt stick read as the left stick.
		check(GetTiltStatus() == TILT_STATUS_OFF && !IsTiltCalibrating(), "the tilt off until asked for");
		EnableVirtualGamepad(0, {left: {tilt: true}, right: {enabled: false}});
		EnableTiltAsync();
		frame([TiltState(WaitingForTap)]);
		check(GetTiltStatus() == TILT_STATUS_WAITING_FOR_TAP, "waiting for the tap that allows the tilt");
		frame([TiltState(Starting)]);
		check(GetTiltStatus() == TILT_STATUS_STARTING, "allowed: starting, waiting for the first reading");
		frame([TouchDown(11, 400, 300), TiltState(On), Tilt(10, 5, 0)]);
		check(GetTiltStatus() == TILT_STATUS_ON
			&& IsTiltCalibrating()
			&& !IsTiltReady()
			&& GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) == 0,
			"on, and calibrating: the tilt stick reads 0");
		var started = haxe.Timer.stamp();
		while (haxe.Timer.stamp() - started < .6) {}
		frame([Tilt(10, 5, 0)]);
		frame([Tilt(10, 35, 0)]);
		check(!IsTiltCalibrating()
			&& IsTiltReady()
			&& GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) == 1
			&& !IsVirtualStickHeld(0, VIRTUAL_STICK_LEFT),
			"a full tilt across reads 1 on the left stick, which captures no finger");
		var base = GetVirtualStickBase(0, VIRTUAL_STICK_LEFT),
			knob = GetVirtualStickKnob(0, VIRTUAL_STICK_LEFT);
		check(knob.x > base.x && knob.y == base.y, 'the tilt stick\'s knob pushed from its base by the tilt: $base, $knob');
		CalibrateTilt();
		check(IsTiltCalibrating(), "taking level again");
		DisableTilt();
		check(!IsTiltCalibrating(), "the tilt turned off while level is being taken: not calibrating");
		frame([TouchUp(11, 400, 300), TiltState(Refused)]);
		check(GetTiltStatus() == TILT_STATUS_REFUSED && GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) == 0, "refused: reads 0");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
