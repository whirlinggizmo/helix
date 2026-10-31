package helix.platform.adapters.events.sdl3;

import helix.platform.Event;
import helix.platform.IEvents;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.ProgramName;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;
import helix.platform.adapters.shared.sdl3.Sdl3EventsBridge;

/** Provides `IEvents` on SDL3, natively: its one queue drained at each poll.

	The window must be open (`Sdl3WindowAdapter`) before the first poll. SDL's events for a device are turned off until its adapter is
	constructed over this one (`Sdl3KeyboardAdapter`, `Sdl3MouseAdapter`, `Sdl3TouchAdapter`, `Sdl3GamepadsAdapter`), except a key,
	a mouse button and a finger lifting, which stay on until the first press has come. */
class Sdl3EventsAdapter implements IEvents {
	@:allow(helix.platform.adapters)
	final stream = new EventStream();

	/** Sets up SDL's events, with no device's wanted yet. */
	public function new() {
		Sdl3Bridge.nameApp(ProgramName.product());
		Sdl3EventsBridge.setup();
	}

	public var unlocked(get, never):Bool;

	function get_unlocked():Bool
		return stream.unlocked;

	public function poll():Void {
		stream.begin();
		if (Sdl3Bridge.isOpen() != 0)
			drain();
		stream.end();
	}

	function drain():Void {
		Sdl3EventsBridge.poll();
		var text:Null<StringBuf> = null;
		while (Sdl3EventsBridge.next() != 0) {
			var kind = Sdl3EventsBridge.kind(),
				code = Sdl3EventsBridge.code(),
				x:Float = Sdl3EventsBridge.x(),
				y:Float = Sdl3EventsBridge.y();
			// Typed characters arrive one record each: a run of them is one Text.
			if (kind == 3) {
				if (text == null)
					text = new StringBuf();
				text.addChar(code);
				continue;
			}
			if (text != null) {
				stream.deliver(Text(text.toString()));
				text = null;
			}
			var event = switch kind {
				case 1: KeyDown(cast code, Sdl3EventsBridge.value() != 0);
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
				case 14: Resized(code, Sdl3EventsBridge.value());
				case 15: FocusGained;
				case 16: FocusLost;
				case 17: Shown;
				case 18: Hidden;
				case 19: CloseRequested;
				case 20: PadButtonDown(code, cast Sdl3EventsBridge.value());
				case 21: PadButtonUp(code, cast Sdl3EventsBridge.value());
				case 22: Unlocked;
				case 23: FilesDropped(code);
				case _: null;
			}
			if (event != null)
				stream.deliver(event);
		}
		if (text != null)
			stream.deliver(Text(text.toString()));
	}

	public var events(get, never):Array<Event>;

	function get_events():Array<Event>
		return stream.delivered;

	public function wait(timeout:Float):Void
		Sdl3EventsBridge.wait(Std.int(Math.max(0, timeout) * 1000));

	public function dispose():Void
		Sdl3EventsBridge.dispose();
}
