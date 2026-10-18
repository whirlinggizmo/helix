package helix.input;

import haxe.Json;
import haxe.io.Bytes;
import helix.assets.Failure;
import helix.assets.Storage;
import helix.host.Presentation;
import helix.host.Screen;

/** An action and its bindings, with whether it was down as the last frame (FRAME) and the last tick (TICK) ended. */
private typedef Action = {
	final name:String;
	var bindings:Array<Binding>;
	final was:Array<Bool>;
}

/** What the player means ("jump", "steer", "fire"), bound by name to keys, pad buttons and axes, mouse buttons and touch regions, and read as
	one: a game asks for "jump", never for Space or the south button, and a player can rebind it (capture) and keep it (save, load).

	Each binding gives a value from -1 to 1 (Binding), and the action is the binding pushed furthest, across every pad: axis its value, value
	how far (0 to 1), isDown while any binding is pushed to its limit (0.5, or a pad axis's non-zero threshold). Pressed and released come per
	tick (isPressed, isReleased) and per frame (isFramePressed, isFrameReleased), as IInput's do: an action is pressed when it is down and
	wasn't as the last tick (or frame) ended, or when a key, button or finger of it went down since (IInput's own edges, so a tap shorter than a
	tick is still a press, and two taps reach two ticks). The map keeps whether each action was down itself, told by the input as each tick
	and frame ends (IInput.watch), so a game makes no extra calls. A finger's edges are frame edges only (IInput has no tick edges for touches):
	a tap shorter than a frame reaches isFramePressed, not isPressed. An action never bound reads as up and 0, so a game's code may run
	before its bindings load.

	Built on IInput, so whatever drives the input drives the actions: the autopilot's input given to it (input) replays them. */
class Actions implements IInputWatcher {
	/** The saved format's version (save, load). */
	public static inline var VERSION = 1;

	/** How far past it a pad axis must go for capture to take it: half way, as down is for a binding without a threshold. */
	public static inline var CAPTURE_THRESHOLD = .5;

	static inline var FRAME = 0;
	static inline var TICK = 1;

	static final ANCHORS:Array<Anchor> = [TopLeft, Top, TopRight, Left, Center, Right, BottomLeft, Bottom, BottomRight];
	static final ANCHOR_NAMES = [
		"TopLeft",
		"Top",
		"TopRight",
		"Left",
		"Center",
		"Right",
		"BottomLeft",
		"Bottom",
		"BottomRight"
	];
	static final PAD_BUTTON_NAMES = [
		"South",
		"East",
		"West",
		"North",
		"LeftBumper",
		"RightBumper",
		"LeftTrigger",
		"RightTrigger",
		"Back",
		"Start",
		"LeftStick",
		"RightStick",
		"Up",
		"Down",
		"Left",
		"Right",
		"Guide"
	];
	static final PAD_BUTTON_TEXT = [
		"Pad south",
		"Pad east",
		"Pad west",
		"Pad north",
		"Left bumper",
		"Right bumper",
		"Left trigger",
		"Right trigger",
		"Pad back",
		"Pad start",
		"Left stick press",
		"Right stick press",
		"D-pad up",
		"D-pad down",
		"D-pad left",
		"D-pad right",
		"Pad guide"
	];
	static final PAD_AXIS_NAMES = ["LeftX", "LeftY", "RightX", "RightY", "LeftTrigger", "RightTrigger"];
	static final PAD_AXIS_TEXT = [
		"Left stick X",
		"Left stick Y",
		"Right stick X",
		"Right stick Y",
		"Left trigger",
		"Right trigger"
	];
	static final MOUSE_NAMES = ["Left", "Right", "Middle"];

	var actions:Array<Action> = [];
	var defaults:Map<String, Array<Binding>> = [];

	// A binding just captured (or the Escape that cancelled), read as 0 until it is seen up as a frame (FRAME) and a tick (TICK) ends, so
	// the press that was captured doesn't also fire a game action.
	var swallowed:Array<Null<Binding>> = [null, null];

