package helix.platform.adapters.mouse.sdl3;

import helix.platform.IMouse;
import helix.platform.adapters.shared.sdl3.Sdl3EventsBridge;

/** Provides `IMouse` on SDL3, natively: the mouse's and a pen's buttons, moves and wheel over the window, in framebuffer pixels. SDL's
	mouse made of a touch is passed over. */
class Sdl3MouseAdapter implements IMouse {
	/** Turns SDL's mouse events on.

		@param options  The events adapter its events are delivered by. */
	public function new(options:Sdl3MouseAdapterOptions) {
		Sdl3EventsBridge.want(Sdl3EventsBridge.MOUSE, 1);
	}

	public function dispose():Void
		Sdl3EventsBridge.want(Sdl3EventsBridge.MOUSE, 0);
}
