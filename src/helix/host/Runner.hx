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
	frame it runs them in their order (the shared services' polls, input's, the presentation refitted to the window, the app's frame, input's frame end) with the clock and timings,
	and at its cleanup it closes them in theirs (the shared services, the app's cleanup, audio, input, the framework's pipelines, the GPU): the
	platform's services are the runner's to close, never the app's. The same on
	every platform: a host owns only the loop, the clock and the window. */
class Runner {
	/** What the app works with, filled at the host's init. */
	public final services:Services;

	var host:IHost;
	var compose:Void->Adapters;
	var adapters:Adapters;
	var app:IApp;
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
		services = new Services(this);
	}

	/** Runs app on the host: its init once the services are up, its frame once a display refresh, its cleanup at the end. Natively it returns
		only after the window closes. */
	public function run(app:IApp):Void {
		this.app = app;
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
		return resources != null && (resources.isBusy() || decoding.isBusy() || audioDecoding.isBusy() || services.environments.isBusy());

	/** The file at path (an asset path) changed: its assets load again in place. A development host's file watcher calls it. */
	public function assetChanged(path:String):Void
		if (resources != null)
			resources.changed(path);

	function init():Void {
		adapters = compose();
		var a = adapters, s = services;
		var fetch = new Fetch(a.http), storage = new Storage(a.storage);
		decoding = new ImageDecoding(a.images);
		audioDecoding = new AudioDecoding(a.audioDecoder);
		resources = new AssetService(fetch, storage, new Storage(a.packaged, true), a.base);
		resources.setManifest(a.manifest);
		s.graphics = a.graphics;
		input = new InputRouter();
		a.input.start(input);
		s.input = input.getInput();
		s.audio = a.audio;
		s.window = host.getWindow();
		s.fetch = fetch;
		s.storage = storage;
		s.assets = resources;
		s.audioResources = new AudioResources(resources, a.audio, audioDecoding);
		s.textures = new helix.render2d.Textures(resources, decoding, a.graphics);
		s.environments = new helix.render3d.Environments(resources, decoding, a.graphics);
		s.harness = a.harness;
		s.screenshots = new helix.graphics.Screenshots(a.graphics, a.export, a.name);
		app.init();
	}

	function frame():Void {
		var now = host.getTime();
		clock.frame(now);
		frameInterval = Math.isNaN(previousFrame) ? 0 : (now - previousFrame) * 1000;
		previousFrame = now;
		resources.poll();
		services.audioResources.poll();
		decoding.poll();
		audioDecoding.poll();
		services.environments.poll();
		input.poll(adapters.input);
		var window = services.window;
		services.presentation.refit(window.getFramebufferWidth(), window.getFramebufferHeight(), window.getPixelRatio());
		app.frame(clock.getDelta());
		services.screenshots.frameEnded();
		input.endFrame();
		frameCpu = (host.getTime() - now) * 1000;
	}

	function cleanup():Void {
		if (closed || adapters == null)
			return;
		closed = true;
		services.screenshots.shutdown();
		services.audioResources.shutdown();
		services.textures.shutdown();
		services.environments.shutdown();
		decoding.shutdown();
		audioDecoding.shutdown();
		resources.shutdown();
		app.cleanup();
		adapters.audio.shutdown();
		adapters.input.shutdown();
		helix.graphics.Pipelines.release(adapters.graphics);
		adapters.graphics.shutdown();
	}
}