	var captureName = "";
	var captureDone:Null<Binding->Void>;
	var captureCancelled:Null<Void->Void>;
	var captureArmed = false;
	var captureAxes:Array<Int> = [];

	/** Actions read from input, their touch regions placed on presentation's visible area (Screen.instance's when null). */
	public function new(input:IInput, ?presentation:Presentation) {
		this.input = input;
		this.presentation = presentation;
	}

	/** The input the actions are read from, which tells the map as each tick and frame ends; null reads every action as up. Assigning stops
		watching the input before: a game playing an autopilot's script gives it the script's input, and an Actions given up is given null. */
	public var input(default, set):Null<IInput>;

	function set_input(value:Null<IInput>):Null<IInput> {
		if (value == input)
			return value;
		if (input != null)
			input.unwatch(this);
		input = value;
		if (value != null)
			value.watch(this);
		return value;
	}

	/** Whose visible area and units touch regions are in: null for Screen's (Screen.instance), read as each finger is. Without either (a
		unit test with no runner) a touch region reads nothing; a test gives its own Presentation, whose None mode is logical pixels. */
	public var presentation:Null<Presentation>;

	/** The actions, in the order first bound; an action cleared or unbound to nothing stays. */
	public var names(get, never):Array<String>;

	function get_names():Array<String>
		return [for (a in actions) a.name];

	/** Whether capture is waiting for a press; while it is, every action reads as up. */
	public var capturing(default, null):Bool = false;

	/** The width and height of a touch region capture makes, centered where the finger landed, in the game's units (Screen's). At least 1;
		96 to begin with. */
	public var captureTouchSize(default, set):Float = 96.;

	function set_captureTouchSize(value:Float):Float {
		value = value >= 1 ? value : 1;
		captureTouchSize = value;
		return value;
	}

	/** Adds binding to the action name, making the action with its first binding. False, changing nothing, for an empty name, a binding the
		action has already, a pad axis's side not -1, 0 or 1 or threshold outside 0 to 1, or a touch region with no area or an offset that
		isn't a number. */
	public function bind(name:String, binding:Binding):Bool {
		if (name == null || name == "" || !isValid(binding))
			return false;
		var action = find(name);
		if (action == null) {
			action = {name: name, bindings: [], was: [false, false]};
			actions.push(action);
		}
		if (indexOf(action.bindings, binding) >= 0)
			return false;
		action.bindings.push(binding);
		return true;
	}

	/** Takes binding off the action name, the action kept; false for an action or binding there isn't. */
	public function unbind(name:String, binding:Binding):Bool {
		var action = find(name);
		var i = action == null ? -1 : indexOf(action.bindings, binding);
		if (i < 0)
			return false;
		action.bindings.splice(i, 1);
		return true;
	}

	/** Takes every binding off the action name, the action kept (a remap screen binds it again); false for an action there isn't. */
	public function clear(name:String):Bool {
		var action = find(name);
		if (action == null)
			return false;
		action.bindings = [];
		return true;
	}

	/** The action's bindings, in the order bound (a copy); empty for an action there isn't. */
	public function bindings(name:String):Array<Binding> {
		var action = find(name);
		return action == null ? [] : action.bindings.copy();
	}

	/** The action's value with its direction, -1 to 1: the binding pushed furthest. 0 for an action there isn't. */
	public function axis(name:String):Float {
		var action = find(name);
		if (action == null)
			return 0;
		var best = 0.;
		for (b in action.bindings) {
			var v = valueOf(b, FRAME);
			if (Math.abs(v) > Math.abs(best))
				best = v;
		}
		return best < -1 ? -1 : (best > 1 ? 1 : best);
	}

	/** How far the action is pushed, 0 to 1: axis without its direction. */
	public function value(name:String):Float
		return Math.abs(axis(name));

	/** Whether the action is held: any of its bindings pushed to 0.5, or a pad axis to its threshold when that isn't 0. */
	public function isDown(name:String):Bool {
		var action = find(name);
		return action != null && isActionDown(action, FRAME);
	}

