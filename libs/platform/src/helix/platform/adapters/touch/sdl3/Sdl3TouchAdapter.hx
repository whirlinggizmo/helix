package helix.platform.adapters.touch.sdl3;

import helix.platform.ITouch;
import helix.platform.adapters.shared.sdl3.Sdl3EventsBridge;

/** Provides `ITouch` on SDL3, natively: fingers on the window, in framebuffer pixels, each numbered by its place among the fingers down.
	A touch SDL cancels arrives as its `TouchUp`. */
class Sdl3TouchAdapter implements ITouch {
	/** Turns SDL's finger events on.

		@param options  The events adapter its events are delivered by. */
	public function new(options:Sdl3TouchAdapterOptions) {
		Sdl3EventsBridge.want(Sdl3EventsBridge.TOUCH, 1);
	}

	public var available(get, never):Bool;

	function get_available():Bool
		return Sdl3EventsBridge.touchDevices() > 0;

	public function dispose():Void
		Sdl3EventsBridge.want(Sdl3EventsBridge.TOUCH, 0);
}
