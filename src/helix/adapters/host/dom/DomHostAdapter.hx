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
import helix.audio.AudioResources;
import helix.app.IApp;
import helix.host.HostCore;
import js.Browser;
import js.html.CanvasElement;

/** The browser host: the page's canvas, a requestAnimationFrame loop, and options from the URL query; the rest of a host is HostCore's. Its
	own IDiagnostics. */
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

	public var environments(default, null):helix.render3d.Environments;

	var focused = true;

	public var window(default, null):helix.host.IWindow;

	var core:HostCore;
	var canvas:CanvasElement;
	var stopped = false;
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
		core = new HostCore(services);
		assets = core.resources;
		audioResources = core.audioResources;
		textures = core.textures;
		environments = core.environments;
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
		var loop:Float->Void = null;
		loop = _ -> {
			if (stopped)
				return;
			core.frame(app, getTime(), getTime);
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

	/** Stops the frame loop and shuts down, once (HostCore.close). The canvas keeps its last frame. */
	function close():Void {
		stopped = true;
		if (app != null)
			core.close(app);
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

	public function getFrameElapsed():Float
		return core.clock.getElapsed();

	public function getFrameCpu():Float
		return core.getFrameCpu();

	public function getFrameInterval():Float
		return core.getFrameInterval();

	public function getFrameAudit():Dynamic
		return null;

	public function memoryPhase(begin:Bool):Dynamic {
		var m:Dynamic = js.Syntax.code("performance.memory");
		return m == null ? null : {usedBytes: m.usedJSHeapSize, totalBytes: m.totalJSHeapSize, limitBytes: m.jsHeapSizeLimit};
	}

	public function getInfo():Dynamic {
		var value:Dynamic = services.info();
		value.assetReloads = core.resources.getReloads();
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
				core.resources.changed(url.substr(prefix.length));
	#end
}