	/** The action went down: since the last tick ended, it went down, or a key, button or mouse button of it did (a tick edge). */
	public function isPressed(name:String):Bool
		return pressed(find(name), TICK);

	/** The action came up: it was down as the last tick ended and isn't now, or a key, button or mouse button of it came up and it isn't
		down (a tick edge). */
	public function isReleased(name:String):Bool
		return released(find(name), TICK);

	/** The action went down this frame, as isPressed for the frame, a finger landing in a touch region too (a frame edge). */
	public function isFramePressed(name:String):Bool
		return pressed(find(name), FRAME);

	/** The action came up this frame, as isReleased for the frame, a finger lifting in a touch region too (a frame edge). */
	public function isFrameReleased(name:String):Bool
		return released(find(name), FRAME);

	/** Waits for the player's next press and binds it to the action name: a key, a pad button, a pad axis pushed past half way (Axis with
		its side and a threshold of CAPTURE_THRESHOLD), or a finger (a captureTouchSize square centered where it landed, anchored to the
		nearest of the visible area's nine anchors). Mouse buttons aren't captured, as the mouse works the remap screen itself. The press
		replaces the action's bindings of the same device (the keyboard's Keyboard and KeyboardPair; the pad's Pad, PadPair and Axis;
		the touch screen's TouchRegion) and leaves the others; done is then called with it. Escape cancels, calling cancelled. Presses in the frame
		capture is called in don't count (the click or tap on a Rebind button), and while it waits every action reads as up; the captured
		press, and the Escape, read as up until they are let go. False, starting nothing, for an empty name or while capturing already. */
	public function capture(name:String, done:Binding->Void, ?cancelled:Void->Void):Bool {
		if (name == null || name == "" || capturing)
			return false;
		keepDefaults();
		capturing = true;
		captureName = name;
		captureDone = done;
		captureCancelled = cancelled;
		captureArmed = false;
		return true;
	}

	/** Stops a capture waiting for a press, calling its cancelled (a remap screen's Cancel button); false when none is waiting. */
	public function cancelCapture():Bool {
		if (!capturing)
			return false;
		finishCapture(null, false);
		return true;
	}

	/** The text a remap screen shows for binding: "Space", "Left / Right", "Pad south", "D-pad left / D-pad right", "Left stick X", "Left
		stick left" (a stick with a side), "Right trigger", "Left mouse", "Touch". */
	public static function describe(binding:Binding):String
		return switch binding {
			case Keyboard(key): describeKey(key);
			case KeyboardPair(negative, positive): describeKey(negative) + " / " + describeKey(positive);
			case Pad(button): PAD_BUTTON_TEXT[button];
			case PadPair(negative, positive): PAD_BUTTON_TEXT[negative] + " / " + PAD_BUTTON_TEXT[positive];
			case Axis(axis, side, _):
				var text = PAD_AXIS_TEXT[axis];
				if (side == 0 || axis == PadAxis.LeftTrigger || axis == PadAxis.RightTrigger) text; else {
					var across = axis == PadAxis.LeftX || axis == PadAxis.RightX;
					text.substr(0, text.length - 1) + (across ? (side < 0 ? "left" : "right") : (side < 0 ? "up" : "down"));
				}
			case Mouse(button): MOUSE_NAMES[button] + " mouse";
			case TouchRegion(_, _, _, _, _): "Touch";
		}

	/** Writes every action's bindings under key in Storage, as JSON: {"version":1,"actions":{"jump":[{"key":"Space"},{"padButton":"South"}]}},
		each binding by its kind ({"keys":["Left","Right"]}, {"padButtons":["Left","Right"]}, {"padAxis":"LeftX","side":0,"threshold":0.15},
		{"mouseButton":"Left"}, {"touch":"BottomRight","x":-120,"y":-120,"width":96,"height":96}), keys by Key.getName. Then done; a failure
		(no Storage, a write refused) goes to failed, or to the log when failed is null. */
	public function save(key = "actions", ?done:Void->Void, ?failed:String->Void):Void {
		if (Storage.instance == null) {
			saveFailed(key, "No storage", failed);
			return;
		}
		Storage.write(key, Bytes.ofString(encode()), result -> switch result {
			case Written:
				if (done != null) done();
			case Failed(message):
				saveFailed(key, message, failed);
			case Cancelled:
		});
	}

