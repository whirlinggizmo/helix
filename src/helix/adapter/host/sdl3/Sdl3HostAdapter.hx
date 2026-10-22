package helix.adapter.host.sdl3;

import helix.adapter.host.sdl3.internal.HostBridge;
import helix.adapter.shared.NativeHost;
import helix.host.IHost;

/** The native host through SDL3: one window and its frame loop, the window with a GL 4.1 context for sokol_gfx or without one for SDL_GPU.
	One per program. */
class Sdl3HostAdapter extends NativeHost implements IHost {
	var gl:Bool;

	/** The program's host; its window opens when run starts, asking for msaaSamples multisampling samples a pixel (1: none), with a GL
		context when gl (the graphics adapter draws GL in it) or without (SDL_GPU's adapter claims the window). */
	public function new(msaaSamples:Int, gl:Bool) {
		super(msaaSamples);
		this.gl = gl;
	}

	function start(init:cpp.Callable<Void->Void>, frame:cpp.Callable<Void->Void>, cleanup:cpp.Callable<Void->Void>, msaaSamples:Int):Void
		HostBridge.run(init, frame, cleanup, msaaSamples, gl ? 1 : 0);

	public function quit():Void
		HostBridge.quit();
}
