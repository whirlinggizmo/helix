package helix.services.input;

import helix.math.Bounds2D;
import helix.platform.IGamepads;
import helix.platform.IPollable;
import helix.platform.IWindow;
import helix.platform.PadAxis;
import helix.platform.PadButton;

/** Provides an on-screen gamepad worked by the fingers, read as a gamepad in a slot.

	The program constructs one over its `Touch`, `IWindow` and `IGamepads`, and gives the virtual gamepad to `Gamepads` in place of the
	`IGamepads`. The program calls `poll` once a frame, after `Touch.poll` and before `Gamepads.poll`. The virtual gamepad's sticks read
	through `Gamepads.getAxis` and `Actions`, as any gamepad's do.

	The first touch anywhere in the window plugs the virtual gamepad in. A physical gamepad plugged into the virtual gamepad's slot
	replaces the virtual gamepad. Physical gamepads fill the slots from 0, whatever slot the virtual gamepad is in. The next touch after
	the physical gamepad is unplugged plugs the virtual gamepad in again. `PadConnected` and `PadDisconnected` come from physical
	gamepads alone.

	Positions and sizes are framebuffer pixels, as `Touch` gives them. `Touch` lists every finger, a finger holding a stick included.
	Drawing is the engine's, from each stick's `held`, base, knob and radius. An engine draws the hints while `hintVisible` is true and
	the device has a touch screen.

	```haxe
	var virtualPad = new VirtualGamepad(touch, window, gamepadsAdapter, 0);
	var gamepads = new Gamepads(events, virtualPad);
	// each frame:
	events.poll();
	touch.poll();
	virtualPad.poll();
	gamepads.poll();
	var moveX = gamepads.getAxis(0, LeftX);
	``` */
class VirtualGamepad implements IPollable implements IGamepads {
	final touch:Touch;
	final window:IWindow;
	final gamepads:IGamepads;
	final slot:Int;
	// Whether a touch has plugged it in since it was enabled or a physical gamepad left its slot; and the window's size when last polled.
	var touched = false;
	var lastWidth = -1;
	var lastHeight = -1;

	/** Creates the virtual gamepad, enabled and not plugged in.

		@param touch  The fingers, polled before this each frame.
		@param window  The window, whose pixel ratio sets a stick's default radius.
		@param gamepads  The gamepads it stands in front of. They stay the program's to dispose.
		@param slot  The slot it's plugged into, 0 to 3.
		@param options  Optional. Its sticks. Two floating sticks, on the window's left and right halves, when omitted. */
	public function new(touch:Touch, window:IWindow, gamepads:IGamepads, slot:Int, ?options:VirtualGamepadOptions) {
		this.touch = touch;
		this.window = window;
		this.gamepads = gamepads;
		this.slot = slot;
		left = new VirtualStick(false);
		right = new VirtualStick(true);
		var blocked = options != null ? options.blockedBounds : null;
		blockedBounds = blocked != null ? blocked : [];
		configure(left, options, options != null ? options.left : null);
		configure(right, options, options != null ? options.right : null);
	}

	// Sets a stick from its own options, then the gamepad's, then the defaults.
	function configure(stick:VirtualStick, all:Null<VirtualGamepadOptions>, own:Null<VirtualStickOptions>):Void {
		inline function pick<T>(mine:Null<T>, shared:Null<T>, fallback:T):T
			return mine != null ? mine : shared != null ? shared : fallback;
		stick.enabled = pick(own != null ? own.enabled : null, null, true);
		stick.touchZone = own != null ? own.touchZone : null;
		stick.basePlacement = pick(own != null ? own.basePlacement : null, all != null ? all.basePlacement : null, Floating);
		stick.fixedBasePosition = own != null ? own.fixedBasePosition : null;
		stick.radius = pick(own != null ? own.radius : null, null, 60 * window.pixelRatio);
		stick.deadZone = pick(own != null ? own.deadZone : null, all != null ? all.deadZone : null, .12);
	}

	/** Gets or sets whether it's enabled. Turned off, the virtual gamepad is unplugged and its sticks let go. Defaults to true. */
	public var enabled(default, set):Bool = true;

	function set_enabled(value:Bool):Bool {
		if (!value) {
			touched = false;
			left.release();
			right.release();
		}
		return enabled = value;
	}

	/** Gets a value indicating whether it's plugged in: enabled, touched, and its slot free of physical gamepads. While a physical
		gamepad is in its slot, the virtual gamepad's sticks ignore touches. */
	public var pluggedIn(get, never):Bool;

	function get_pluggedIn():Bool
		return enabled && touched && !gamepads.isConnected(slot);

	/** Gets a value indicating whether a physical gamepad is in the virtual gamepad's slot. */
	public var physicalConnected(get, never):Bool;

	function get_physicalConnected():Bool
		return gamepads.isConnected(slot);

	/** Gets a value indicating whether an engine draws a hint at each unheld stick's base: enabled, untouched, and its slot free of
		physical gamepads. The first touch ends every stick's hint. */
	public var hintVisible(get, never):Bool;

	function get_hintVisible():Bool
		return enabled && !touched && !gamepads.isConnected(slot);

	/** Gets the left stick, read as `LeftX` and `LeftY`. */
	public var left(default, null):VirtualStick;

	/** Gets the right stick, read as `RightX` and `RightY`. */
	public var right(default, null):VirtualStick;

