package helix.services.input;

import helix.math.Bounds2D;
import helix.platform.IGamepads;
import helix.platform.IPollable;
import helix.platform.IWindow;
import helix.platform.GamepadAxis;
import helix.platform.GamepadButton;

/** Provides an on-screen gamepad worked by the fingers, read as a gamepad in a slot.

	The program constructs one over its `Touch`, `IWindow` and `IGamepads`, and gives the virtual gamepad to `Gamepads` in place of the
	`IGamepads`. The program calls `poll` once a frame, after `Touch.poll` and before `Gamepads.poll`. The virtual gamepad's sticks read
	through `Gamepads.getAxis` and its buttons through `Gamepads.isButtonDown`, `isButtonPressed` and `isButtonReleased`, and both
	through `Actions`, as any gamepad's do.

	The first touch anywhere in the window plugs the virtual gamepad in. A physical gamepad plugged into the virtual gamepad's slot
	replaces the virtual gamepad. Physical gamepads fill the slots from 0, whatever slot the virtual gamepad is in. The next touch after
	the physical gamepad is unplugged plugs the virtual gamepad in again. `GamepadConnected` and `GamepadDisconnected` come from physical
	gamepads alone.

	Positions and sizes are framebuffer pixels, as `Touch` gives them. `Touch` lists every finger, a finger holding a stick or a button
	included. Drawing is the engine's: each button and each `Fixed` stick while `visible` is true, each other stick while `held`, and each
	stick's hint while `hintVisible` is true.

	```haxe
	var virtualGamepad = new VirtualGamepad(touch, window, gamepadsAdapter, 0);
	var gamepads = new Gamepads(events, virtualGamepad);
	// each frame:
	events.poll();
	touch.poll();
	virtualGamepad.poll();
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
	// The fingers the buttons captured, and those that lifted this frame.
	var buttonFingers:Array<Int> = [];
	var liftedButtonFingers:Array<Int> = [];

	/** Creates the virtual gamepad, enabled and not plugged in.

		@param touch  The fingers, polled before this each frame.
		@param window  The window, whose pixel ratio sets a stick's default radius.
		@param gamepads  The gamepads it stands in front of. They stay the program's to dispose.
		@param slot  The slot it's plugged into, 0 to 3.
		@param options  Optional. Its sticks and buttons. Two floating sticks, on the window's left and right halves, and no buttons, when
			omitted. */
	public function new(touch:Touch, window:IWindow, gamepads:IGamepads, slot:Int, ?options:VirtualGamepadOptions) {
		this.touch = touch;
		this.window = window;
		this.gamepads = gamepads;
		this.slot = slot;
		left = new VirtualStick(false);
		right = new VirtualStick(true);
		configure(options);
	}

	/** Applies options, as the constructor does. Each stick and the buttons keep the fingers they captured.

		@param options  Optional. Its sticks and buttons. Two floating sticks, on the window's left and right halves, and no buttons, when
			omitted. */
	public function configure(?options:VirtualGamepadOptions):Void {
		var all:VirtualGamepadOptions = options != null ? options : {};
		blockedBounds = all.blockedBounds != null ? all.blockedBounds : [];
		configureStick(left, all, all.left);
		configureStick(right, all, all.right);
		buttons = [
			for (own in (all.buttons != null ? all.buttons : [])) {
				var made = new VirtualButton(own.button, own.position, own.radius != null ? own.radius : 40 * window.pixelRatio);
				made.enabled = own.enabled != false;
				made;
			}
		];
	}

	// Sets a stick from its own options, then the gamepad's, then the defaults.
	function configureStick(stick:VirtualStick, all:VirtualGamepadOptions, own:Null<VirtualStickOptions>):Void {
		var mine:VirtualStickOptions = own != null ? own : {};
		stick.enabled = mine.enabled != false;
		stick.touchZone = mine.touchZone;
		var placement = mine.basePlacement != null ? mine.basePlacement : all.basePlacement;
		stick.basePlacement = placement != null ? placement : Floating;
		stick.fixedBasePosition = mine.fixedBasePosition;
		stick.radius = mine.radius != null ? mine.radius : 60 * window.pixelRatio;
		var dead = mine.deadZone != null ? mine.deadZone : all.deadZone;
		stick.deadZone = dead != null ? dead : .12;
	}

	/** Returns whether a stick or the buttons captured a finger, including a finger that lifted this frame. An engine that turns fingers
		into a mouse leaves these out.

		@param id  The finger, as `Touch` knows it.
		@return  True for a captured finger. */
	public function capturesFinger(id:Int):Bool
		return id >= 0
			&& (left.finger == id || right.finger == id || left.lifted == id || right.lifted == id || buttonFingers.indexOf(id) >= 0
				|| liftedButtonFingers.indexOf(id) >= 0);

	/** Gets or sets whether it's enabled. Turned off, the virtual gamepad is unplugged, its sticks let go and its buttons are up. Defaults to
		true. */
	public var enabled(default, set):Bool = true;

	function set_enabled(value:Bool):Bool {
		if (!value) {
			touched = false;
			left.release();
			right.release();
			letGoOfButtons();
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

	/** Gets a value indicating whether an engine draws the buttons and the `Fixed` sticks: enabled, its slot free of physical gamepads,
		and on a device with touch (`Touch.available`). */
	public var visible(get, never):Bool;

	function get_visible():Bool
		return enabled && !gamepads.isConnected(slot) && touch.available;

	/** Gets a value indicating whether an engine draws a hint at each unheld stick's base: enabled, untouched, its slot free of physical
		gamepads, and on a device with touch (`Touch.available`). The first touch ends every stick's hint. */
	public var hintVisible(get, never):Bool;

	function get_hintVisible():Bool
		return enabled && !touched && !gamepads.isConnected(slot) && touch.available;

	/** Gets the left stick, read as `LeftX` and `LeftY`. */
	public var left(default, null):VirtualStick;

	/** Gets the right stick, read as `RightX` and `RightY`. */
	public var right(default, null):VirtualStick;

	/** Gets the buttons, as the options gave them. */
	public var buttons(default, null):Array<VirtualButton>;

	/** Gets or sets bounds where a landing finger stays free, even within a stick's touch zone, such as a GUI button's bounds. The blocked bounds follow changes to these
		bounds' fields. A finger holding a stick keeps the stick when the finger moves into a blocked bound. */
	public var blockedBounds:Array<Bounds2D>;

	/** Reads the fingers `Touch` read this frame, and moves each stick and button. Call it once a frame, after `Touch.poll`. */
	public function poll():Void {
		var width = window.framebufferWidth, height = window.framebufferHeight;
		var resized = lastWidth >= 0 && (width != lastWidth || height != lastHeight);
		lastWidth = width;
		lastHeight = height;
		var alone = !(left.enabled && right.enabled);
		left.updateZone(width, height, alone);
		right.updateZone(width, height, alone);
		left.lifted = right.lifted = -1;
		liftedButtonFingers.resize(0);
		var idle = !enabled || gamepads.isConnected(slot);
		// A physical gamepad in its slot: the next touch after it leaves plugs the virtual gamepad in again.
		if (idle && enabled)
			touched = false;
		else if (touch.pressed.length > 0)
			touched = true;
		for (stick in [left, right])
			if (idle || resized || !stick.held)
				stick.release();
			else
				follow(stick);
		if (idle)
			letGoOfButtons();
		else {
			for (id in buttonFingers.copy())
				if (!touch.isFingerDown(id) || touch.isFingerReleased(id)) {
					buttonFingers.remove(id);
					liftedButtonFingers.push(id);
				}
			for (button in buttons)
				button.place(width, height);
			for (id in touch.pressed)
				land(id, touch.getX(id), touch.getY(id));
			for (button in buttons) {
				button.down = false;
				if (button.active())
					for (id in buttonFingers)
						if (button.contains(touch.getX(id), touch.getY(id)))
							button.down = true;
			}
		}
	}

	// Releases every finger the buttons captured, and every button is up.
	function letGoOfButtons():Void {
		for (id in buttonFingers)
			liftedButtonFingers.push(id);
		buttonFingers.resize(0);
		for (button in buttons)
			button.down = false;
	}

	// Moves a held stick with its finger, or hands it to a finger still down in its zone when its own lifts.
	function follow(stick:VirtualStick):Void {
		var own = stick.finger;
		if (touch.isFingerDown(own) && !touch.isFingerReleased(own)) {
			stick.moveTo(touch.getX(own), touch.getY(own));
			return;
		}
		var other = stick == left ? right : left;
		for (id in touch.fingers)
			if (id != other.finger
				&& !touch.isFingerPressed(id)
				&& buttonFingers.indexOf(id) < 0
				&& stick.zone.contains(touch.getX(id), touch.getY(id))) {
				stick.lifted = own;
				stick.take(id, touch.getX(id), touch.getY(id), true);
				return;
			}
		stick.release();
	}

	// A finger landing: on a button the buttons capture it; within a blocked bound it stays free; else the stick whose zone it's in captures it,
	// the free one where both are.
	function land(id:Int, atX:Float, atY:Float):Void {
		for (button in buttons)
			if (button.active() && button.contains(atX, atY)) {
				buttonFingers.push(id);
				return;
			}
		for (bounds in blockedBounds)
			if (bounds.contains(atX, atY))
				return;
		var inLeft = left.enabled && left.zone.contains(atX, atY),
			inRight = right.enabled && right.zone.contains(atX, atY);
		// Where the zones overlap, the free stick, else the left.
		var stick = inLeft && (!inRight || !left.held || right.held) ? left : inRight ? right : null;
		if (stick != null)
			stick.take(id, atX, atY, false);
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

	/** Returns whether a gamepad's button is down. While the virtual gamepad is plugged in, its slot's buttons are the virtual buttons.

		@param slot  The slot, 0 to 3.
		@param button  The button.
		@return  True while it's down. */
	public function isButtonDown(slot:Int, button:GamepadButton):Bool {
		if (slot != this.slot || !pluggedIn)
			return gamepads.isButtonDown(slot, button);
		for (made in buttons)
			if (made.down && made.button == button)
				return true;
		return false;
	}

	/** Returns a gamepad's axis. While the virtual gamepad is plugged in, its slot's sticks are the virtual sticks, and its triggers
		are 0.

		@param slot  The slot, 0 to 3.
		@param axis  The axis.
		@return  -1 to 1 for a stick, right and down positive. 0 to 1 for a trigger. */
	public function getAxis(slot:Int, axis:GamepadAxis):Float {
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

	/** Lets go of its sticks and buttons. The gamepads it stands in front of stay the program's. */
	public function dispose():Void {
		left.release();
		right.release();
		letGoOfButtons();
	}
}
