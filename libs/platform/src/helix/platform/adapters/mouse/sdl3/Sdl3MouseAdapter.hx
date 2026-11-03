package helix.platform.adapters.mouse.sdl3;

import helix.platform.CursorShape;
import helix.platform.IMouse;
import helix.platform.adapters.shared.PollAnswers;
import helix.platform.adapters.shared.sdl3.Sdl3EventsBridge;

/** Provides `IMouse` on SDL3, natively: the mouse's and a pen's buttons, moves and wheel over the window, in framebuffer pixels. SDL's
	mouse made of a touch is passed over. The cursor is SDL's system cursor of each shape, and the lock is SDL's relative mouse mode,
	answered at the next `Sdl3EventsAdapter` poll. */
class Sdl3MouseAdapter implements IMouse {
	/** Turns SDL's mouse events on.

		@param options  The events adapter its events are delivered by. */
	public function new(options:Sdl3MouseAdapterOptions) {
		Sdl3EventsBridge.want(Sdl3EventsBridge.MOUSE, 1);
	}

	public var cursorVisible(get, set):Bool;

	function get_cursorVisible():Bool
		return Sdl3EventsBridge.cursorVisible() != 0;

	function set_cursorVisible(on:Bool):Bool {
		Sdl3EventsBridge.setCursorVisible(on ? 1 : 0);
		return on;
	}

	public var cursorShape(get, set):CursorShape;

	var shape = Arrow;

	function get_cursorShape():CursorShape
		return shape;

	function set_cursorShape(to:CursorShape):CursorShape {
		shape = to;
		Sdl3EventsBridge.setCursorShape(to);
		return to;
	}

	public var locked(get, never):Bool;

	function get_locked():Bool
		return Sdl3EventsBridge.locked() != 0;

	// SDL sets the relative mouse mode during the call; the answer waits for the next poll.
	public function requestLock(locked:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		var granted = Sdl3EventsBridge.setLocked(locked ? 1 : 0) != 0;
		PollAnswers.add(() -> {
			if (granted) {
				if (done != null)
					done();
			} else if (failed != null)
				failed("SDL couldn't " + (locked ? "lock" : "let go of") + " the mouse");
			return true;
		});
		return true;
	}

	public function canSetPosition():Bool
		return true;

	public function setPosition(x:Float, y:Float):Bool
		return Sdl3EventsBridge.warp(x, y) != 0;

	public function dispose():Void {
		Sdl3EventsBridge.disposeMouse();
		Sdl3EventsBridge.want(Sdl3EventsBridge.MOUSE, 0);
	}
}
