package helix.ray.internal;

import helix.ray.AutomationEvent;
import helix.ray.AutomationEventList;
import helix.ray.raylib.RCore;
import helix.ray.raylib.RAsync;

/** Holds raylib's automation events: the input as raylib keeps it, which the input functions read once automation is used, the list
	recorded into, and the recording and playing of events, as raylib's rcore does them.

	raylib keeps each key's, button's and finger's state from the last event that changed it, and an event played changes it as a real
	one does. So once automation is used, the input functions read the state here: brought up to date after each poll from the devices
	where they changed (the mouse wheel and the gamepads every poll, as raylib reads them), and changed by `play`. */
@:noCompletion
class Automation {
	/** The automation in use, or null before a list is set or an event played. */
	public static var active:Null<Automation> = null;

	/** Gets the automation, made at its first use with the devices it reads, and the input as they have it now.

		@return  The automation. */
	public static function use():Automation {
		if (active == null) {
			active = new Automation();
			Runtime.mirroring = active.mirror;
		}
		return active;
	}

	/** raylib's event types' names, as `ExportAutomationEventList` writes them. */
	public static final TYPE_NAMES = [
		"EVENT_NONE",
		"INPUT_KEY_UP",
		"INPUT_KEY_DOWN",
		"INPUT_KEY_PRESSED",
		"INPUT_KEY_RELEASED",
		"INPUT_MOUSE_BUTTON_UP",
		"INPUT_MOUSE_BUTTON_DOWN",
		"INPUT_MOUSE_POSITION",
		"INPUT_MOUSE_WHEEL_MOTION",
		"INPUT_GAMEPAD_CONNECT",
		"INPUT_GAMEPAD_DISCONNECT",
		"INPUT_GAMEPAD_BUTTON_UP",
		"INPUT_GAMEPAD_BUTTON_DOWN",
		"INPUT_GAMEPAD_AXIS_MOTION",
		"INPUT_TOUCH_UP",
		"INPUT_TOUCH_DOWN",
		"INPUT_TOUCH_POSITION",
		"INPUT_GESTURE",
		"WINDOW_CLOSE",
		"WINDOW_MAXIMIZE",
		"WINDOW_MINIMIZE",
		"WINDOW_RESIZE",
		"ACTION_TAKE_SCREENSHOT",
		"ACTION_SETTARGETFPS"
	];

	/** raylib's MAX_AUTOMATION_EVENTS: the most a list holds. */
	public static inline final CAPACITY = 16384;

	static inline final KEYS = 512;
	static inline final BUTTONS = 8;
	static inline final TOUCHES = 8;
	static inline final PADS = 4;
	static inline final PAD_BUTTONS = 32;
	static inline final PAD_AXES = 8;
	// raylib's MAX_KEY_PRESSED_QUEUE.
	static inline final KEY_QUEUE = 16;

	/** The list recorded into, as `SetAutomationEventList` sets it. */
	public var list:Null<AutomationEventList> = null;

	/** Whether each frame's input is recorded into the list as the frame ends. */
	public var recording(default, set):Bool = false;

	/** What the frame counter events are stamped with is ahead of helix-ray's frames, as `SetAutomationEventBaseFrame` sets it. */
	public var frameOffset = 0;

	/** The number in the next screenshot's name an event takes. */
	public var screenshots = 0;

	/** Each key down, by its number on the platform (`KEY_*`, a right-hand modifier as the left-hand one), and as the last frame had it. */
	public final keys = flags(KEYS);

	public final previousKeys = flags(KEYS);

	/** Each mouse button down (`MOUSE_BUTTON_*`), a finger as the left one, and as the last frame had it. */
	public final buttons = flags(BUTTONS);

	public final previousButtons = flags(BUTTONS);

	/** The mouse's position, in the screen's pixels before `SetMouseOffset` and `SetMouseScale`, and the last frame's. */
	public var mouseX = 0.;

	public var mouseY = 0.;
	public var previousMouseX = 0.;
	public var previousMouseY = 0.;

	/** How far the wheel turned this frame, and the last frame. */
	public var wheelX = 0.;

	public var wheelY = 0.;
	public var previousWheelX = 0.;
	public var previousWheelY = 0.;

