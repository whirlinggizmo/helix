package helix.adapter.inputsource.sokol;

import helix.adapter.inputsource.sokol.internal.InputBridge;
import helix.adapter.shared.NativeInputSource;
import helix.input.IInputSource;

/** Native input through sokol_app: the sokol host's window events, and the OS's gamepads (evdev on Linux, XInput on Windows, none on macOS). */
class SokolInputSourceAdapter extends NativeInputSource implements IInputSource {
	/** Sets up the native input bridge. */
	public function new()
		InputBridge.setup();

	function pollSource():Void
		InputBridge.poll();

	/** Releases the native input bridge. */
	public function shutdown():Void
		InputBridge.shutdown();
}
