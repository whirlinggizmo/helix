package helix.services.input;

import helix.math.Point2D;

/** Provides actions, which are names the game reads, such as "jump" or "left", each bound to keys, mouse buttons, gamepads and tilt.

	Any of an action's bindings works it. Actions reads the devices it was created over, so it is current once they are polled. It has no
	`poll` of its own. A binding to a device it wasn't given, or a name with no bindings, reads as not held, with a value of 0.

	```haxe
	var keyboard = new Keyboard(events), pads = new Gamepads(events);
	var actions = new Actions([keyboard, pads]);
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
	final devices:Array<IActionDevice>;
	final bindings = new Map<String, Array<Binding>>();

	/** Creates actions with nothing bound, over the devices the game made.

		@param devices  The devices its bindings are read from: any of `Keyboard`, `Mouse`, `Gamepads` and `Tilt`. */
	public function new(devices:Array<IActionDevice>) {
		this.devices = devices.copy();
	}

	/** Binds a name to keys, buttons or sticks, in addition to its existing bindings.

		An existing array is passed as `...bindings`.

		@param name  The action's name.
		@param bindings  One or more bindings that work the action.
		@return  False when the name was already bound to every one of them. Any new ones are bound either way. */
	public function bind(name:String, ...bindings:Binding):Bool {
		var bound = this.bindings.get(name);
		if (bound == null)
			this.bindings.set(name, bound = []);
		var added = false;
		for (binding in bindings)
			if (!contains(bound, binding)) {
				bound.push(binding);
				added = true;
			}
		return added;
	}

	/** Removes bindings from a name.

		`unbind(name, ...getBindings(name))` removes every binding of one name.

		@param name  The action's name.
		@param bindings  One or more bindings that no longer work the action.
		@return  False when the name was bound to none of them. Any it was bound to are removed either way. */
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

	/** Removes every binding from every name, as before anything was bound. */
	public function unbindAll():Void {
		bindings.clear();
	}

	/** Returns a name's bindings.

		@param name  The action's name.
		@return  A copy of its bindings, in the order they were bound, or an empty array for a name with no bindings. */
	public function getBindings(name:String):Array<Binding> {
		var bound = bindings.get(name);
		return bound == null ? [] : bound.copy();
	}

	/** Returns whether an action is held, which is when any of its bindings is held.

		@param name  The action's name.
		@return  True while any of its bindings is held. */
	public function isDown(name:String):Bool {
		var bound = bindings.get(name);
		if (bound != null)
			for (binding in bound)
				if (isBindingDown(binding))
					return true;
		return false;
	}

	/** Returns whether an action began this frame, which is when one of its bindings went down while none was held before.

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

	/** Returns whether an action ended this frame, which is when its last held binding went up.

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

	/** Returns how far an action is worked.

		A held key or button is 1. A stick or trigger is its distance past the dead zone.

		@param name  The action's name.
		@return  The largest value among its bindings, 0 to 1. */
	public function getValue(name:String):Float {
		var bound = bindings.get(name);
		var most = 0.;
		if (bound != null)
			for (binding in bound) {
				var device = deviceOf(binding);
				var value = device == null ? 0 : device.getValue(binding);
				if (value > most)
					most = value;
			}
		return most;
	}

	/** Returns one axis made of two actions, such as "left" and "right".

		Two axes read this way make a diagonal longer than either axis. For movement in two directions, use `computeVector`.

		@param negative  The action toward -1.
		@param positive  The action toward 1.
		@return  The positive action's value less the negative's, -1 to 1. */
	public function getAxis(negative:String, positive:String):Float {
		return getValue(positive) - getValue(negative);
	}

	/** Returns a direction made of four actions, with its length clamped to at most 1.

		A diagonal is no faster than a straight line, and a stick pushed partway stays partway.

		@param left  The action toward -x.
		@param right  The action toward +x.
		@param up  The action toward -y.
		@param down  The action toward +y.
		@param out  Optional. The point to fill. A new point is created when omitted.
		@return  The direction. Its x is `getAxis(left, right)` and its y is `getAxis(up, down)`, scaled down when longer than 1. */
	public function computeVector(left:String, right:String, up:String, down:String, ?out:Point2D):Point2D {
		var x = getAxis(left, right), y = getAxis(up, down);
		var length = Math.sqrt(x * x + y * y);
		if (length > 1) {
			x /= length;
			y /= length;
		}
		return out == null ? new Point2D(x, y) : out.set(x, y);
	}

	// The device that reads a binding of its kind, or null when the game gave none.
	function deviceOf(binding:Binding):Null<IActionDevice> {
		for (device in devices)
			if (device.reads(binding))
				return device;
		return null;
	}

	function isBindingDown(binding:Binding):Bool {
		var device = deviceOf(binding);
		return device != null && device.getValue(binding) > 0;
	}

	// Whether it was down before this frame.
	function wasBindingDown(binding:Binding):Bool {
		var device = deviceOf(binding);
		return device != null && device.wasDown(binding);
	}

	function isBindingPressed(binding:Binding):Bool {
		var device = deviceOf(binding);
		return device != null && device.isPressed(binding);
	}

	function isBindingReleased(binding:Binding):Bool {
		var device = deviceOf(binding);
		return device != null && device.isReleased(binding);
	}

	static function contains(bound:Array<Binding>, binding:Binding):Bool {
		for (b in bound)
			if (Type.enumEq(b, binding))
				return true;
		return false;
	}
}