	/** Reads the bindings saved under key in Storage, and replaces the bindings of each action the game has bound with the saved ones; an
		action the save names but the game doesn't bind is dropped, an action the save doesn't name keeps its bindings, and an entry the map
		can't read (an unknown kind or name, a refused binding) is skipped and logged (Failure). Then done, also when nothing was saved; a
		failure (no Storage, a read failing, a file that isn't a version 1 save) goes to failed, or to the log when failed is null, the bindings
		unchanged. The defaults reset restores are kept first. */
	public function load(key = "actions", ?done:Void->Void, ?failed:String->Void):Void {
		if (Storage.instance == null) {
			Failure.report(key, "No storage", failed);
			return;
		}
		keepDefaults();
		Storage.read(key, result -> switch result {
			case Stored(bytes):
				apply(key, bytes.toString(), done, failed);
			case Missing:
				if (done != null) done();
			case Failed(message):
				Failure.report(key, message, failed);
			case Cancelled:
		});
	}

	/** Restores each action's defaults: its bindings as the game bound them in code, kept at the first load or capture after the action was
		made (so what a player changed, by a capture or a loaded save, goes back). An action made after the last load or capture has no
		defaults yet and keeps its bindings. */
	public function reset():Void
		for (action in actions)
			if (defaults.exists(action.name))
				action.bindings = defaults.get(action.name).copy();

	/** For the input (IInputWatcher): keeps whether each action was down as the tick ended, and lets go of a captured press seen up. */
	public function tickEnded():Void {
		for (action in actions)
			action.was[TICK] = isActionDown(action, TICK);
		if (swallowed[TICK] != null && rawValue(swallowed[TICK]) == 0)
			swallowed[TICK] = null;
	}

	/** For the input (IInputWatcher): takes a press for capture, keeps whether each action was down as the frame ended, and lets go of a
		captured press seen up. */
	public function frameEnded():Void {
		if (capturing)
			takeCapture();
		for (action in actions)
			action.was[FRAME] = isActionDown(action, FRAME);
		if (swallowed[FRAME] != null && rawValue(swallowed[FRAME]) == 0)
			swallowed[FRAME] = null;
	}

	// ---- reading

	function find(name:String):Null<Action> {
		for (a in actions)
			if (a.name == name)
				return a;
		return null;
	}

	static function indexOf(list:Array<Binding>, binding:Binding):Int {
		for (i in 0...list.length)
			if (Type.enumEq(list[i], binding))
				return i;
		return -1;
	}

	// Whether binding counts in context: nothing does while capturing, and a captured press doesn't until it's let go.
	function isLive(binding:Binding, context:Int):Bool
		return input != null && !capturing && (swallowed[context] == null || !Type.enumEq(binding, swallowed[context]));

	function valueOf(binding:Binding, context:Int):Float
		return isLive(binding, context) ? rawValue(binding) : 0;

	function isActionDown(action:Action, context:Int):Bool {
		for (b in action.bindings) {
			var limit = switch b {
				case Axis(_, _, threshold) if (threshold > 0): threshold;
				case _: .5;
			}
			if (Math.abs(valueOf(b, context)) >= limit)
				return true;
		}
		return false;
	}

	function pressed(action:Null<Action>, context:Int):Bool {
		if (action == null)
			return false;
		if (isActionDown(action, context) && !action.was[context])
			return true;
		for (b in action.bindings)
			if (isLive(b, context) && hasEdge(b, context, true))
				return true;
		return false;
	}

