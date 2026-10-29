import helix.math.Point2D;
import helix.services.input.Actions;
import helix.services.input.Input;

/** Checks Input and Actions over fake events: keys, the mouse and pads held, pressed and released by frame; repeats ignored; focus lost
	letting go; sticks past a round dead zone; actions bound, unbound and cleared, pressed once however many bindings are held, axes as
	buttons, and movement capped at 1. */
class InputTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var events = new FakeEvents();
		var input = new Input(events);
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			input.poll();
		}

		frame([KeyDown(Space, false)]);
		check(input.isKeyDown(Space) && input.isKeyPressed(Space) && !input.isKeyReleased(Space), "a key down: held and pressed");
		frame([KeyDown(Space, true)]);
		check(input.isKeyDown(Space) && !input.isKeyPressed(Space), "held: a repeat isn't pressed again");
		frame([KeyUp(Space)]);
		check(!input.isKeyDown(Space) && input.isKeyReleased(Space), "up: released");
		frame();
		check(!input.isKeyReleased(Space), "released for one frame alone");
		frame([KeyDown(A, false), KeyUp(A)]);
		check(input.isKeyPressed(A) && input.isKeyReleased(A) && !input.isKeyDown(A), "a tap within a frame: pressed and released");

		frame([MouseDown(Left, 10, 20), Wheel(0, 2), Wheel(1, -1)]);
		check(input.isMouseDown(Left) && input.isMousePressed(Left) && input.mouseX == 10 && input.mouseY == 20, "a mouse button, where");
		check(input.wheelX == 1 && input.wheelY == 1, "the wheel summed over the frame");
		frame([MouseMove(30, 40)]);
		check(input.wheelY == 0 && input.mouseX == 30 && input.isMouseDown(Left), "the wheel per frame; the mouse moves");
		frame([KeyDown(W, false), FocusLost]);
		check(!input.isKeyDown(W) && input.isKeyReleased(W) && !input.isMouseDown(Left) && input.isMouseReleased(Left), "focus lost lets go of what's held");

		frame([PadButtonDown(0, South)]);
		check(input.isPadButtonDown(0, South) && input.isPadButtonPressed(0, South) && !input.isPadButtonDown(1, South), "a pad's button");
		frame([PadDisconnected(0)]);
		check(!input.isPadButtonDown(0, South) && input.isPadButtonReleased(0, South), "a pad gone lets go of its buttons");

		events.axes[0] = .1;
		frame();
		check(input.getPadAxis(0, LeftX) == 0, "inside the dead zone: 0");
		events.axes[0] = 1;
		frame();
		check(input.getPadAxis(0, LeftX) == 1, "pushed all the way: 1");
		events.axes[0] = .15;
		events.axes[1] = .15;
		frame();
		check(input.getPadAxis(0, LeftX) > 0, "a diagonal past the round dead zone counts on each axis");
		events.axes[0] = 0;
		events.axes[1] = 0;
		events.axes[4] = .6;
		frame();
		check(Math.abs(input.getPadAxis(0, LeftTrigger) - .5) < 1e-9, "a trigger past the dead zone, scaled to reach 1");
		events.axes[4] = 0;
		input.padDeadZone = 2;
		check(input.padDeadZone < 1, "the dead zone stays under 1");
		input.padDeadZone = .2;
		check(input.getPadAxis(9, LeftX) == 0, "a slot past 3 reads 0");

		var actions = new Actions(input);
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
		actions.clearBindings();
		check(actions.getBindings("jump").length == 0, "clearBindings: none left");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
