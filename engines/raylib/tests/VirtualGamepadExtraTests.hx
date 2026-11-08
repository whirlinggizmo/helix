import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.VirtualGamepad.*;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.VirtualGamepads;
import helix.services.input.Gamepads;
import helix.services.input.Mouse;
import helix.services.input.Touch;
import helix.services.screen.Screen;

/** Checks `extras.VirtualGamepad` over fakes (services' `FakeSystem`, `FakeWindow`, `FakeEvents` and `FakeDevices`): unplugged until the
	first touch; then gamepad 0, virtual, its left stick read through `GetGamepadAxisMovement`; a finger holding a stick leaving the mouse
	up, and a free finger tapping a blocked bound as a click there; a physical gamepad replacing it; and disabled, unplugged. */
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
		devices.padConnected = false;
		Runtime.system = new FakeSystem();
		Runtime.window = window;
		Runtime.events = events;
		Runtime.screen = new Screen(window, events);
		Runtime.touchService = new Touch(events, devices);
		Runtime.mouseService = new Mouse(events, devices);
		Runtime.gamepadsAdapter = devices;
		Runtime.gamepadsService = new Gamepads(events, devices);
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			Runtime.touch().poll();
			Runtime.mouse().poll();
			VirtualGamepads.inSlot(0).poll();
			Runtime.gamepads().poll();
		}

		var pause = new Rectangle(736, 0, 64, 64);
		EnableVirtualGamepad(0, {blockedBounds: [pause], right: {basePlacement: VIRTUAL_STICK_BASE_FIXED}});
		frame();
		check(!IsGamepadAvailable(0) && !IsGamepadVirtual(0) && Runtime.overlay != null, "enabled: unplugged until a touch, drawn at EndDrawing");

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
		frame([TouchUp(2, 760, 30)]);
		check(IsMouseButtonReleased(MOUSE_BUTTON_LEFT), "its lift releases the mouse");
		frame([TouchUp(1, 260, 300)]);
		check(!IsMouseButtonReleased(MOUSE_BUTTON_LEFT) && GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X) == 0,
			"the stick's finger lifting leaves the mouse alone");

		frame([TouchDown(3, 500, 300)]);
		check(GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X) < -.9, "a fixed right stick, its base at its zone's center, pushed left");
		frame([TouchUp(3, 500, 300)]);

		devices.padConnected = true;
		frame();
		check(IsGamepadAvailable(0) && !IsGamepadVirtual(0) && GetGamepadName(0) == "Fake", "a physical gamepad replaces it");
		devices.padConnected = false;
		frame();
		check(!IsGamepadAvailable(0), "the physical gamepad gone: unplugged until a touch");

		frame([TouchDown(4, 200, 300)]);
		DisableVirtualGamepad(0);
		frame([TouchUp(4, 200, 300)]);
		check(!IsGamepadAvailable(0) && !IsGamepadVirtual(0), "disabled: unplugged");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