	function released(action:Null<Action>, context:Int):Bool {
		if (action == null || isActionDown(action, context))
			return false;
		if (action.was[context])
			return true;
		for (b in action.bindings)
			if (isLive(b, context) && hasEdge(b, context, false))
				return true;
		return false;
	}

	// The binding's value from -1 to 1 as the input has it now.
	function rawValue(binding:Binding):Float {
		if (input == null)
			return 0;
		return switch binding {
			case Keyboard(key): input.isDown(key) ? 1 : 0;
			case KeyboardPair(negative, positive): (input.isDown(positive) ? 1 : 0) - (input.isDown(negative) ? 1 : 0);
			case Pad(button): input.isPadDown(button) ? 1 : 0;
			case PadPair(negative, positive): (input.isPadDown(positive) ? 1 : 0) - (input.isPadDown(negative) ? 1 : 0);
			case Axis(axis, side, threshold):
				var best = 0.;
				for (i in 0...input.padCount) {
					var pad = input.getPad(i);
					if (!pad.connected)
						continue;
					var v = pad.getAxis(axis);
					if (side != 0)
						v = v * side > 0 ? v * side : 0;
					if (Math.abs(v) > Math.abs(best))
						best = v;
				}
				Math.abs(best) < threshold ? 0 : best;
			case Mouse(button): input.isMouseDown(button) ? 1 : 0;
			case TouchRegion(_, _, _, _, _):
				var found = false;
				for (t in input.touches)
					if (t.down && isInRegion(binding, t.x, t.y))
						found = true;
				found ? 1 : 0;
		}
	}

	// Whether a key, pad button, mouse button or (for a frame) finger of binding went down (pressing) or came up since the context began.
	function hasEdge(binding:Binding, context:Int, pressing:Bool):Bool {
		var frame = context == FRAME;
		inline function key(k:Key):Bool
			return frame ? (pressing ? input.isFramePressed(k) : input.isFrameReleased(k)) : (pressing ? input.isPressed(k) : input.isReleased(k));
		inline function button(b:PadButton):Bool {
			var edge = false;
			for (i in 0...input.padCount) {
				var pad = input.getPad(i);
				if (pad.connected
					&& (frame ? (pressing ? pad.isFramePressed(b) : pad.isFrameReleased(b)) : (pressing ? pad.isPressed(b) : pad.isReleased(b))))
					edge = true;
			}
			return edge;
		}
		return switch binding {
			case Keyboard(k): key(k);
			case KeyboardPair(negative, positive): key(negative) || key(positive);
			case Pad(b): button(b);
			case PadPair(negative, positive): button(negative) || button(positive);
			case Axis(_, _, _): false;
			case Mouse(b):
				frame ? (pressing ? input.isMouseFramePressed(b) : input.isMouseFrameReleased(b)) : (pressing ? input.isMousePressed(b) : input.isMouseReleased(b));
			case TouchRegion(_, _, _, _, _):
				var edge = false;
				if (frame)
					for (t in input.touches)
						if ((pressing ? t.pressed : t.released) && isInRegion(binding, t.x, t.y))
							edge = true;
				edge;
		}
	}

	function screen():Null<Presentation>
		return presentation != null ? presentation : Screen.instance;

	// Whether framebuffer pixel x, y is in the touch region binding, in the presentation's units.
	function isInRegion(binding:Binding, x:Float, y:Float):Bool {
		var p = screen();
		if (p == null)
			return false;
		return switch binding {
			case TouchRegion(anchor, rx, ry, width, height): var i = ANCHORS.indexOf(anchor); var left = p.visibleX + p.visibleWidth * (i % 3) / 2 + rx,
					top = p.visibleY + p.visibleHeight * Std.int(i / 3) / 2 + ry; var ux = p.toUnitsX(x),
					uy = p.toUnitsY(y); ux >= left && uy >= top && ux < left + width && uy < top + height;
			case _: false;
		}
	}

	// ---- binding and capture

