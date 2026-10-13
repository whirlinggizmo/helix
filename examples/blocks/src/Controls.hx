import Game.Actions;
import helix.input.IInput;
import helix.input.Key;
import helix.input.PadButton;
import helix.input.PointerGestures;
import helix.render2d.Camera2D;

/** Keyboard, gamepad and touch into one tick's Actions. Touch: drag moves by whole cells, tap turns, flick down drops, flick up holds. */
class Controls {
	public static inline var REPEAT_DELAY = 10;
	public static inline var REPEAT_EVERY = 2;

	public var actions(default, null) = new Actions();
	public var gestures(default, null) = new PointerGestures();

	var heldLeft = 0;
	var heldRight = 0;
	var anchorX = 0.;
	var anchorY = 0.;

	public function new() {}

	/** Moves for a direction held this many ticks: one at once, then repeats after a delay. */
	static function repeats(ticks:Int):Int
		return ticks == 1 || ticks > REPEAT_DELAY && (ticks - REPEAT_DELAY) % REPEAT_EVERY == 0 ? 1 : 0;

	public function read(input:IInput, tick:Int, game:Game, layout:Layout, camera:Camera2D):Actions {
		var a = actions;
		a.clear();
		a.start = input.isPressed(Key.Enter) || input.isPressed(Key.Space) && game.state != "playing" || input.isPadPressed(PadButton.Start)
			&& game.state != "playing";
		a.pause = game.state != "title"
			&& game.state != "over"
			&& (input.isPressed(Key.Escape) || input.isPressed(Key.P) || input.isPadPressed(PadButton.Start) && game.state == "playing");
		var left = input.isDown(Key.Left) || input.isDown(Key.A) || input.isPadDown(PadButton.Left),
			right = input.isDown(Key.Right) || input.isDown(Key.D) || input.isPadDown(PadButton.Right);
		heldLeft = left ? heldLeft + 1 : 0;
		heldRight = right ? heldRight + 1 : 0;
		if (heldLeft > 0 && (heldRight == 0 || heldLeft < heldRight))
			a.left = repeats(heldLeft);
		else if (heldRight > 0)
			a.right = repeats(heldRight);
		a.softDrop = input.isDown(Key.Down) || input.isDown(Key.S) || input.isPadDown(PadButton.Down);
		a.rotateClockwise = input.isPressed(Key.Up) || input.isPressed(Key.X) || input.isPressed(Key.W) || input.isPadPressed(PadButton.South);
		a.rotateCounter = input.isPressed(Key.Z) || input.isPadPressed(PadButton.East);
		a.hardDrop = game.state == "playing" && input.isPressed(Key.Space) || input.isPadPressed(PadButton.Up);
		a.hold = input.isPressed(Key.C) || input.isPressed(Key.Shift) || input.isPadPressed(PadButton.RightBumper);
		touch(input, tick, game, layout, camera);
		return a;
	}

	function touch(input:IInput, tick:Int, game:Game, layout:Layout, camera:Camera2D):Void {
		var g = gestures, a = actions, cell = camera.getZoom();
		g.setSlop(cell * .4);
		g.update(input, tick / 60);
		if (g.isPressed()) {
			anchorX = g.getX();
			anchorY = g.getY();
		}
		var wx = camera.screenToWorldX(g.getX()),
			wy = camera.screenToWorldY(g.getY());
		// Off the field, any tap starts, restarts or resumes.
		if (game.state != "playing") {
			if (g.isTapped())
				a.start = true;
			return;
		}
		if (g.isTapped()) {
			if (Layout.inside(layout.pauseBox, wx, wy))
				a.pause = true;
			else if (Layout.inside(layout.holdBox, wx, wy))
				a.hold = true;
			else
				a.rotateClockwise = true;
			return;
		}
		if (g.isDown() && g.isDragging()) {
			var columns = Std.int((g.getX() - anchorX) / cell);
			if (columns > 0)
				a.right += columns;
			else if (columns < 0)
				a.left -= columns;
			anchorX += columns * cell;
			var rows = Std.int((g.getY() - anchorY) / cell);
			if (rows > 0) {
				a.dropRows += rows;
				anchorY += rows * cell;
			}
		}
		if (g.isReleased() && g.isDragging()) {
			var fast = cell * 25;
			if (g.getFlickY() > fast && g.getFlickY() > Math.abs(g.getFlickX()) * 2)
				a.hardDrop = true;
			else if (-g.getFlickY() > fast && -g.getFlickY() > Math.abs(g.getFlickX()) * 2)
				a.hold = true;
		}
	}
}
