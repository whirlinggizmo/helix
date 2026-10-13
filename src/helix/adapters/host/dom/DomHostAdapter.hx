package helix.adapters.host.dom;

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
import js.Browser;
import js.html.CanvasElement;

/** The browser host: the page's canvas, a requestAnimationFrame loop, and options from the URL query. Its own IDiagnostics. */
class DomHostAdapter implements IHost implements IDiagnostics {
	public var graphics(default, null):IGraphics;
	public var input(default, null):IInput;
	public var audio(default, null):IAudio;
	public var diagnostics(default, null):IDiagnostics;
	public var assets(default, null):IAssets;
	public var fetch(default, null):IFetch;
	public var storage(default, null):IStorage;
	public var audioResources(default, null):AudioResources;
	public var textures(default, null):helix.render2d.Textures;

	var focused = true;

	public var window(default, null):helix.host.IWindow;

	var resources:AssetService;
	var canvas:CanvasElement;
	var stopped = false;
	var closed = false;
	var services:HostServices;
	var params = new js.html.URLSearchParams(Browser.window.location.search);

	/** Builds the services with compose, given the element with id "canvas" and whether to preserve the drawing buffer (the tick option is given). */
	public function new(compose:(CanvasElement, Bool) -> HostServices) {
		diagnostics = this;
		canvas = cast Browser.document.getElementById("canvas");
		window = new DomWindow(canvas);
		resize();
		services = compose(canvas, getOption("tick", "-1") != "-1");
		graphics = services.graphics;
		input = services.input;
		audio = services.audio;
		fetch = services.fetch;
		storage = services.storage;
		resources = new AssetService(fetch, storage, services.packaged, services.base);
		assets = resources;
		audioResources = new AudioResources(assets, audio);
		textures = new helix.render2d.Textures(assets, services.images, graphics);
		#if hotreload watchAssets(services.base); #end
		Browser.window.addEventListener("resize", _ -> resize());
		Browser.window.addEventListener("keydown", _ -> services.unlockAudio());
		canvas.addEventListener("pointerdown", _ -> services.unlockAudio());
		Browser.window.addEventListener("blur", _ -> {
			focused = false;
			services.focusInput(false);
			services.suspendAudio();
		});
		Browser.window.addEventListener("focus", _ -> {
			focused = true;
			services.focusInput(true);
		});
		Browser.document.addEventListener("visibilitychange", _ -> {
			focused = !Browser.document.hidden;
			services.focusInput(focused);
			if (!focused)
				services.suspendAudio();
		});
		Browser.window.addEventListener("unhandledrejection", e -> failure((cast e : Dynamic).reason));
		Browser.window.addEventListener("error", e -> failure((cast e : Dynamic).error));
		canvas.addEventListener("webglcontextlost", e -> {
			e.preventDefault();
			stopped = true;
			Browser.document.getElementById("status").textContent = "Graphics context lost. Reload to recover.";
		});
	}

	function failure(error:Dynamic):Void {
		stopped = true;
		var message = Std.string(error);
		Browser.document.getElementById("status").textContent = message;
		Browser.console.error(message);
	}

	function resize():Void {
		canvas.width = Std.int(Math.max(1, Browser.window.innerWidth * getPixelRatio()));
		canvas.height = Std.int(Math.max(1, Browser.window.innerHeight * getPixelRatio()));
	}

	public function run(app:IApp):Void {
		this.app = app;
		app.init();
		var previous = getTime();
		var loop:Float->Void = null;
		loop = _ -> {
			if (stopped)
				return;
			var current = getTime(), cpuStart = current;
			lastFrameInterval = (current - previous) * 1000;
			resources.poll();
			audioResources.poll();
			textures.poll();
			services.pollInput();
			app.frame(current - previous);
			services.endInputFrame();
			lastFrameCpu = (getTime() - cpuStart) * 1000;
			previous = current;
			// A quit during the frame closes after it, as natively.
			if (quitting)
				close();
			else if (!stopped)
				Browser.window.requestAnimationFrame(loop);
		};
		Browser.window.requestAnimationFrame(loop);
		Browser.window.addEventListener("pagehide", _ -> close());
	}

	var app:IApp;
	var quitting = false;

	/** Stops the frame loop and shuts down, once: the services, then the app's cleanup. The canvas keeps its last frame. */
	function close():Void {
		stopped = true;
		if (closed || app == null)
			return;
		closed = true;
		audioResources.shutdown();
		textures.shutdown();
		services.images.shutdown();
		resources.shutdown();
		app.cleanup();
		services.shutdownInput();
	}

	public function isFocused():Bool
		return focused;

	public function canQuit():Bool
		return false;

	public function getTime():Float
		return Browser.window.performance.now() / 1000;

	public function getFramebufferWidth():Int
		return canvas.width;

	public function getFramebufferHeight():Int
		return canvas.height;

	public function getPixelRatio():Float
		return Browser.window.devicePixelRatio;

	public function getOption(name:String, fallback:String):String {
		var v = params.get(name);
		return v == null ? fallback : v;
	}

	public function publish(value:Dynamic):Void {
		js.Syntax.code("window.result={0}", value);
	}

	public function expose(inspect:Void->Dynamic):Void {
		js.Syntax.code("window.inspect={0};window.graphicsContract={1};window.hostInfo={2}", inspect, graphics, getInfo);
	}

	public function capture(name:String = ""):Void {
		if (name != "")
			Browser.window.dispatchEvent(new js.html.CustomEvent("helix-capture", {detail: name}));
	}

	public function quit():Void
		quitting = true;

	var lastFrameCpu = 0.;
	var lastFrameInterval = 0.;

	public function getFrameCpu():Float
		return lastFrameCpu;

	public function getFrameInterval():Float
		return lastFrameInterval;

	public function getFrameAudit():Dynamic
		return null;

	public function memoryPhase(begin:Bool):Dynamic {
		var m:Dynamic = js.Syntax.code("performance.memory");
		return m == null ? null : {usedBytes: m.usedJSHeapSize, totalBytes: m.totalJSHeapSize, limitBytes: m.jsHeapSizeLimit};
	}

	public function getInfo():Dynamic {
		var value:Dynamic = services.info();
		value.assetReloads = resources.getReloads();
		return value;
	}

	#if hotreload
	// Development only: hotreload-hx's dev server says which served files changed; those under the asset base load again in place.
	var reloader:hotreload.Reloader;

	function watchAssets(base:Null<String>):Void {
		if (base == null)
			return;
		var prefix = new js.html.URL(base, Browser.location.href).pathname;
		reloader = new hotreload.Reloader();
		reloader.assetsChanged = urls -> assetsChanged(prefix, urls);
	}

	function assetsChanged(prefix:String, urls:Array<String>):Void
		for (url in urls)
			if (StringTools.startsWith(url, prefix))
				resources.changed(url.substr(prefix.length));
	#end
}
