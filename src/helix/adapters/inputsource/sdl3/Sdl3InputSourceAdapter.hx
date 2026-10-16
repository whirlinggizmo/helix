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

	/** Releases the native input bridge. */
	public function shutdown():Void
		InputBridge.shutdown();
}
