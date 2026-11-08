package helix.platform.adapters.gamepads.dom;

import helix.platform.IGamepads;
import helix.platform.GamepadAxis;
import helix.platform.GamepadButton;
import helix.platform.adapters.shared.EventStream;
import js.Browser;

/** Provides `IGamepads` in a browser page, read at each `IEvents.poll` in the W3C standard layout.

	A page sees a gamepad only after a button press on it. The Gamepad API has no button events, so a change between two polls is one. */
class DomGamepadsAdapter implements IGamepads {
	final stream:EventStream;
	// The gamepads in slots 0 to 3 as of the last poll: the browser's gamepad, or null.
	final pads:Array<Dynamic> = [null, null, null, null];
	// Each slot's buttons as the last poll read them.
	final held:Array<Array<Bool>> = [for (_ in 0...4) [for (_ in 0...GamepadButton.COUNT) false]];
	final reading:Void->Void;

	/** Starts reading the gamepads at each poll.

		@param options  The events adapter whose poll reads them. */
	public function new(options:DomGamepadsAdapterOptions) {
		stream = options.events.stream;
		reading = read;
		stream.polls.push(reading);
	}

	function read():Void {
		var list:Dynamic = Browser.navigator.getGamepads();
		for (slot in 0...4) {
			var pad:Dynamic = list != null && slot < list.length ? list[slot] : null;
			if (pad != null && !pad.connected)
				pad = null;
			if (pad != null && pads[slot] == null)
				stream.deliver(GamepadConnected(slot));
			else if (pad == null && pads[slot] != null)
				stream.deliver(GamepadDisconnected(slot));
			pads[slot] = pad;
			var was = held[slot];
			for (i in 0...GamepadButton.COUNT) {
				var down = pad != null && isButtonDown(slot, cast i);
				if (down != was[i] && pad != null)
					stream.deliver(down ? GamepadButtonDown(slot, cast i) : GamepadButtonUp(slot, cast i));
				was[i] = down;
			}
		}
	}

	public function isConnected(slot:Int):Bool
		return slot >= 0 && slot < 4 && pads[slot] != null;

	public function getName(slot:Int):String
		return isConnected(slot) ? pads[slot].id : "";

	public function isButtonDown(slot:Int, button:GamepadButton):Bool {
		if (!isConnected(slot))
			return false;
		var buttons:Dynamic = pads[slot].buttons, i:Int = button;
		return i < buttons.length && buttons[i].pressed;
	}

	public function getAxis(slot:Int, axis:GamepadAxis):Float {
		if (!isConnected(slot))
			return 0;
		var pad:Dynamic = pads[slot], i:Int = axis;
		// The triggers are the standard layout's buttons 6 and 7, read by their value.
		if (i >= 4)
			return pad.buttons.length > i + 2 ? pad.buttons[i + 2].value : 0;
		return pad.axes.length > i ? pad.axes[i] : 0;
	}

	// The Gamepad API's vibration actuator ("dual-rumble"), where the browser has one.
	public function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool {
		var pad:Dynamic = slot >= 0 && slot < 4 ? pads[slot] : null;
		var actuator:Dynamic = pad != null ? pad.vibrationActuator : null;
		if (actuator == null || actuator.playEffect == null)
			return false;
		var clamp = (v:Float) -> v < 0 ? 0. : v > 1 ? 1. : v;
		if (seconds <= 0)
			actuator.reset != null ? actuator.reset() : actuator.playEffect("dual-rumble", {duration: 0, strongMagnitude: 0, weakMagnitude: 0});
		else
			actuator.playEffect("dual-rumble", {duration: seconds * 1000, strongMagnitude: clamp(low), weakMagnitude: clamp(high)});
		return true;
	}

	public function addMappings(mappings:String):Int
		return 0;

	public function dispose():Void {
		stream.polls.remove(reading);
		for (slot in 0...4)
			pads[slot] = null;
	}
}