	/** Gets or sets bounds cut out of the sticks' touch zones, such as a pause button's. The blocked bounds follow changes to these
		bounds' fields. A finger holding a stick keeps the stick when the finger moves into a blocked bound. */
	public var blockedBounds:Array<Bounds2D>;

	/** Reads the fingers `Touch` read this frame, and moves each stick. Call it once a frame, after `Touch.poll`. */
	public function poll():Void {
		var width = window.framebufferWidth, height = window.framebufferHeight;
		var resized = lastWidth >= 0 && (width != lastWidth || height != lastHeight);
		lastWidth = width;
		lastHeight = height;
		var alone = !(left.enabled && right.enabled);
		left.updateZone(width, height, alone);
		right.updateZone(width, height, alone);
		if (!enabled || gamepads.isConnected(slot)) {
			// A physical gamepad in its slot: the next touch after it leaves plugs the virtual gamepad in again.
			if (enabled)
				touched = false;
			rest(left);
			rest(right);
			return;
		}
		if (resized) {
			left.release();
			right.release();
		}
		if (touch.pressed.length > 0)
			touched = true;
		follow(left);
		follow(right);
		for (id in touch.pressed)
			land(id, touch.getX(id), touch.getY(id));
		for (stick in [left, right])
			if (!stick.held)
				stick.rest();
	}

	// Lets a stick go and rests it at its home.
	function rest(stick:VirtualStick):Void {
		stick.release();
		stick.rest();
	}

	// Moves a held stick with its finger, or hands it to a finger still down in its zone when its own lifts.
	function follow(stick:VirtualStick):Void {
		if (!stick.held)
			return;
		if (touch.isFingerDown(stick.finger) && !touch.isFingerReleased(stick.finger)) {
			stick.moveTo(touch.getX(stick.finger), touch.getY(stick.finger));
			return;
		}
		stick.release();
		var other = stick == left ? right : left;
		for (id in touch.fingers)
			if (id != other.finger && !touch.isFingerPressed(id) && stick.zone.contains(touch.getX(id), touch.getY(id))) {
				stick.handTo(id, touch.getX(id), touch.getY(id));
				return;
			}
	}

	// A finger landing: within a blocked bound it stays free; else it takes the stick whose zone it's in, the free one where both are.
	function land(id:Int, atX:Float, atY:Float):Void {
		for (bounds in blockedBounds)
			if (bounds.contains(atX, atY))
				return;
		var inLeft = left.enabled && left.zone.contains(atX, atY),
			inRight = right.enabled && right.zone.contains(atX, atY);
		var stick = inLeft
			&& inRight ? (right.held
				&& !left.held ? left : !right.held && left.held ? right : left) : inLeft ? left : inRight ? right : null;
		if (stick != null)
			stick.take(id, atX, atY);
	}

	/** Returns whether a gamepad is in a slot. The virtual gamepad's slot is true while the virtual gamepad is plugged in or a physical
		gamepad is there. See `physicalConnected` for telling them apart.

		@param slot  The slot, 0 to 3.
		@return  True when one is there. */
	public function isConnected(slot:Int):Bool
		return (slot == this.slot && pluggedIn) || gamepads.isConnected(slot);

	/** Returns the name of the gamepad in a slot. The virtual gamepad's name is "Virtual gamepad".

		@param slot  The slot, 0 to 3.
		@return  The name, or "" for an empty slot. */
	public function getName(slot:Int):String
		return slot == this.slot && pluggedIn ? "Virtual gamepad" : gamepads.getName(slot);

	/** Returns whether a gamepad's button is down. The virtual gamepad's buttons are always up.

		@param slot  The slot, 0 to 3.
		@param button  The button.
		@return  True while it's down. */
	public function isButtonDown(slot:Int, button:PadButton):Bool
		return slot == this.slot && pluggedIn ? false : gamepads.isButtonDown(slot, button);

	/** Returns a gamepad's axis. While the virtual gamepad is plugged in, its slot's sticks are the virtual sticks, and its triggers
		are 0.

		@param slot  The slot, 0 to 3.
		@param axis  The axis.
		@return  -1 to 1 for a stick, right and down positive. 0 to 1 for a trigger. */
	public function getAxis(slot:Int, axis:PadAxis):Float {
		if (slot != this.slot || !pluggedIn)
			return gamepads.getAxis(slot, axis);
		return switch axis {
			case LeftX: left.x;
			case LeftY: left.y;
			case RightX: right.x;
			case RightY: right.y;
			case _: 0;
		}
	}

	/** Shakes a physical gamepad. The virtual gamepad stays still.

		@param slot  The slot, 0 to 3.
		@param low  The low-frequency motor, 0 to 1.
		@param high  The high-frequency motor, 0 to 1.
		@param seconds  How long.
		@return  False for the virtual gamepad or an empty slot. */
	public function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool
		return slot == this.slot && pluggedIn ? false : gamepads.setVibration(slot, low, high, seconds);

	/** Adds mappings for the physical gamepads, in SDL's controller database format.

		@param mappings  The mappings.
		@return  How many were added. */
	public function addMappings(mappings:String):Int
		return gamepads.addMappings(mappings);

	/** Lets go of its sticks. The gamepads it stands in front of stay the program's. */
	public function dispose():Void {
		left.release();
		right.release();
	}
}
