package helix.adapters.host.sdl3;

import helix.adapters.host.sdl3.internal.HostBridge;
import helix.adapters.shared.NativeHost;
import helix.host.IHost;

/** The native host through SDL3: one window with a GL 4.1 context and its frame loop. One per program. */
class Sdl3HostAdapter extends NativeHost implements IHost {
	/** The program's host; its window opens when run starts, asking for msaaSamples multisampling samples a pixel (1: none). */
	public function new(msaaSamples:Int)
		super(msaaSamples);

	function start(init:cpp.Callable<Void->Void>, frame:cpp.Callable<Void->Void>, cleanup:cpp.Callable<Void->Void>, msaaSamples:Int):Void
		HostBridge.run(init, frame, cleanup, msaaSamples);

	public function quit():Void
		HostBridge.quit();
}
