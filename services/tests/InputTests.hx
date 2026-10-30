import helix.math.Point2D;
import helix.services.input.Actions;
import helix.services.input.Gamepads;
import helix.services.input.Keyboard;
import helix.services.input.Mouse;
import helix.services.input.Tilt;

/** Checks the keyboard, the mouse, the gamepads, the tilt and Actions over fake events: held, pressed and released by frame; repeats
	ignored; focus lost letting go; sticks past a round dead zone; tilt from level; actions over the devices given, pressed once however
	many bindings are held, axes as buttons, and movement capped at 1; and the first press unlocking. */
class InputTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var events = new FakeEvents();
		var keyboard = new Keyboard(events),
			mouse = new Mouse(events),
			pads = new Gamepads(events),
			tilt = new Tilt(events);
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			keyboard.poll();
			mouse.poll();
			pads.poll();
			tilt.poll();
		}

		var pressed:Array<helix.platform.Event> = [PadButtonDown(0, South), KeyDown(Space, false)];
		check(helix.platform.adapters.shared.FirstPress.mark(pressed, false) && Type.enumEq(pressed[1], Unlocked),
			"a pad's press doesn't unlock; a key's does, before it");
		var marked:Array<helix.platform.Event> = [TouchDown(1, 0, 0), TouchUp(1, 0, 0)];
		check(helix.platform.adapters.shared.FirstPress.mark(marked, false) && Type.enumEq(marked[1], Unlocked),
			"a finger activates as it lifts, not as it lands");
		frame([KeyDown(Space, false)]);
		check(keyboard.isKeyDown(Space) && keyboard.isKeyPressed(Space) && !keyboard.isKeyReleased(Space), "a key down: held and pressed");
		frame([KeyDown(Space, true)]);
		check(keyboard.isKeyDown(Space) && !keyboard.isKeyPressed(Space), "held: a repeat isn't pressed again");
		frame([KeyUp(Space)]);
		check(!keyboard.isKeyDown(Space) && keyboard.isKeyReleased(Space), "up: released");
		frame();
		check(!keyboard.isKeyReleased(Space), "released for one frame alone");
		frame([KeyDown(A, false), KeyUp(A)]);
		check(keyboard.isKeyPressed(A) && keyboard.isKeyReleased(A) && !keyboard.isKeyDown(A), "a tap within a frame: pressed and released");

		frame([MouseDown(Left, 10, 20), Wheel(0, 2), Wheel(1, -1)]);
		check(mouse.isButtonDown(Left) && mouse.isButtonPressed(Left) && mouse.x == 10 && mouse.y == 20, "a mouse button, where");
		check(mouse.wheelX == 1 && mouse.wheelY == 1, "the wheel summed over the frame");
		frame([MouseMove(30, 40)]);
		check(mouse.wheelY == 0 && mouse.x == 30 && mouse.isButtonDown(Left), "the wheel per frame; the mouse moves");
		frame([KeyDown(W, false), FocusLost]);
		check(!keyboard.isKeyDown(W) && keyboard.isKeyReleased(W) && !mouse.isButtonDown(Left) && mouse.isButtonReleased(Left),
			"focus lost lets go of what's held");

		frame([PadButtonDown(0, South)]);
		check(pads.isButtonDown(0, South) && pads.isButtonPressed(0, South) && !pads.isButtonDown(1, South), "a pad's button");
		frame([PadDisconnected(0)]);
		check(!pads.isButtonDown(0, South) && pads.isButtonReleased(0, South), "a pad gone lets go of its buttons");

		events.axes[0] = .1;
		frame();
		check(pads.getAxis(0, LeftX) == 0, "inside the dead zone: 0");
		events.axes[0] = 1;
		frame();
		check(pads.getAxis(0, LeftX) == 1, "pushed all the way: 1");
		events.axes[0] = .15;
		events.axes[1] = .15;
		frame();
		check(pads.getAxis(0, LeftX) > 0, "a diagonal past the round dead zone counts on each axis");
		events.axes[0] = 0;
		events.axes[1] = 0;
		events.axes[4] = .6;
		frame();
		check(Math.abs(pads.getAxis(0, LeftTrigger) - .5) < 1e-9, "a trigger past the dead zone, scaled to reach 1");
		events.axes[4] = 0;
		pads.deadZone = 2;
		check(pads.deadZone == 1, "the dead zone is clamped to 1, and reads back so");
		events.axes[0] = 1;
		frame();
		check(pads.getAxis(0, LeftX) == 1, "a dead zone of 1 still lets a full push through");
		events.axes[0] = 0;
		frame();
		pads.deadZone = .2;
		check(pads.getAxis(9, LeftX) == 0, "a slot past 3 reads 0");

		var actions = new Actions([keyboard, mouse, pads, tilt]);
		check(actions.bind("jump", Keyboard(Space), Pad(0, South)), "bind: some new");
		check(!actions.bind("jump", Keyboard(Space)), "bind: none new");
		check(actions.getBindings("jump").length == 2 && actions.getBindings("none").length == 0, "the bindings, a copy");
		frame([KeyDown(Space, false)]);
		check(actions.isDown("jump") && actions.isPressed("jump"), "an action pressed");
		frame([PadButtonDown(0, South)]);
		check(actions.isDown("jump") && !actions.isPressed("jump"), "a second binding while one is held isn't another press");
		frame([KeyUp(Space)]);
		check(actions.isDown("jump") && !actions.isReleased("jump"), "one let go while another holds: not released");
		frame([PadButtonUp(0, South)]);
		check(!actions.isDown("jump") && actions.isReleased("jump"), "the last let go: released");
		check(!actions.isDown("none") && actions.getValue("none") == 0, "a name with nothing bound");

		actions.bind("left", Keyboard(Left), Axis(0, LeftX, Negative));
		actions.bind("right", Keyboard(Right), Axis(0, LeftX, Positive));
		actions.bind("up", Keyboard(Up));
		actions.bind("down", Keyboard(Down));
		events.axes[0] = -1;
		frame();
		check(actions.isPressed("left") && actions.getValue("left") == 1 && actions.getAxis("left", "right") == -1, "an axis as a button");
		frame();
		check(actions.isDown("left") && !actions.isPressed("left"), "held on the next frame: not pressed again");
		events.axes[0] = 0;
		frame();
		check(actions.isReleased("left"), "an axis let go: released");

		frame([KeyDown(Right, false), KeyDown(Down, false)]);
		var move = new Point2D();
		check(actions.computeVector("left", "right", "up", "down", move) == move, "computeVector fills the point given");
		check(Math.abs(Math.sqrt(move.x * move.x + move.y * move.y) - 1) < 1e-9 && move.x > 0 && move.y > 0, "a diagonal capped at 1");
		frame([KeyUp(Down)]);
		check(actions.computeVector("left", "right", "up", "down").x == 1, "straight: 1, a new point");

		check(actions.unbind("left", ...actions.getBindings("left")) && actions.getBindings("left").length == 0, "unbind every one");
		check(!actions.unbind("left", Keyboard(Left)), "unbind what isn't bound: false");
		actions.unbindAll();
		check(actions.getBindings("jump").length == 0, "unbindAll: none left");
		// Tilt: asked through the events, level taken once held steady for half a second, then read turned with the screen.
		check(tilt.requestAccess() && events.tiltRequested && tilt.status == Off, "tilt asked for through the events");
		frame([TiltState(On), Tilt(10, 5, 0)]);
		check(tilt.status == On && tilt.calibrating && tilt.getAxis(X) == 0, "the first reading: level being taken, reading 0");
		var started = haxe.Timer.stamp();
		while (haxe.Timer.stamp() - started < .6) {}
		frame([Tilt(11, 6, 0)]);
		check(!tilt.calibrating, "held within 3 degrees for half a second: level taken");
		frame([Tilt(26, 21, 0)]);
		check(Math.abs(tilt.getAxis(Y) - .5) < 1e-9 && Math.abs(tilt.getAxis(X) - .5) < 1e-9, "15 degrees of 30 from level: 0.5 each way");
		frame([Tilt(11, 66, 0)]);
		check(tilt.getAxis(X) == 1, "past tiltRange: clamped to 1");
		actions.bind("roll", Tilt(X, Positive));
		check(actions.isDown("roll") && actions.getValue("roll") == 1, "tilt bound as an action");
		frame([Tilt(11, 6, 90)]);
		check(tilt.calibrating && tilt.getAxis(X) == 0, "the screen turned: level taken again");
		frame([TiltState(Refused)]);
		check(tilt.status == Refused && tilt.getAxis(X) == 0, "refused: reads 0");
		tilt.range = 0;
		check(tilt.range == 1, "tiltRange clamped to at least 1");
		tilt.releaseAccess();
		check(!events.tiltRequested && tilt.getAxis(X) == 0, "tilt released: no readings, reads 0");
		var keysOnly = new Actions([keyboard]);
		keysOnly.bind("jump", Pad(0, South));
		frame([PadButtonDown(0, South)]);
		check(pads.isButtonDown(0, South) && !keysOnly.isDown("jump") && keysOnly.getValue("jump") == 0,
			"a binding to a device Actions wasn't given reads as not held");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
