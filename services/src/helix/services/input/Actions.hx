package helix.services.input;

import haxe.exceptions.NotImplementedException;
import helix.math.Point2D;

/** Provides actions: names the game reads ("jump", "left"), each bound to keys, mouse buttons and gamepads, any of which works it.

	It reads the `Input` it was made over, so it is current once that is polled; it has no `poll` of its own. A name nothing is bound to
	reads as not held and 0.

	```haxe
	actions.bind("jump", Keyboard(Space), Pad(0, South));
	actions.bind("left", Keyboard(Left), Keyboard(A), Axis(0, LeftX, Negative));
	actions.bind("right", Keyboard(Right), Keyboard(D), Axis(0, LeftX, Positive));
	actions.bind("up", Keyboard(Up), Keyboard(W), Axis(0, LeftY, Negative));
	actions.bind("down", Keyboard(Down), Keyboard(S), Axis(0, LeftY, Positive));
	var move = new Point2D();
	// each frame:
	if (actions.isPressed("jump")) jump();
	actions.computeVector("left", "right", "up", "down", move);
	x += speed * move.x * clock.delta;
	y += speed * move.y * clock.delta;
	``` */
class Actions {
	/** Creates actions with nothing bound.

		@param input  The state the actions read. */
	public function new(input:Input) {
		throw new NotImplementedException();
	}

	/** Binds a name to keys, buttons or sticks, beside what it's already bound to.

		An array already made is passed as `...bindings`.
		@param name  The action's name.
		@param bindings  What works it, one or more.
		@return  False when it was already bound to every one of them; any it wasn't are bound either way. */
	public function bind(name:String, ...bindings:Binding):Bool {
		throw new NotImplementedException();
	}

	/** Takes one binding off a name.

		@param name  The action's name.
		@param binding  What no longer works it.
		@return  False, changing nothing, when it wasn't bound to that. */
	public function unbind(name:String, binding:Binding):Bool {
		throw new NotImplementedException();
	}

	/** Takes every binding off a name.

		@param name  The action's name. */
	public function clear(name:String):Void {
		throw new NotImplementedException();
	}

	/** Returns what a name is bound to.

		@param name  The action's name.
		@return  A copy of its bindings, in the order they were bound; empty for a name nothing is bound to. */
	public function getBindings(name:String):Array<Binding> {
		throw new NotImplementedException();
	}

	/** Returns whether an action is held: any of its bindings is.

		@param name  The action's name.
		@return  True while any is held. */
	public function isDown(name:String):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether an action began this frame: one of its bindings went down while none was held.

		@param name  The action's name.
		@return  True for that frame alone, once per press. */
	public function isPressed(name:String):Bool {
		throw new NotImplementedException();
	}

	/** Returns whether an action ended this frame: its last held binding went up.

		@param name  The action's name.
		@return  True for that frame alone. */
	public function isReleased(name:String):Bool {
		throw new NotImplementedException();
	}

	/** Returns how far an action is worked: a key or button held is 1, a stick its distance past the dead zone.

		@param name  The action's name.
		@return  The most of its bindings, 0 to 1. */
	public function getValue(name:String):Float {
		throw new NotImplementedException();
	}

	/** Returns one axis made of two actions, such as "left" and "right".

		Two axes read this way make a diagonal longer than either: for movement in two directions, `computeVector`.
		@param negative  The action toward -1.
		@param positive  The action toward 1.
		@return  The positive action's value less the negative's, -1 to 1. */
	public function getAxis(negative:String, positive:String):Float {
		throw new NotImplementedException();
	}

	/** Returns a direction made of four actions, its length held to at most 1, so a diagonal is no faster than a straight line and a stick
		pushed partway stays partway.

		@param left  The action toward -x.
		@param right  The action toward +x.
		@param up  The action toward -y.
		@param down  The action toward +y.
		@param out  Optional. The point to fill; a new one when left out.
		@return  The direction: x is `getAxis(left, right)` and y `getAxis(up, down)`, scaled down when longer than 1. */
	public function computeVector(left:String, right:String, up:String, down:String, ?out:Point2D):Point2D {
		throw new NotImplementedException();
	}
}