	/** Each finger down by its place, 0 for the first down, as the last frame had it, and where each is, in the screen's pixels, now and
		the last frame. */
	public final touches = flags(TOUCHES);

	public final previousTouches = flags(TOUCHES);
	public final touchX = [for (_ in 0...TOUCHES) 0.];
	public final touchY = [for (_ in 0...TOUCHES) 0.];
	public final previousTouchX = [for (_ in 0...TOUCHES) 0.];
	public final previousTouchY = [for (_ in 0...TOUCHES) 0.];

	/** Each gamepad connected, its buttons down (`GAMEPAD_BUTTON_*`, gamepad times 32 plus the button) as now and the last frame, and its
		axes (gamepad times 8 plus the axis). */
	public final pads = flags(PADS);

	public final padButtons = flags(PADS * PAD_BUTTONS);
	public final previousPadButtons = flags(PADS * PAD_BUTTONS);
	public final padAxes = [for (_ in 0...PADS * PAD_AXES) 0.];

	/** The gesture detected now (`GESTURE_*`). */
	public var gesture = 0;

	// What the devices had at the last poll, so a played state stays until they change.
	final seenKeys = flags(KEYS);
	final seenButtons = flags(BUTTONS);
	final seenTouches = flags(TOUCHES);
	final seenTouchX = [for (_ in 0...TOUCHES) 0.];
	final seenTouchY = [for (_ in 0...TOUCHES) 0.];
	var seenMouseX = 0.;
	var seenMouseY = 0.;
	var seenGesture = 0;

	function new() {
		// Before InitWindow there are no devices: the state is all up until the first poll.
		if (Runtime.events == null)
			return;
		Runtime.mouse();
		Runtime.gamepads();
		for (k in 0...KEYS) {
			keys[k] = seenKeys[k] = RCore.realKeyDown(k);
			previousKeys[k] = keys[k] ? !RCore.realKeyPressed(k) : RCore.realKeyReleased(k);
		}
		for (b in 0...BUTTONS) {
			buttons[b] = seenButtons[b] = RCore.realButtonDown(b);
			previousButtons[b] = buttons[b] ? !RCore.realButtonPressed(b) : RCore.realButtonReleased(b);
		}
		var pointer = RCore.realPointer();
		mouseX = previousMouseX = seenMouseX = pointer.x;
		mouseY = previousMouseY = seenMouseY = pointer.y;
		readTouches();
		for (i in 0...TOUCHES) {
			previousTouches[i] = touches[i];
			previousTouchX[i] = touchX[i];
			previousTouchY[i] = touchY[i];
		}
		readPads();
		for (i in 0...padButtons.length)
			previousPadButtons[i] = padButtons[i];
		gesture = seenGesture = RCore.realGesture();
	}

	function set_recording(value:Bool):Bool {
		Runtime.recording = value ? record : null;
		return recording = value;
	}

	// After each poll: the last frame's state kept as the previous, and each state taken from the devices where they changed it.
	function mirror():Void {
		for (k in 0...KEYS) {
			previousKeys[k] = keys[k];
			var down = RCore.realKeyDown(k);
			if (down != seenKeys[k])
				keys[k] = seenKeys[k] = down;
		}
		for (b in 0...BUTTONS) {
			previousButtons[b] = buttons[b];
			var down = RCore.realButtonDown(b);
			if (down != seenButtons[b])
				buttons[b] = seenButtons[b] = down;
		}
		previousMouseX = mouseX;
		previousMouseY = mouseY;
		var pointer = RCore.realPointer();
		if (pointer.x != seenMouseX || pointer.y != seenMouseY) {
			mouseX = seenMouseX = pointer.x;
			mouseY = seenMouseY = pointer.y;
		}
		previousWheelX = wheelX;
		previousWheelY = wheelY;
		var wheel = RCore.realWheel();
		wheelX = wheel.x;
		wheelY = wheel.y;
		for (i in 0...TOUCHES) {
			previousTouches[i] = touches[i];
			previousTouchX[i] = touchX[i];
			previousTouchY[i] = touchY[i];
		}
		readTouches();
		for (i in 0...padButtons.length)
			previousPadButtons[i] = padButtons[i];
		readPads();
		var now = RCore.realGesture();
		if (now != seenGesture)
			gesture = seenGesture = now;
	}