	static function isValid(binding:Binding):Bool {
		if (binding == null)
			return false;
		return switch binding {
			case Axis(_, side, threshold): (side == -1 || side == 0 || side == 1) && threshold >= 0 && threshold <= 1;
			case TouchRegion(anchor, x, y, width, height):
				anchor != null
				&& Math.isFinite(x)
				&& Math.isFinite(y)
				&& width > 0
				&& height > 0
				&& Math.isFinite(width)
				&& Math.isFinite(height);
			case _: true;
		}
	}

	// The device a binding is of: the keyboard (0), a pad (1), the mouse (2), the touch screen (3). A capture replaces its own device's.
	static function device(binding:Binding):Int
		return switch binding {
			case Keyboard(_) | KeyboardPair(_, _): 0;
			case Pad(_) | PadPair(_, _) | Axis(_, _, _): 1;
			case Mouse(_): 2;
			case TouchRegion(_, _, _, _, _): 3;
		}

	// Each action's bindings as they stand, for those without defaults yet.
	function keepDefaults():Void
		for (action in actions)
			if (!defaults.exists(action.name))
				defaults.set(action.name, action.bindings.copy());

	// A capture's look at the frame as it ends: Escape cancels, else the first key, pad button, pad axis crossing half way, or finger that
	// went down; the frame capture began in is skipped.
	function takeCapture():Void {
		if (input == null)
			return;
		if (!captureArmed) {
			captureArmed = true;
			captureAxes = axisSides();
			return;
		}
		if (input.isFramePressed(Key.Escape)) {
			finishCapture(null, true);
			return;
		}
		for (k in Key.all)
			if (input.isFramePressed(k)) {
				finishCapture(Keyboard(k), true);
				return;
			}
		for (i in 0...input.padCount) {
			var pad = input.getPad(i);
			if (pad.connected)
				for (b in PadButton.all)
					if (pad.isFramePressed(b)) {
						finishCapture(Pad(b), true);
						return;
					}
		}
		var sides = axisSides();
		for (i in 0...sides.length)
			if (sides[i] != 0 && sides[i] != captureAxes[i]) {
				finishCapture(Axis(PadAxis.all[i % PadAxis.COUNT], sides[i], CAPTURE_THRESHOLD), true);
				return;
			}
		captureAxes = sides;
		var p = screen();
		if (p != null)
			for (t in input.touches)
				if (t.pressed) {
					finishCapture(region(p, p.toUnitsX(t.x), p.toUnitsY(t.y)), true);
					return;
				}
	}

	// Each pad's axes, pad by pad, as the side each is pushed past CAPTURE_THRESHOLD on (-1, 1), or 0.
	function axisSides():Array<Int> {
		var sides = [];
		for (i in 0...input.padCount) {
			var pad = input.getPad(i);
			for (axis in PadAxis.all) {
				var v = pad.connected ? pad.getAxis(axis) : 0;
				sides.push(v >= CAPTURE_THRESHOLD ? 1 : (v <= -CAPTURE_THRESHOLD ? -1 : 0));
			}
		}
		return sides;
	}

	// A captureTouchSize square centered on x, y (units), placed from the nearest anchor.
	function region(p:Presentation, x:Float, y:Float):Binding {
		var nearest = 0, distance = Math.POSITIVE_INFINITY;
		for (i in 0...ANCHORS.length) {
			var ax = p.visibleX + p.visibleWidth * (i % 3) / 2,
				ay = p.visibleY + p.visibleHeight * Std.int(i / 3) / 2;
			var d = (x - ax) * (x - ax) + (y - ay) * (y - ay);
			if (d < distance) {
				distance = d;
				nearest = i;
			}
		}
		var ax = p.visibleX + p.visibleWidth * (nearest % 3) / 2,
			ay = p.visibleY + p.visibleHeight * Std.int(nearest / 3) / 2;
		var half = captureTouchSize / 2;
		return TouchRegion(ANCHORS[nearest], x - ax - half, y - ay - half, captureTouchSize, captureTouchSize);
	}

