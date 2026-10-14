package helix.adapters.host.sokol;

import helix.adapters.host.sokol.internal.HostBridge;
import helix.host.IHost;
import helix.host.IWindow;

/** The native host: one sokol_app window and its frame loop, haxe.Timer's clock, and options from HELIX_* environment variables. One per
	program. */
class SokolHostAdapter implements IHost {
	static var init:Void->Void;
	static var frame:Void->Void;
	static var cleanup:Void->Void;

	var window = new SokolWindow();

	/** The program's host; its window opens when run starts. */
	public function new() {}

	public function run(init:Void->Void, frame:Void->Void, cleanup:Void->Void):Void {
		SokolHostAdapter.init = init;
		SokolHostAdapter.frame = frame;
		SokolHostAdapter.cleanup = cleanup;
		HostBridge.run(cpp.Callable.fromStaticFunction(onInit), cpp.Callable.fromStaticFunction(onFrame), cpp.Callable.fromStaticFunction(onCleanup));
	}

	static function onInit():Void
		init();

	static function onFrame():Void
		frame();

	static function onCleanup():Void
		cleanup();

	public function getTime():Float
		return haxe.Timer.stamp();

	public function getWindow():IWindow
		return window;

	public function canQuit():Bool
		return true;

	public function quit():Void
		HostBridge.quit();

	public function getOption(name:String):Null<String>
		return Sys.getEnv("HELIX_" + name.toUpperCase());
}
