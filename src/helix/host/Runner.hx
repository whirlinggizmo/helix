package helix.host;

import helix.hotreload.AppRouter;
import helix.asset.AssetService;
import helix.asset.Assets;
import helix.asset.Fetch;
import helix.asset.FetchService;
import helix.asset.Storage;
import helix.asset.StorageService;
import helix.audio.Audio;
import helix.audio.AudioDecoding;
import helix.audio.AudioResources;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.ImageDecoding;
import helix.graphics.ScreenshotService;
import helix.graphics.Screenshots;
import helix.input.Input;
import helix.input.InputRouter;
import helix.font.FontCache;
import helix.font.Fonts;
import helix.texture.TextureCache;
import helix.texture.Textures;
import helix.render3d.ModelCache3D;
import helix.render3d.Models3D;
import helix.scene.SceneFileCache3D;
import helix.scene.SceneFiles3D;
import helix.time.Clock;
import helix.time.Time;

/** What a host pumps: at its init it builds the app's services over a profile's adapters (and the engine's shared services over those) and
	binds the static classes the app reaches them by (Window, Input, Graphics, Audio, Assets, Time and the others), each
	frame it runs them in their order (the shared services' polls, input's, the presentation refitted to the window and the game's clock advanced, the app's update, the stage drawn, input's frame end) with the clock and timings,
	and at its cleanup it closes them in theirs (the shared services, the app's cleanup, audio, input, the framework's pipelines, the GPU) and
	unbinds the statics: the
	platform's services are the runner's to close, never the app's. The same on
	every platform: a host owns only the loop, the clock and the window. */
@:noCompletion
@:allow(helix)
class Runner {
	var compose:Void->Adapters;
	var adapters:Adapters;
	var router:AppRouter;
	var started = false;
	// The config's load as the program starts: the app's init waits for it to end, with or without a file.
	var configPending = false;
	var resources:AssetService;
	var decoding:ImageDecoding;
	var audioDecoding:AudioDecoding;
	var input:InputRouter;
	var presentation:Presentation;
	var gameClock:Clock;
	var sounds:AudioResources;
	var textures:TextureCache;
	var fonts:FontCache;
	var models:ModelCache3D;
	var sceneFiles:SceneFileCache3D;
	var screenshots:ScreenshotService;
	// The optional parts installed by their first use, in that order.
	var parts:Array<Part> = [];
	var previousFrame = Math.NaN;
	var closed = false;

	/** A runner for host, building its services from compose's adapters when the host starts (natively the GPU exists only then). */
	function new(host:IHost, compose:Void->Adapters) {
		this.host = host;
		this.compose = compose;
		Host.bind(host);
		Host.runner = this;
	}

	/** Runs the app router reaches on the host: its init once the services are filled and the game's config has come, its update once a
		display refresh, its cleanup at the end. Natively it returns only after the window closes. */
	function run(router:AppRouter):Void {
		this.router = router;
		host.run(() -> init(), () -> frame(), () -> cleanup());
	}

	/** The host it runs on. */
	var host(default, null):IHost;

	/** The frame clock. */
	var clock(default, null):FrameClock = new FrameClock();

	/** The last frame's CPU time in milliseconds. */
	var frameCpu(default, null):Float = 0.;

	/** Milliseconds between the last two frames' starts (0 for the first). */
	var frameInterval(default, null):Float = 0.;

	/** Whether the shared services are loading anything (Host.busy). */
	var busy(get, never):Bool;

	function get_busy():Bool
		return resources != null && (resources.busy || decoding.busy || audioDecoding.busy || partsBusy());

	function partsBusy():Bool {
		for (part in parts)
			if (part.busy != null && part.busy())
				return true;
		return false;
	}

	/** The assets, for an optional part built over them. */
	var assets(get, never):AssetService;

	function get_assets():AssetService
		return resources;

	/** The image decoder, for an optional part built over it. */
	var images(get, never):ImageDecoding;

	function get_images():ImageDecoding
		return decoding;

	/** The adapters the program runs on, for an optional part built over them. */
	var platform(get, never):Adapters;

	function get_platform():Adapters
		return adapters;

	/** Adds an optional part, its hooks run from now until the program's end. Its static class calls it, at the part's first use. */
	function install(part:Part):Void
		parts.push(part);

	/** The file at path (an asset path) changed: its assets load again in place. A development host's file watcher calls it. */
	function assetChanged(path:String):Void
		if (resources != null)
			resources.changed(path);