	// Ends a capture with binding (null: cancelled), the press read as up until it's let go when swallow; every action's previous state is
	// taken as it stands, so nothing held through the capture reads as pressed after it.
	function finishCapture(binding:Null<Binding>, swallow:Bool):Void {
		var name = captureName,
			done = captureDone,
			cancelled = captureCancelled;
		capturing = false;
		captureDone = null;
		captureCancelled = null;
		if (swallow) {
			var pressed = binding != null ? binding : Binding.Keyboard(Key.Escape);
			swallowed = [pressed, pressed];
		}
		if (binding != null) {
			var action = find(name);
			if (action == null) {
				action = {name: name, bindings: [], was: [false, false]};
				actions.push(action);
			}
			var kind = device(binding);
			action.bindings = [for (b in action.bindings) if (device(b) != kind) b];
			action.bindings.push(binding);
		}
		for (action in actions) {
			action.was[FRAME] = isActionDown(action, FRAME);
			action.was[TICK] = isActionDown(action, TICK);
		}
		if (binding != null) {
			if (done != null)
				done(binding);
		} else if (cancelled != null)
			cancelled();
	}

	// ---- saving

	static function describeKey(key:Key):String
		return switch key {
			case PageUp: "Page up";
			case PageDown: "Page down";
			case CapsLock: "Caps lock";
			case ScrollLock: "Scroll lock";
			case NumLock: "Num lock";
			case PrintScreen: "Print screen";
			case World1: "World 1";
			case World2: "World 2";
			case Apostrophe: "'";
			case Comma: ",";
			case Minus: "-";
			case Period: ".";
			case Slash: "/";
			case Semicolon: ";";
			case Equal: "=";
			case LeftBracket: "[";
			case Backslash: "\\";
			case RightBracket: "]";
			case Grave: "`";
			case KeypadDecimal: "Keypad .";
			case KeypadDivide: "Keypad /";
			case KeypadMultiply: "Keypad *";
			case KeypadSubtract: "Keypad -";
			case KeypadAdd: "Keypad +";
			case KeypadEnter: "Keypad enter";
			case KeypadEqual: "Keypad =";
			case _:
				var name = Key.getName(key);
				StringTools.startsWith(name, "Keypad") ? "Keypad " + name.substr(6) : name;
		}

	function encode():String {
		var parts = [
			for (action in actions)
				Json.stringify(action.name) + ":[" + [for (b in action.bindings) encodeBinding(b)].join(",") + "]"
		];
		return '{"version":$VERSION,"actions":{' + parts.join(",") + "}}";
	}

	static function encodeBinding(binding:Binding):String {
		inline function text(s:String):String
			return Json.stringify(s);
		inline function number(f:Float):String
			return Json.stringify(f);
		return switch binding {
			case Keyboard(key): '{"key":${text(Key.getName(key))}}';
			case KeyboardPair(negative, positive): '{"keys":[${text(Key.getName(negative))},${text(Key.getName(positive))}]}';
			case Pad(button): '{"padButton":${text(PAD_BUTTON_NAMES[button])}}';
			case PadPair(negative, positive): '{"padButtons":[${text(PAD_BUTTON_NAMES[negative])},${text(PAD_BUTTON_NAMES[positive])}]}';
			case Axis(axis, side, threshold): '{"padAxis":${text(PAD_AXIS_NAMES[axis])},"side":$side,"threshold":${number(threshold)}}';
			case Mouse(button): '{"mouseButton":${text(MOUSE_NAMES[button])}}';
			case TouchRegion(anchor, x, y, width, height):
				'{"touch":${text(ANCHOR_NAMES[ANCHORS.indexOf(anchor)])},"x":${number(x)},"y":${number(y)},"width":${number(width)},"height":${number(height)}}';
		}
	}

	static function saveFailed(key:String, message:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(message);
		else
			trace('Save failed: ${Failure.named(key, message)}');
	}

