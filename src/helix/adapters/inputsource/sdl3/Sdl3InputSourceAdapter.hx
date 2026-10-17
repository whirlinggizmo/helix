package helix.adapters.inputsource.sdl3;

import helix.adapters.inputsource.sdl3.internal.InputBridge;
import helix.adapters.shared.NativeInputSource;
import helix.input.IInputSource;

/** Native input through SDL3: its window's events (keys by physical position, the pointer, text, touch, focus) and its gamepads, through its controller database, connected and disconnected while running. */
class Sdl3InputSourceAdapter extends NativeInputSource implements IInputSource {
	/** Sets up the native input bridge. */
	public function new()
		InputBridge.setup();

	function pollSource():Void
		InputBridge.poll();

	/** SDL's text input, started on the window while on (it sends typed text only then, and on a platform with a soft keyboard shows it) and
		stopped when off. */
	override public function setTextEntry(on:Bool):Void
		InputBridge.setText(on ? 1 : 0);

	/** Releases the native input bridge. */
	public function shutdown():Void
		InputBridge.shutdown();
}
