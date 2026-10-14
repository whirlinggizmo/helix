package helix.host;

import helix.assets.IAssets;
import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.audio.AudioResources;
import helix.audio.IAudio;
import helix.debug.ITestHarness;
import helix.graphics.IGraphics;
import helix.input.IInput;

/** What an app has to work with: the platform's GPU, input, audio, window and storage, the engine's shared services over them (assets,
	sounds, textures, environments), the clock, run options and quitting. The Runner fills it as the program starts: an app keeps the object
	from its construction and reads the services from its init on. */
@:allow(helix.host.Runner)
class Services {
	/** The GPU. */
	public var graphics(default, null):IGraphics;

	/** Keyboard, mouse, touch and gamepads. */
	public var input(default, null):IInput;

	/** Sound output. */
	public var audio(default, null):IAudio;

	/** The window the app draws in (the page, on the web): its drawing surface's size, pixel ratio and focus too. */
	public var window(default, null):IWindow;

	/** Assets: the packaged files or downloads, cached. */
	public var assets(default, null):IAssets;

	/** Downloads. */
	public var fetch(default, null):IFetch;

	/** The writable cache. */
	public var storage(default, null):IStorage;

	/** Sounds loaded through the assets and decoded for audio. */
	public var audioResources(default, null):AudioResources;

	/** Textures from image files, reloading in place when a file changes during development. */
	public var textures(default, null):helix.render2d.Textures;

	/** Environment maps from equirectangular images, prepared a little each frame. */
	public var environments(default, null):helix.render3d.Environments;

	/** Where results go for the check that launched the program. */
	public var harness(default, null):ITestHarness;

	var runner:Runner;

	function new(runner:Runner)
		this.runner = runner;

	/** Seconds on the host's monotonic clock. */
	public function getTime():Float
		return runner.getHost().getTime();

	/** The seconds since the last frame, unheld (the app's frame dt is held at 0.1), and 0 on the first: what a fixed-rate simulation
		(Ticker.advance) is fed, so a slow frame is caught up in ticks instead of lost. */
	public function getFrameElapsed():Float
		return runner.getClock().getElapsed();

	/** The last frame's CPU time in milliseconds, its services' polls included. */
	public function getFrameCpu():Float
		return runner.getFrameCpu();

	/** Milliseconds between the last two frames' starts (0 for the first). */
	public function getFrameInterval():Float
		return runner.getFrameInterval();

	/** A run option, or fallback when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_
		and name in capitals. */
	public function getOption(name:String, fallback:String):String {
		var value = runner.getHost().getOption(name);
		return value == null ? fallback : value;
	}

	/** Whether quitting closes anything, so whether to offer a quit key: not in a browser page, where quit stops the program but the page stays. */
	public function canQuit():Bool
		return runner.getHost().canQuit();

	/** Ends the program after this frame: the services close and the app's cleanup runs. Natively the window closes; in a browser page the
		frames stop and the canvas keeps its last one. */
	public function quit():Void
		runner.getHost().quit();

	/** Backend facts: the graphics backend and renderer, the audio's, and how many assets have loaded again in place. */
	public function getInfo():Dynamic
		return runner.getInfo();
}