	// A save's text read into the actions the game binds.
	function apply(key:String, text:String, done:Null<Void->Void>, failed:Null<String->Void>):Void {
		var root:Dynamic = null;
		try
			root = Json.parse(text)
		catch (_:Dynamic) {
			Failure.report(key, "not JSON", failed);
			return;
		}
		if (!isObject(root) || Reflect.field(root, "version") != VERSION || !isObject(Reflect.field(root, "actions"))) {
			Failure.report(key, 'not a version $VERSION actions save', failed);
			return;
		}
		var saved:Dynamic = Reflect.field(root, "actions");
		for (name in Reflect.fields(saved)) {
			var action = find(name);
			if (action == null)
				continue;
			var list:Dynamic = Reflect.field(saved, name);
			if (!Std.isOfType(list, Array)) {
				Failure.report(key, '$name: expected a list of bindings', null);
				continue;
			}
			var read:Array<Binding> = [];
			for (entry in (list : Array<Dynamic>)) {
				try {
					var b = decode(entry);
					if (!isValid(b))
						throw 'refused binding ${Json.stringify(entry)}';
					if (indexOf(read, b) < 0)
						read.push(b);
				} catch (reason:String) {
					Failure.report(key, '$name: $reason', null);
				}
			}
			action.bindings = read;
		}
		if (done != null)
			done();
	}

	static function isObject(value:Dynamic):Bool
		return value != null && Reflect.isObject(value) && !Std.isOfType(value, String) && !Std.isOfType(value, Array);

	// A saved binding, or a throw of why it can't be read.
	static function decode(entry:Dynamic):Binding {
		if (!isObject(entry))
			throw 'expected a binding, not ${Json.stringify(entry)}';
		function text(field:String):String {
			var v:Dynamic = Reflect.field(entry, field);
			if (!Std.isOfType(v, String))
				throw '$field: expected a name';
			return v;
		}
		function number(field:String):Float {
			var v:Dynamic = Reflect.field(entry, field);
			if (!Std.isOfType(v, Float) || !Math.isFinite(v))
				throw '$field: expected a number';
			return v;
		}
		function pair(field:String):Array<String> {
			var v:Dynamic = Reflect.field(entry, field);
			if (!Std.isOfType(v, Array) || v.length != 2 || !Std.isOfType(v[0], String) || !Std.isOfType(v[1], String))
				throw '$field: expected two names';
			return [v[0], v[1]];
		}
		function key(name:String):Key
			return try Key.named(name) catch (_:Dynamic) throw 'unknown key $name';
		function named(names:Array<String>, name:String, what:String):Int {
			var i = names.indexOf(name);
			if (i < 0)
				throw 'unknown $what $name';
			return i;
		}
		if (Reflect.hasField(entry, "key"))
			return Keyboard(key(text("key")));
		if (Reflect.hasField(entry, "keys")) {
			var p = pair("keys");
			return KeyboardPair(key(p[0]), key(p[1]));
		}
		if (Reflect.hasField(entry, "padButton"))
			return Pad(cast named(PAD_BUTTON_NAMES, text("padButton"), "pad button"));
		if (Reflect.hasField(entry, "padButtons")) {
			var p = pair("padButtons");
			return PadPair(cast named(PAD_BUTTON_NAMES, p[0], "pad button"), cast named(PAD_BUTTON_NAMES, p[1], "pad button"));
		}
		if (Reflect.hasField(entry, "padAxis")) {
			var side = number("side");
			if (side != Math.ffloor(side))
				throw "side: expected -1, 0 or 1";
			return Axis(cast named(PAD_AXIS_NAMES, text("padAxis"), "pad axis"), Std.int(side), number("threshold"));
		}
		if (Reflect.hasField(entry, "mouseButton"))
			return Mouse(cast named(MOUSE_NAMES, text("mouseButton"), "mouse button"));
		if (Reflect.hasField(entry, "touch"))
			return TouchRegion(ANCHORS[named(ANCHOR_NAMES, text("touch"), "anchor")], number("x"), number("y"), number("width"), number("height"));
		throw 'unknown binding ${Json.stringify(entry)}';
	}
}
