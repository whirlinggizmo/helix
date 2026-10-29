package helix.services.input;

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
	x += speed * move.x * time.delta;
	y += speed * move.y * time.delta;
	``` */
class Actions {
	final input:Input;
	final bindings = new Map<String, Array<Binding>>();

	/** Creates actions with nothing bound.

		@param input  The state the actions read. */
	public function new(input:Input) {
		this.input = input;
	}

	/** Binds a name to keys, buttons or sticks, beside what it's already bound to.

		An array already made is passed as `...bindings`.
		@param name  The action's name.
		@param bindings  What works it, one or more.
		@return  False when it was already bound to every one of them; any it wasn't are bound either way. */
	public function bind(name:String, ...bindings:Binding):Bool {
		var bound = this.bindings.get(name);
		if (bound == null)
			this.bindings.set(name, bound = []);
		var added = false;
		for (binding in bindings)
			if (!has(bound, binding)) {
				bound.push(binding);
				added = true;
			}
		return added;
	}

	/** Takes bindings off a name.

		Every binding of one name comes off as `unbind(name, ...getBindings(name))`.
		@param name  The action's name.
		@param bindings  What no longer works it, one or more.
		@return  False when it was bound to none of them; any it was are taken off either way. */
	public function unbind(name:String, ...bindings:Binding):Bool {
		var bound = this.bindings.get(name);
		if (bound == null)
			return false;
		var removed = false;
		for (binding in bindings)
			for (i in 0...bound.length)
				if (Type.enumEq(bound[i], binding)) {
					bound.splice(i, 1);
					removed = true;
					break;
				}
		if (bound.length == 0)
			this.bindings.remove(name);
		return removed;
	}

	/** Takes every binding off every name, as before anything was bound. */
	public function unbindAll():Void {
		bindings.clear();
	}

	/** Returns what a name is bound to.

		@param name  The action's name.
		@return  A copy of its bindings, in the order they were bound; empty for a name nothing is bound to. */
	public function getBindings(name:String):Array<Binding> {
		var bound = bindings.get(name);
		return bound == null ? [] : bound.copy();
	}

	/** Returns whether an action is held: any of its bindings is.

		@param name  The action's name.
		@return  True while any is held. */
	public function isDown(name:String):Bool {
		var bound = bindings.get(name);
		if (bound != null)
			for (binding in bound)
				if (isBindingDown(binding))
					return true;
		return false;
	}

	/** Returns whether an action began this frame: one of its bindings went down while none was held.

		@param name  The action's name.
		@return  True for that frame alone, once per press. */
	public function isPressed(name:String):Bool {
		var bound = bindings.get(name);
		if (bound == null)
			return false;
		var pressed = false;
		for (binding in bound) {
			if (wasBindingDown(binding))
				return false;
			if (isBindingPressed(binding))
				pressed = true;
		}
		return pressed;
	}

	/** Returns whether an action ended this frame: its last held binding went up.

		@param name  The action's name.
		@return  True for that frame alone. */
	public function isReleased(name:String):Bool {
		var bound = bindings.get(name);
		if (bound == null)
			return false;
		var released = false;
		for (binding in bound) {
			if (isBindingDown(binding))
				return false;
			if (isBindingReleased(binding))
				released = true;
		}
		return released;
	}

	/** Returns how far an action is worked: a key or button held is 1, a stick its distance past the dead zone.

		@param name  The action's name.
		@return  The most of its bindings, 0 to 1. */
	public function getValue(name:String):Float {
		var bound = bindings.get(name);
		var most = 0.;
		if (bound != null)
			for (binding in bound) {
				var value = switch binding {
					case Axis(slot, axis, direction): side(input.getPadAxis(slot, axis), direction);
					case _: isBindingDown(binding) ? 1 : 0;
				}
				if (value > most)
					most = value;
			}
		return most;
	}

	/** Returns one axis made of two actions, such as "left" and "right".

		Two axes read this way make a diagonal longer than either: for movement in two directions, `computeVector`.
		@param negative  The action toward -1.
		@param positive  The action toward 1.
		@return  The positive action's value less the negative's, -1 to 1. */
	public function getAxis(negative:String, positive:String):Float {
		return getValue(positive) - getValue(negative);
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
		var x = getAxis(left, right), y = getAxis(up, down);
		var length = Math.sqrt(x * x + y * y);
		if (length > 1) {
			x /= length;
			y /= length;
		}
		return out == null ? new Point2D(x, y) : out.set(x, y);
	}

	function isBindingDown(binding:Binding):Bool {
		return switch binding {
			case Keyboard(key): input.isKeyDown(key);
			case Mouse(button): input.isMouseDown(button);
			case Pad(slot, button): input.isPadButtonDown(slot, button);
			case Axis(slot, axis, direction): side(input.getPadAxis(slot, axis), direction) > 0;
		}
	}

	// Whether it was down before this frame: held and not pressed now, or let go now after being held.
	function wasBindingDown(binding:Binding):Bool {
		return switch binding {
			case Keyboard(key): (input.isKeyDown(key) || input.isKeyReleased(key)) && !input.isKeyPressed(key);
			case Mouse(button): (input.isMouseDown(button) || input.isMouseReleased(button)) && !input.isMousePressed(button);
			case Pad(slot, button): (input.isPadButtonDown(slot, button) || input.isPadButtonReleased(slot, button)) && !input.isPadButtonPressed(slot, button);
			case Axis(slot, axis, direction): side(input.getLastPadAxis(slot, axis), direction) > 0;
		}
	}

	function isBindingPressed(binding:Binding):Bool {
		return switch binding {
			case Keyboard(key): input.isKeyPressed(key);
			case Mouse(button): input.isMousePressed(button);
			case Pad(slot, button): input.isPadButtonPressed(slot, button);
			case Axis(_, _, _): isBindingDown(binding) && !wasBindingDown(binding);
		}
	}

	function isBindingReleased(binding:Binding):Bool {
		return switch binding {
			case Keyboard(key): input.isKeyReleased(key);
			case Mouse(button): input.isMouseReleased(button);
			case Pad(slot, button): input.isPadButtonReleased(slot, button);
			case Axis(_, _, _): wasBindingDown(binding) && !isBindingDown(binding);
		}
	}

	static function side(value:Float, direction:AxisDirection):Float {
		var toward = direction == Negative ? -value : value;
		return toward > 0 ? toward : 0;
	}

	static function has(bound:Array<Binding>, binding:Binding):Bool {
		for (b in bound)
			if (Type.enumEq(b, binding))
				return true;
		return false;
	}
}
