package helix.platform.adapters.events.sdl3;

import helix.platform.Event;
import helix.platform.IEvents;
import helix.platform.PadAxis;
import helix.platform.PadButton;
import helix.platform.adapters.events.sdl3.internal.EventsBridge;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;

/** Provides `IEvents` on SDL3, natively: its one queue drained at each poll, and its gamepads through its controller database.

	The window must be open (`Sdl3WindowAdapter`) before the first poll. No motion sensor is read natively: tilt asked for is unavailable. */
class Sdl3EventsAdapter implements IEvents {
	var delivered:Array<Event> = [];
	// What the adapter itself has to say, delivered at the next poll.
	var pending:Array<Event> = [];

	/** Sets up SDL's gamepads and touch. */
	public function new()
		EventsBridge.setup();

	public function poll():Void {
		delivered.resize(0);
		for (event in pending)
			delivered.push(event);
		pending.resize(0);
		if (Sdl3Bridge.isOpen() == 0)
			return;
		EventsBridge.poll();
		var text:Null<StringBuf> = null;
		while (EventsBridge.next() != 0) {
			var kind = EventsBridge.kind(),
				code = EventsBridge.code(),
				x:Float = EventsBridge.x(),
				y:Float = EventsBridge.y();
			// Typed characters arrive one record each: a run of them is one Text.
			if (kind == 3) {
				if (text == null)
					text = new StringBuf();
				text.addChar(code);
				continue;
			}
			if (text != null) {
				delivered.push(Text(text.toString()));
				text = null;
			}
			var event = switch kind {
				case 1: KeyDown(cast code, EventsBridge.value() != 0);
				case 2: KeyUp(cast code);
				case 4: MouseDown(cast code, x, y);
				case 5: MouseUp(cast code, x, y);
				case 6: MouseMove(x, y);
				case 7: MouseLeave;
				case 8: Wheel(x, y);
				case 9: TouchDown(code, x, y);
				case 10: TouchMove(code, x, y);
				case 11: TouchUp(code, x, y);
				case 12: PadConnected(code);
				case 13: PadDisconnected(code);
				case 14: Resized(code, EventsBridge.value());
				case 15: FocusGained;
				case 16: FocusLost;
				case 17: Shown;
				case 18: Hidden;
				case 19: CloseRequested;
				case 20: PadButtonDown(code, cast EventsBridge.value());
				case 21: PadButtonUp(code, cast EventsBridge.value());
				case _: null;
			}
			if (event != null)
				delivered.push(event);
		}
		if (text != null)
			delivered.push(Text(text.toString()));
	}

	public var events(get, never):Array<Event>;

	function get_events():Array<Event>
		return delivered;

	public function wait(timeout:Float):Void
		EventsBridge.wait(Std.int(Math.max(0, timeout) * 1000));

	public function setTextInput(on:Bool):Void
		EventsBridge.setText(on ? 1 : 0);

	public function setTiltWanted(on:Bool):Void
		if (on)
			pending.push(TiltState(5));

	public var activated(get, never):Bool;

	function get_activated():Bool
		return true;

	public function isPadConnected(slot:Int):Bool
		return EventsBridge.padConnected(slot) != 0;

	public function getPadName(slot:Int):String
		return (EventsBridge.padName(slot) : String);

	public function isPadButtonDown(slot:Int, button:PadButton):Bool
		return EventsBridge.padButton(slot, button) != 0;

	public function getPadAxis(slot:Int, axis:PadAxis):Float
		return EventsBridge.padAxis(slot, axis);

	public function dispose():Void
		EventsBridge.dispose();
}
