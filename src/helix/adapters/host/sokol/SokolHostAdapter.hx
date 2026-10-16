package helix.adapters.host.sokol;

import helix.adapters.host.sokol.internal.HostBridge;
import helix.adapters.shared.NativeHost;
import helix.host.IHost;

/** The native host through sokol_app: one window and its frame loop (X11 and GLX, Win32 and WGL, Cocoa). One per program. */
class SokolHostAdapter extends NativeHost implements IHost {
	/** The program's host; its window opens when run starts, asking for msaaSamples multisampling samples a pixel (1: none). */
	public function new(msaaSamples:Int)
		super(msaaSamples);

	function start(init:cpp.Callable<Void->Void>, frame:cpp.Callable<Void->Void>, cleanup:cpp.Callable<Void->Void>, msaaSamples:Int):Void
		HostBridge.run(init, frame, cleanup, msaaSamples);

	public function quit():Void
		HostBridge.quit();
}
