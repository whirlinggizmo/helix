package helix.host;

import helix.app.IApp;
import helix.assets.AssetService;
import helix.audio.AudioResources;

/** What every host does the same way, whatever its platform: from the platform's services (HostServices) it builds the shared ones (assets,
	sounds, textures, environments), runs a frame in their order (the services' polls, the input's, the app's frame, the input's frame end)
	with its clock and timings, and closes in their order (the services, the app's cleanup, the input, the framework's pipelines, the
	GPU). A host adapter keeps only its platform's part: the loop that calls frame, the window, time, options and diagnostics. */
class HostCore {
	/** The platform's services. */
	public var services(default, null):HostServices;

	/** Assets: the packaged files or downloads, cached. */
	public var resources(default, null):AssetService;

	/** Sounds loaded through the assets and decoded for audio. */
	public var audioResources(default, null):AudioResources;

	/** Textures from image files. */
	public var textures(default, null):helix.render2d.Textures;

	/** Environment maps from equirectangular images. */
	public var environments(default, null):helix.render3d.Environments;

	/** The frame clock: the app's delta and the unheld elapsed time. */
	public var clock(default, null) = new FrameClock();

	var frameCpu = 0.;
	var frameInterval = 0.;
	var previousFrame = Math.NaN;
	var closed = false;

	/** The shared services over services. */
	public function new(services:HostServices) {
		this.services = services;
		resources = new AssetService(services.fetch, services.storage, services.packaged, services.base);
		audioResources = new AudioResources(resources, services.audio);
		textures = new helix.render2d.Textures(resources, services.images, services.graphics);
		environments = new helix.render3d.Environments(resources, services.images, services.graphics);
	}

	/** One frame at now (seconds, the host's clock), which getTime reads again after: the services' polls, the input's, app's frame, the
		input's frame end; the frame's interval and CPU time measured. */
	public function frame(app:IApp, now:Float, getTime:Void->Float):Void {
		clock.frame(now);
		frameInterval = Math.isNaN(previousFrame) ? 0 : (now - previousFrame) * 1000;
		previousFrame = now;
		resources.poll();
		audioResources.poll();
		textures.poll();
		environments.poll();
		services.pollInput();
		app.frame(clock.getDelta());
		services.endInputFrame();
		frameCpu = (getTime() - now) * 1000;
	}

	/** The last frame's CPU time in milliseconds. */
	public function getFrameCpu():Float
		return frameCpu;

	/** Milliseconds between the last two frames' starts (0 for the first). */
	public function getFrameInterval():Float
		return frameInterval;

	/** Closes, once: the shared services, the image decoder and the assets, then app's cleanup, the input, the framework's pipelines and the
		GPU. */
	public function close(app:IApp):Void {
		if (closed)
			return;
		closed = true;
		audioResources.shutdown();
		textures.shutdown();
		environments.shutdown();
		services.images.shutdown();
		resources.shutdown();
		app.cleanup();
		services.shutdownInput();
		helix.graphics.Pipelines.release(services.graphics);
		services.graphics.shutdown();
	}
}