	// The fingers where the devices changed them.
	function readTouches():Void {
		for (i in 0...TOUCHES) {
			var down = RCore.realTouchDown(i);
			if (down != seenTouches[i])
				touches[i] = seenTouches[i] = down;
			if (down) {
				var at = RCore.realTouchPosition(i);
				if (at.x != seenTouchX[i] || at.y != seenTouchY[i]) {
					touchX[i] = seenTouchX[i] = at.x;
					touchY[i] = seenTouchY[i] = at.y;
				}
			}
		}
	}

	// The gamepads as the devices have them now, read every poll as raylib reads them; a gamepad not connected keeps its buttons.
	function readPads():Void {
		for (pad in 0...PADS) {
			pads[pad] = RCore.realPadReady(pad);
			if (!pads[pad])
				continue;
			for (b in 0...PAD_BUTTONS)
				padButtons[pad * PAD_BUTTONS + b] = RCore.realPadButtonDown(pad, b);
			for (a in 0...PAD_AXES)
				padAxes[pad * PAD_AXES + a] = RCore.realPadAxis(pad, a);
		}
	}

	/** Returns a gamepad's axis as raylib's `GetGamepadAxisMovement` gives it: its value while the gamepad is connected, else -1 for a
		trigger and 0 for the rest.

		@param pad  The gamepad.
		@param axis  The axis.
		@return  The value. */
	public function axisMovement(pad:Int, axis:Int):Float {
		var resting = axis == 4 || axis == 5 ? -1. : 0.;
		return pad >= 0 && pad < PADS && axis >= 0 && axis < PAD_AXES && pads[pad] ? padAxes[pad * PAD_AXES + axis] : resting;
	}

	// raylib's RecordAutomationEvent: the frame's input into the list, as the frame ends.
	function record():Void {
		var l = list;
		if (l == null || l.count == l.capacity)
			return;
		for (key in 0...KEYS) {
			if (previousKeys[key] && !keys[key] && !add(l, 1, "INPUT_KEY_UP", key, 0))
				return;
			if (keys[key] && !add(l, 2, "INPUT_KEY_DOWN", key, 0))
				return;
		}
		for (button in 0...BUTTONS) {
			if (previousButtons[button] && !buttons[button] && !add(l, 5, "INPUT_MOUSE_BUTTON_UP", button, 0))
				return;
			if (buttons[button] && !add(l, 6, "INPUT_MOUSE_BUTTON_DOWN", button, 0))
				return;
		}
		if (Std.int(mouseX) != Std.int(previousMouseX) || Std.int(mouseY) != Std.int(previousMouseY))
			if (!add(l, 7, "INPUT_MOUSE_POSITION", Std.int(mouseX), Std.int(mouseY)))
				return;
		if (Std.int(wheelX) != Std.int(previousWheelX) || Std.int(wheelY) != Std.int(previousWheelY))
			if (!add(l, 8, "INPUT_MOUSE_WHEEL_MOTION", Std.int(wheelX), Std.int(wheelY)))
				return;
		for (id in 0...TOUCHES) {
			if (previousTouches[id] && !touches[id] && !add(l, 14, "INPUT_TOUCH_UP", id, 0))
				return;
			if (touches[id] && !add(l, 15, "INPUT_TOUCH_DOWN", id, 0))
				return;
			// raylib 6.2's: a finger's move, wherever it is.
			if ((Std.int(touchX[id]) != Std.int(previousTouchX[id]) || Std.int(touchY[id]) != Std.int(previousTouchY[id]))
				&& !add(l, 16, "INPUT_TOUCH_POSITION", id, Std.int(touchX[id]), Std.int(touchY[id])))
				return;
		}
		for (pad in 0...PADS) {
			for (button in 0...PAD_BUTTONS) {
				var i = pad * PAD_BUTTONS + button;
				if (previousPadButtons[i] && !padButtons[i] && !add(l, 11, "INPUT_GAMEPAD_BUTTON_UP", pad, button))
					return;
				if (padButtons[i] && !add(l, 12, "INPUT_GAMEPAD_BUTTON_DOWN", pad, button))
					return;
			}
			for (axis in 0...PAD_AXES) {
				var resting = axis == 4 || axis == 5 ? -1. : 0.;
				if (axisMovement(pad, axis) != resting
					&& !add(l, 13, "INPUT_GAMEPAD_AXIS_MOTION", pad, axis, Std.int(padAxes[pad * PAD_AXES + axis] * 32768)))
					return;
			}
		}
		if (gesture != 0)
			add(l, 17, "INPUT_GESTURE", gesture, 0);
	}