	function init():Void {
		adapters = compose();
		var a = adapters;
		var fetch = new FetchService(a.http),
			storage = new StorageService(a.storage);
		decoding = new ImageDecoding(a.images);
		audioDecoding = new AudioDecoding(a.audioDecoder);
		resources = new AssetService(fetch, storage, new StorageService(a.packaged, true), a.base);
		resources.setManifest(a.manifest);
		input = new InputRouter();
		a.input.start(input);
		presentation = new Presentation();
		gameClock = new Clock();
		sounds = new AudioResources(resources, a.audio, audioDecoding);
		textures = new TextureCache(resources, decoding, a.graphics);
		fonts = new FontCache(resources, a.graphics);
		models = new ModelCache3D(resources, textures);
		sceneFiles = new SceneFileCache3D(resources);
		screenshots = new ScreenshotService(a.graphics, a.export, a.name, presentation);
		Graphics.bind(a.graphics);
		Input.bind(input.input);
		Screen.bind(presentation);
		Time.bind(this, gameClock);
		Window.bind(host.window);
		Fetch.bind(fetch);
		Storage.bind(storage);
		Assets.bind(resources);
		Audio.bind(sounds);
		Textures.bind(textures);
		Fonts.bind(fonts);
		Models3D.bind(models);
		SceneFiles3D.bind(sceneFiles);
		TestHarness.bind(a.harness);
		Screenshots.bind(screenshots);
		// config.json beside the program, read now so a deployed game's settings change without a build; the app's init waits for it (a
		// frame or two, blank). None is no failure: the defaults stand.
		configPending = true;
		host.loadConfig(bytes -> {
			if (bytes != null)
				Host.config = Config.parse(bytes, host.getOption("config"));
			configPending = false;
		});
	}

	function frame():Void {
		var now = host.time;
		clock.frame(now);
		frameInterval = Math.isNaN(previousFrame) ? 0 : (now - previousFrame) * 1000;
		previousFrame = now;
		resources.poll();
		sounds.poll(clock.delta);
		decoding.poll();
		audioDecoding.poll();
		for (part in parts)
			if (part.poll != null)
				part.poll();
		input.poll(adapters.input);
		var window = host.window;
		presentation.refit(window.framebufferWidth, window.framebufferHeight, window.pixelRatio);
		gameClock.update(clock.elapsed);
		if (!started) {
			// Until the config has come: a blank frame, then the app begun.
			if (configPending) {
				adapters.graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff000000);
				adapters.graphics.endFrame();
				input.endFrame();
				frameCpu = (host.time - now) * 1000;
				return;
			}
			started = true;
			router.init();
		}
		router.update(clock.delta);
		for (part in parts)
			if (part.update != null)
				part.update(gameClock.delta);
		// The frame is the runner's: the stage draws it once the app has used it (docs/DISPLAY_MODEL.md); else it's cleared to black.
		var drawn = false;
		for (part in parts)
			if (part.draw != null) {
				part.draw();
				drawn = true;
			}
		if (!drawn) {
			adapters.graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff000000);
			adapters.graphics.endFrame();
		}
		screenshots.frameEnded();
		for (part in parts)
			if (part.frameEnded != null)
				part.frameEnded();
		input.endFrame();
		frameCpu = (host.time - now) * 1000;
	}

	function cleanup():Void {
		if (closed || adapters == null)
			return;
		closed = true;
		screenshots.shutdown();
		// The parts, the last installed first, before the shared services they're built over.
		var i = parts.length;
		while (i-- > 0)
			if (parts[i].shutdown != null)
				parts[i].shutdown();
		parts = [];
		sounds.shutdown();
		sceneFiles.shutdown();
		models.shutdown();
		fonts.shutdown();
		textures.shutdown();
		decoding.shutdown();
		audioDecoding.shutdown();
		resources.shutdown();
		if (started)
			router.cleanup();
		adapters.audio.shutdown();
		adapters.input.shutdown();
		helix.shader.ShaderLibrary.release(adapters.graphics);
		helix.graphics.Pipelines.release(adapters.graphics);
		adapters.graphics.shutdown();
		// Nothing to work with after the program's end: a read then fails plainly, on null.
		Graphics.bind(null);
		Input.bind(null);
		Screen.bind(null);
		Time.bind(null, null);
		Window.bind(null);
		Fetch.bind(null);
		Storage.bind(null);
		Assets.bind(null);
		Audio.bind(null);
		Textures.bind(null);
		Fonts.bind(null);
		Models3D.bind(null);
		SceneFiles3D.bind(null);
		TestHarness.bind(null);
		Screenshots.bind(null);
		Host.bind(null);
		Host.config = null;
		Host.runner = null;
	}
}
