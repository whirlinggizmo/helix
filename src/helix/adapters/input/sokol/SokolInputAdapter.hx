package helix.adapters.input.sokol;

import helix.adapters.input.sokol.internal.InputBridge;
import helix.input.InputState;
import helix.input.Key;
import helix.input.MouseButton;
import helix.input.PadButton;
import helix.input.PadAxis;

/** Sokol's queued events applied in order, so a press and release in one frame keep both edges; then the evdev pads. */
class SokolInputAdapter extends InputState {
	public function new() {
		super();
		InputBridge.inputSetup();
	}

	public function poll():Void {
		InputBridge.inputPoll();
		while (InputBridge.next() != 0) {
			var code = InputBridge.eventCode(),
				value = InputBridge.eventValue() != 0,
				x:Float = InputBridge.eventX(),
				y:Float = InputBridge.eventY();
			switch (InputBridge.eventType()) {
				case 1:
					var key = Key.fromCode(code);
					if (key != null)
						keyEvent(key, value);
				case 2:
					textEvent(String.fromCharCode(code));
				case 3:
					if (code >= 0 && code < 3)
						mouseEvent(cast code, value);
					if (code == MouseButton.Left)
						pointerEvent(x, y, value);
					else
						pointerEvent(x, y, pointerDown);
				case 4:
					pointerEvent(x, y, pointerDown);
				case 5:
					wheelEvent(x, y);
				case 6:
					touchEvent(code, x, y, value);
				case 7:
					if (!value)
						clear();
				default:
			}
		}
		var focused = InputBridge.focused() != 0;
		for (i in 0...pads.length) {
			var pad = pads[i], connected = focused && InputBridge.padConnected(i) != 0;
			if (!connected) {
				if (pad.isConnected())
					pad.connect(false, "");
				continue;
			}
			var name:String = InputBridge.padName(i);
			if (!pad.isConnected() || pad.getName() != name)
				pad.connect(true, name);
			for (button in PadButton.all)
				pad.buttonEvent(button, InputBridge.padButton(i, button) != 0);
			for (axis in PadAxis.all)
				pad.axisEvent(axis, InputBridge.padAxis(i, axis));
		}
	}

	public function shutdown():Void
		InputBridge.inputShutdown();
}