	// Adds an event of this frame to the list, as raylib's does, logging it; false when the list is now full.
	function add(l:AutomationEventList, type:Int, name:String, param0:Int, param1:Int, param2:Int = 0):Bool {
		if (l.events.length <= l.count)
			l.events.push(new AutomationEvent());
		var event = l.events[l.count];
		event.frame = Runtime.frames + frameOffset;
		event.type = type;
		while (event.params.length < 4)
			event.params.push(0);
		event.params[0] = param0;
		event.params[1] = param1;
		event.params[2] = param2;
		Runtime.log(3, 'AUTOMATION: Frame: ${event.frame} | Event type: $name | Event parameters: $param0, $param1, $param2');
		l.count++;
		return l.count != l.capacity;
	}

	/** Plays an event, as raylib's `PlayAutomationEvent`: the input it holds becomes the input now, a window event or an action is done.
		Nothing is played while recording.

		@param event  The event. */
	public function play(event:AutomationEvent):Void {
		if (recording)
			return;
		var p = [for (i in 0...4) i < event.params.length ? event.params[i] : 0];
		inline function within(i:Int, size:Int):Bool
			return i >= 0 && i < size;
		switch event.type {
			case 1:
				var k = RCore.toKey(p[0]);
				if (k >= 0)
					keys[k] = false;
			case 2:
				var k = RCore.toKey(p[0]);
				if (k >= 0) {
					keys[k] = true;
					if (!previousKeys[k] && Runtime.keysPressed.length < KEY_QUEUE)
						Runtime.keysPressed.push(p[0]);
				}
			case 5:
				if (within(p[0], BUTTONS))
					buttons[p[0]] = false;
			case 6:
				if (within(p[0], BUTTONS))
					buttons[p[0]] = true;
			case 7:
				mouseX = p[0];
				mouseY = p[1];
			case 8:
				wheelX = p[0];
				wheelY = p[1];
			case 14:
				if (within(p[0], TOUCHES))
					touches[p[0]] = false;
			case 15:
				if (within(p[0], TOUCHES))
					touches[p[0]] = true;
			case 16:
				if (within(p[0], TOUCHES)) {
					touchX[p[0]] = p[1];
					touchY[p[0]] = p[2];
				}
			case 9:
				if (within(p[0], PADS))
					pads[p[0]] = true;
			case 10:
				if (within(p[0], PADS))
					pads[p[0]] = false;
			case 11:
				if (within(p[0], PADS) && within(p[1], PAD_BUTTONS))
					padButtons[p[0] * PAD_BUTTONS + p[1]] = false;
			case 12:
				if (within(p[0], PADS) && within(p[1], PAD_BUTTONS))
					padButtons[p[0] * PAD_BUTTONS + p[1]] = true;
			case 13:
				if (within(p[0], PADS) && within(p[1], PAD_AXES))
					padAxes[p[0] * PAD_AXES + p[1]] = p[2] / 32768;
			case 17:
				gesture = p[0];
			case 18:
				Runtime.shouldClose = true;
			case 19:
				RAsync.MaximizeWindowAsync();
			case 20:
				RAsync.MinimizeWindowAsync();
			case 21:
				RAsync.SetWindowSizeAsync(p[0], p[1]);
			case 22:
				RAsync.TakeScreenshotAsync('screenshot${StringTools.lpad(Std.string(screenshots), "0", 3)}.png');
				screenshots++;
			case 23:
				RCore.SetTargetFPS(p[0]);
			case _:
		}
		Runtime.log(3, 'AUTOMATION PLAY: Frame: ${event.frame} | Event type: ${event.type} | Event parameters: ${p[0]}, ${p[1]}, ${p[2]}');
	}

	static function flags(count:Int):Array<Bool> {
		return [for (_ in 0...count) false];
	}
}
