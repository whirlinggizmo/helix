package helix.adapters.inputsource.sokol;

import helix.adapters.inputsource.sokol.internal.InputBridge;
import helix.input.IInputEvents;
import helix.input.IInputSource;
import helix.input.Key;
import helix.input.MouseButton;
import helix.input.PadAxis;
import helix.input.PadButton;

/** Native input: sokol's queued window events reported in order at poll (so a press and release in one frame keep both edges), then the
	evdev gamepads. */
class SokolInputAdapter implements IInputSource {
	var events:IInputEvents;
	var buttons:Array<Bool> = [for (_ in PadButton.all) false];
	var axes:Array<Float> = [for (_ in PadAxis.all) 0.];

	/** Sets up the native input bridge. */
	public function new()
		InputBridge.inputSetup();

	public function start(events:IInputEvents):Void
		this.events = events;

	public function poll():Void {
		InputBridge.inputPoll();
		while (InputBridge.next() != 0) {
			var code = InputBridge.eventCode(),
				value = InputBridge.eventValue() != 0,
				x:Float = InputBridge.eventX(),
				y:Float = InputBridge.eventY();
			switch (InputBridge.eventType()) {
				case 1:
					var key = toKey(code);
					if (key != null)
						events.key(key, value);
				case 2:
					events.text(String.fromCharCode(code));
				case 3:
					if (code >= 0 && code < 3)
						events.mouseButton(cast code, value, x, y);
				case 4:
					events.mouseMove(x, y);
				case 5:
					events.wheel(x, y);
				case 6:
					events.touch(code, x, y, value);
				case 7:
					events.focus(value);
				default:
			}
		}
		for (i in 0...InputBridge.padSlots()) {
			if (InputBridge.padConnected(i) == 0)
				continue;
			for (button in PadButton.all)
				buttons[button] = InputBridge.padButton(i, button) != 0;
			for (axis in PadAxis.all)
				axes[axis] = InputBridge.padAxis(i, axis);
			events.pad(InputBridge.padName(i), buttons, axes);
		}
	}

	/** The Key a sokol key code names: sokol's codes are Key's numbers, its right-hand modifiers folded onto the left-hand ones; null for a
		key HeliX doesn't name. */
	static function toKey(code:Int):Null<Key> {
		if (code >= 344 && code <= 347)
			code -= 4;
		return code >= 0 && code < Key.COUNT && known[code] ? cast code : null;
	}

	static final known:Array<Bool> = {
		var v = [for (_ in 0...Key.COUNT) false];
		for (k in Key.all)
			v[k] = true;
		v;
	};

	/** Releases the native input bridge. */
	public function shutdown():Void
		InputBridge.inputShutdown();
}
