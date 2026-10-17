package helix.host;

import helix.app.IApp;
import helix.assets.AssetService;
import helix.assets.Fetch;
import helix.assets.Storage;
import helix.graphics.ImageDecoding;
import helix.audio.AudioDecoding;
import helix.audio.AudioResources;
import helix.input.InputRouter;

/** What a host pumps: at its init it builds the app's Services over a profile's adapters (and the engine's shared services over those), each
	frame it runs them in their order (the shared services' polls, input's, the presentation refitted to the window and the game's clock advanced, the app's frame, input's frame end) with the clock and timings,
	and at its cleanup it closes them in theirs (the shared services, the app's cleanup, audio, input, the framework's pipelines, the GPU): the
	platform's services are the runner's to close, never the app's. The same on
	every platform: a host owns only the loop, the clock and the window. */
class Runner {
	var host:IHost;
	var compose:Void->Adapters;
	var adapters:Adapters;
	var app:IApp;
	var makeApp:Void->IApp;
	var resources:AssetService;
	var decoding:ImageDecoding;
	var audioDecoding:AudioDecoding;
	var input:InputRouter;
	var clock = new FrameClock();
	var frameCpu = 0.;
	var frameInterval = 0.;
	var previousFrame = Math.NaN;
	var closed = false;

	/** A runner for host, building its services from compose's adapters when the host starts (natively the GPU exists only then). */
	public function new(host:IHost, compose:Void->Adapters) {
		this.host = host;
		this.compose = compose;
		Services.runner = this;
	}

	/** Runs the app makeApp builds on the host: built once the services are filled (so its field initializers may read them), its init then,
		its frame once a display refresh, its cleanup at the end. Natively it returns only after the window closes. */
	public function run(makeApp:Void->IApp):Void {
		this.makeApp = makeApp;
		host.run(init, frame, cleanup);
	}

	/** The host it runs on. */
	public function getHost():IHost
		return host;

	/** The frame clock. */
	public function getClock():FrameClock
		return clock;

	/** The last frame's CPU time in milliseconds. */
	public function getFrameCpu():Float
		return frameCpu;

	/** Milliseconds between the last two frames' starts (0 for the first). */
	public function getFrameInterval():Float
		return frameInterval;

	/** Whether the shared services are loading anything (Services.isBusy). */
	public function isBusy():Bool
		return resources != null && (resources.isBusy() || decoding.isBusy() || audioDecoding.isBusy() || Services.environments.isBusy());

	/** The file at path (an asset path) changed: its assets load again in place. A development host's file watcher calls it. */
	public function assetChanged(path:String):Void
		if (resources != null)
			resources.changed(path);

	function init():Void {
		adapters = compose();
		var a = adapters;
		var fetch = new Fetch(a.http), storage = new Storage(a.storage);
		decoding = new ImageDecoding(a.images);
		audioDecoding = new AudioDecoding(a.audioDecoder);
		resources = new AssetService(fetch, storage, new Storage(a.packaged, true), a.base);
		resources.setManifest(a.manifest);
		Services.graphics = a.graphics;
		input = new InputRouter();
		a.input.start(input);
		Services.input = input.getInput();
		Services.presentation = new Presentation();
		Services.clock = new helix.time.Clock();
		Services.audio = a.audio;
		Services.window = host.getWindow();
		Services.fetch = fetch;
		Services.storage = storage;
		Services.assets = resources;
		Services.audioResources = new AudioResources(resources, a.audio, audioDecoding);
		Services.textures = new helix.render2d.Textures(resources, decoding, a.graphics);
		Services.environments = new helix.render3d.Environments(resources, decoding, a.graphics);
		Services.harness = a.harness;
		Services.screenshots = new helix.graphics.Screenshots(a.graphics, a.export, a.name);
		app = makeApp();
		app.init();
	}

	function frame():Void {
		var now = host.getTime();
		clock.frame(now);
		frameInterval = Math.isNaN(previousFrame) ? 0 : (now - previousFrame) * 1000;
		previousFrame = now;
		resources.poll();
		Services.audioResources.poll();
		decoding.poll();
		audioDecoding.poll();
		Services.environments.poll();
		input.poll(adapters.input);
		var window = Services.window;
		Services.presentation.refit(window.getFramebufferWidth(), window.getFramebufferHeight(), window.getPixelRatio());
		Services.clock.update(clock.getElapsed());
		app.frame(clock.getDelta());
		Services.screenshots.frameEnded();
		input.endFrame();
		frameCpu = (host.getTime() - now) * 1000;
	}

	function cleanup():Void {
		if (closed || adapters == null)
			return;
		closed = true;
		Services.screenshots.shutdown();
		Services.audioResources.shutdown();
		Services.textures.shutdown();
		Services.environments.shutdown();
		decoding.shutdown();
		audioDecoding.shutdown();
		resources.shutdown();
		if (app != null)
			app.cleanup();
		adapters.audio.shutdown();
		adapters.input.shutdown();
		helix.graphics.Pipelines.release(adapters.graphics);
		adapters.graphics.shutdown();
		// Nothing to work with after the program's end: a read then fails plainly, on null.
		Services.graphics = null;
		Services.input = null;
		Services.audio = null;
		Services.window = null;
		Services.presentation = null;
		Services.clock = null;
		Services.assets = null;
		Services.fetch = null;
		Services.storage = null;
		Services.audioResources = null;
		Services.textures = null;
		Services.environments = null;
		Services.harness = null;
		Services.screenshots = null;
		Services.runner = null;
	}
}
