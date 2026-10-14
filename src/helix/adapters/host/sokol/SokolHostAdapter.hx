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
import helix.assets.AssetService;
import helix.audio.AudioResources;
import helix.app.IApp;

/** The native host: one sokol_app window and its frame loop, and options from HELIX_* environment variables. Its own IDiagnostics. */
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

	var resources:AssetService;
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
		var s = instance.services;
		instance.fetch = s.fetch;
		instance.storage = s.storage;
		instance.input = s.input;
		instance.audio = s.audio;
		instance.graphics = s.graphics;
		instance.resources = new AssetService(s.fetch, s.storage, s.packaged, s.base);
		instance.assets = instance.resources;
		instance.audioResources = new AudioResources(instance.assets, instance.audio);
		instance.textures = new helix.render2d.Textures(instance.assets, s.images, instance.graphics);
		instance.environments = new helix.render3d.Environments(instance.assets, s.images, instance.graphics);
		instance.app.init();
	}

	static function onFrame():Void {
		var cpuStart = instance.getTime();
		instance.clock.frame(cpuStart);
		instance.lastFrameInterval = instance.previousCallback == 0 ? 0 : (cpuStart - instance.previousCallback) * 1000;
		instance.previousCallback = cpuStart;
		instance.resources.poll();
		instance.audioResources.poll();
		instance.textures.poll();
		instance.environments.poll();
		instance.services.pollInput();
		instance.focused = InputBridge.focused() != 0;
		instance.app.frame(instance.clock.getDelta());
		instance.services.endInputFrame();
		var path = Sys.getEnv("HELIX_LIVE");
		if (path != null && instance.inspectCallback != null) {
			var value = instance.inspectCallback();
			value.host = instance.getInfo();
			sys.io.File.saveContent(path, haxe.Json.stringify(value));
		}
		instance.lastFrameCpu = (instance.getTime() - cpuStart) * 1000;
	}

	static function onCleanup():Void {
		instance.audioResources.shutdown();
		instance.textures.shutdown();
		instance.environments.shutdown();
		instance.services.images.shutdown();
		instance.resources.shutdown();
		instance.app.cleanup();
		instance.services.shutdownInput();
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

	var clock = new helix.host.FrameClock();

	public function getFrameElapsed():Float
		return clock.getElapsed();

	var lastFrameCpu = 0.;
	var lastFrameInterval = 0.;
	var previousCallback = 0.;

	public function getFrameCpu():Float
		return lastFrameCpu;

	public function getFrameInterval():Float
		return lastFrameInterval;

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
