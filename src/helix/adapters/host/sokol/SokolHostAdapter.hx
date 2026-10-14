package helix.adapters.host.sokol;

import helix.adapters.input.sokol.internal.InputBridge;
import helix.adapters.host.sokol.internal.HostBridge;
import helix.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.host.HostServices;
import helix.host.IHost;
import helix.assets.IAssets;
import helix.graphics.IGraphics;
import helix.input.IInput;
import helix.audio.IAudio;
import helix.debug.IDiagnostics;
import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.audio.AudioResources;
import helix.app.IApp;
import helix.host.HostCore;

/** The native host: one sokol_app window and its frame loop, and options from HELIX_* environment variables; the rest of a host is HostCore's.
	Its own IDiagnostics. */
class SokolHostAdapter implements IHost implements IDiagnostics {
	public var graphics(default, null):IGraphics;
	public var input(default, null):IInput;
	public var audio(default, null):IAudio;
	public var diagnostics(default, null):IDiagnostics;
	public var assets(default, null):IAssets;
	public var fetch(default, null):IFetch;
	public var storage(default, null):IStorage;
	public var audioResources(default, null):AudioResources;
	public var textures(default, null):helix.render2d.Textures;

	public var environments(default, null):helix.render3d.Environments;

	var focused = true;

	public var window(default, null):helix.host.IWindow = new SokolWindow();

	static var instance:SokolHostAdapter;

	var core:HostCore;
	var services:HostServices;
	var compose:Void->HostServices;
	var app:IApp;
	var inspectCallback:Void->Dynamic;

	/** Keeps compose to build the services when run opens the window; only one host per program. */
	public function new(compose:Void->HostServices) {
		this.compose = compose;
		instance = this;
		diagnostics = this;
	}

	public function run(app:IApp):Void {
		this.app = app;
		HostBridge.run(cpp.Callable.fromStaticFunction(onInit), cpp.Callable.fromStaticFunction(onFrame), cpp.Callable.fromStaticFunction(onCleanup));
	}

	static function onInit():Void {
		instance.services = instance.compose();
		var s = instance.services, core = new HostCore(s);
		instance.core = core;
		instance.fetch = s.fetch;
		instance.storage = s.storage;
		instance.input = s.input;
		instance.audio = s.audio;
		instance.graphics = s.graphics;
		instance.assets = core.resources;
		instance.audioResources = core.audioResources;
		instance.textures = core.textures;
		instance.environments = core.environments;
		instance.app.init();
	}

	static function onFrame():Void {
		instance.focused = InputBridge.focused() != 0;
		instance.core.frame(instance.app, instance.getTime(), instance.getTime);
		var path = Sys.getEnv("HELIX_LIVE");
		if (path != null && instance.inspectCallback != null) {
			var value = instance.inspectCallback();
			value.host = instance.getInfo();
			sys.io.File.saveContent(path, haxe.Json.stringify(value));
		}
	}

	static function onCleanup():Void {
		instance.core.close(instance.app);
	}

	public function isFocused():Bool
		return focused;

	public function canQuit():Bool
		return true;

	public function getTime():Float
		return haxe.Timer.stamp();

	public function getFramebufferWidth():Int
		return HostBridge.width();

	public function getFramebufferHeight():Int
		return HostBridge.height();

	public function getPixelRatio():Float
		return HostBridge.pixelRatio();

	public function getOption(name:String, fallback:String):String {
		var value = Sys.getEnv("HELIX_" + name.toUpperCase());
		return value == null ? fallback : value;
	}

	public function publish(value:Dynamic):Void {
		var json = haxe.Json.stringify(value);
		Sys.println(json);
		var path = Sys.getEnv("HELIX_RESULT");
		if (path != null)
			sys.io.File.saveContent(path, json + "\n");
	}

	public function expose(inspect:Void->Dynamic):Void
		inspectCallback = inspect;

	public function capture(name:String = ""):Void {
		var path = Sys.getEnv("HELIX_CAPTURE");
		if (path != null) {
			if (name != "")
				path = haxe.io.Path.withoutExtension(path) + "-" + name + ".ppm";
			GraphicsBridge.capture(path);
		}
	}

	public function quit():Void
		HostBridge.quit();

	public function getFrameElapsed():Float
		return core.clock.getElapsed();

	public function getFrameCpu():Float
		return core.getFrameCpu();

	public function getFrameInterval():Float
		return core.getFrameInterval();

	public function getFrameAudit():Dynamic
		return haxe.Json.parse(Std.string(GraphicsBridge.audit()));

	public function memoryPhase(begin:Bool):Dynamic {
		if (begin) {
			cpp.vm.Gc.run(true);
			cpp.vm.Gc.enable(false);
			return memory();
		}
		var before = memory();
		cpp.vm.Gc.enable(true);
		cpp.vm.Gc.run(true);
		return {beforeCollect: before, afterCollect: memory()};
	}

	function memory():Dynamic
		return {
			peakRssBytes: GraphicsBridge.peakRss(),
			vertexReservedBytes: GraphicsBridge.vertexReserved(),
			usedBytes: cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_CURRENT),
			reservedBytes: cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED),
			liveEstimateBytes: cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE)
		};

	public function getInfo():Dynamic
		return services.info();
}
