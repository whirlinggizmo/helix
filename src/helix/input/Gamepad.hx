package helix.input;

/** One gamepad slot. Edges work as the keyboard's: tick edges until consume(), frame edges until the frame ends.
	Sticks read past a radial dead zone, rescaled so they still reach 1; getRawAxis reads them as the pad reports. */
class Gamepad {
	var connected = false;
	var name = "";
	var deadzone = .15;
	var held = [for (_ in 0...PadButton.COUNT) false];
	var pushes = [for (_ in 0...PadButton.COUNT) 0];
	var lifts = [for (_ in 0...PadButton.COUNT) 0];
	var framePushes = [for (_ in 0...PadButton.COUNT) false];
	var frameLifts = [for (_ in 0...PadButton.COUNT) false];
	var axes = [for (_ in 0...PadAxis.COUNT) 0.];

	/** An empty slot. */
	public function new() {}

	/** Whether a pad is in this slot; natively, only while the window has the focus. */
	public function isConnected():Bool
		return connected;

	/** The pad's name as the platform reports it; empty when the slot is empty. */
	public function getName():String
		return name;

	/** Fraction of a stick's reach that reads as centred. */
	public function getDeadzone():Float
		return deadzone;

	/** False for a value outside 0 (none) to just under 1. */
	public function setDeadzone(value:Float):Bool {
		if (!(value >= 0 && value < 1))
			return false;
		deadzone = value;
		return true;
	}

	/** Whether the button is held now. */
	public function isDown(button:PadButton):Bool
		return held[button];

	/** The button went down: a counted tick edge, as a key's, so two presses between ticks reach two ticks. */
	public function isPressed(button:PadButton):Bool
		return pushes[button] > 0;

	/** The button came up: a counted tick edge. */
	public function isReleased(button:PadButton):Bool
		return lifts[button] > 0;

	/** The button went down this frame: a frame edge. */
	public function isFramePressed(button:PadButton):Bool
		return framePushes[button];

	/** The button came up this frame: a frame edge. */
	public function isFrameReleased(button:PadButton):Bool
		return frameLifts[button];

	/** The axis as the pad reports it, without the dead zone: sticks -1..1, triggers 0..1. */
	public function getRawAxis(axis:PadAxis):Float
		return axes[axis];

	/** A stick axis past the radial dead zone, rescaled to reach 1, -1..1; a trigger as reported, 0..1. */
	public function getAxis(axis:PadAxis):Float {
		if (axis == PadAxis.LeftTrigger || axis == PadAxis.RightTrigger)
			return axes[axis];
		var left = axis == PadAxis.LeftX || axis == PadAxis.LeftY,
			x = axes[left ? PadAxis.LeftX : PadAxis.RightX],
			y = axes[left ? PadAxis.LeftY : PadAxis.RightY];
		var length = Math.sqrt(x * x + y * y);
		if (length <= deadzone)
			return 0;
		var scale = Math.min(1, (length - deadzone) / (1 - deadzone)) / length;
		return axes[axis] * scale;
	}

	/** Fills the slot with a named pad (true) or empties it (false), for adapters; emptying lets go of every button and centres every axis. */
	public function connect(value:Bool, name:String):Void {
		if (connected && !value)
			for (button in PadButton.all)
				buttonEvent(button, false);
		connected = value;
		this.name = value ? name : "";
		if (!value)
			for (i in 0...axes.length)
				axes[i] = 0;
	}

	/** A button's state from the adapter; going down sets both press edges. */
	public function buttonEvent(button:PadButton, value:Bool):Void {
		if (value && !held[button]) {
			pushes[button]++;
			framePushes[button] = true;
		}
		if (!value && held[button]) {
			lifts[button]++;
			frameLifts[button] = true;
		}
		held[button] = value;
	}

	/** An axis's value from the adapter, clamped to -1..1 for a stick and 0..1 for a trigger. */
	public function axisEvent(axis:PadAxis, value:Float):Void
		axes[axis] = Math.max(axis == PadAxis.LeftTrigger || axis == PadAxis.RightTrigger ? 0 : -1, Math.min(1, value));

	/** Clears the tick edges; the input's consume() calls it after each tick. */
	public function consume():Void
		for (i in 0...pushes.length) {
			if (pushes[i] > 0)
				pushes[i]--;
			if (lifts[i] > 0)
				lifts[i]--;
		}

	/** Clears the frame edges; the input's endFrame() calls it after each frame. */
	public function endFrame():Void
		for (i in 0...framePushes.length) {
			framePushes[i] = false;
			frameLifts[i] = false;
		}
}
