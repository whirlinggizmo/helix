package helix.host;

import helix.assets.Fetch;
import helix.assets.IAssets;
import helix.assets.Storage;
import helix.audio.AudioResources;
import helix.audio.IAudio;
import helix.debug.ITestHarness;
import helix.graphics.IGraphics;
import helix.input.IInput;

/** What an app has to work with: the platform's GPU, input, audio, window and storage, the engine's shared services over them (assets,
	sounds, textures, environments), the presentation, the clock, run options and quitting. One program, one set, so they're statics, as
	the earlier frameworks' and Godot's are (DECISIONS 114): any class reads `Services.window` without being handed it. The Runner fills them
	as the program starts and clears them at its end: an app reads them from its init on (a profile builds the app after they're filled, so
	a field initializer may read them too), and the framework's own classes in src/ never read them, taking what they use instead, so they
	stay testable apart. A test fills what it needs (`@:privateAccess`) and clears it after. Each field is `@:hot`, kept across a hot reload
	(DECISIONS 126), as nothing would set it again. */
@:allow(helix.host.Runner)
class Services {
	/** The GPU. */
	@:hot public static var graphics(default, null):IGraphics;

	/** Keyboard, mouse, touch and gamepads. */
	@:hot public static var input(default, null):IInput;

	/** Sound output. */
	@:hot public static var audio(default, null):IAudio;

	/** The window the app draws in (the page, on the web): its drawing surface's size, pixel ratio and focus too. */
	@:hot public static var window(default, null):IWindow;

	/** The app's design fitted to the window: its units, what's visible of them, and a 2D camera to show them (None, logical pixels, until
		the app sets a mode). */
	@:hot public static var presentation(default, null):Presentation;

	/** The game's time: the frames' time scaled and paused as a whole (helix.time.Clock), updated before each frame; what tickers, tweens,
		timers, animators and emitters are fed. */
	@:hot public static var clock(default, null):helix.time.Clock;

	/** Assets: the packaged files or downloads, cached. */
	@:hot public static var assets(default, null):IAssets;

	/** Downloads. */
	@:hot public static var fetch(default, null):Fetch;

	/** The writable cache. */
	@:hot public static var storage(default, null):Storage;

	/** Sounds loaded through the assets and decoded for audio. */
	@:hot public static var audioResources(default, null):AudioResources;

	/** Textures from image files, reloading in place when a file changes during development. */
	@:hot public static var textures(default, null):helix.render2d.Textures;

	/** Environment maps from equirectangular images, prepared a little each frame. */
	@:hot public static var environments(default, null):helix.render3d.Environments;

	/** Where results go for the check that launched the program. */
	@:hot public static var harness(default, null):ITestHarness;

	/** Screenshots of the frame, saved for the user (a download in a browser, a file natively). */
	@:hot public static var screenshots(default, null):helix.graphics.Screenshots;

	// The runner and every field above are kept across a hot reload (@:hot): set once by the runner, nothing would set them again.
	@:hot static var runner:Runner;

	/** Whether the runner has filled the services: false in a test that fills what it needs itself. */
	public static function isRunning():Bool
		return runner != null;

	/** Whether anything is still loading: an asset, an image or sound being decoded, an environment being prepared. A loading screen waits
		for it to be false (with the app's own loads in view); so does a tool taking the frame's picture once it's in. */
	public static function isBusy():Bool
		return runner != null && runner.isBusy();

	/** Seconds on the host's monotonic clock. */
	public static function getTime():Float
		return runner.getHost().getTime();

	/** The seconds since the last frame, unheld (the app's frame dt is held at 0.1), and 0 on the first: what a fixed-rate simulation
		(Ticker.advance) is fed, so a slow frame is caught up in ticks instead of lost. */
	public static function getFrameElapsed():Float
		return runner.getClock().getElapsed();

	/** The last frame's CPU time in milliseconds, its services' polls included. */
	public static function getFrameCpu():Float
		return runner.getFrameCpu();

	/** Milliseconds between the last two frames' starts (0 for the first). */
	public static function getFrameInterval():Float
		return runner.getFrameInterval();

	/** The game's settings from config.json among its assets (Config), or null without one. */
	@:hot public static var config(default, null):Null<Config>;

	/** A run option, or fallback when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_
		and name in capitals; else the config's value at name (its profile over its default, dotted into nested objects), as text. */
	public static function getOption(name:String, fallback:String):String {
		var value = runner.getHost().getOption(name);
		if (value == null && config != null)
			value = config.getString(name);
		return value == null ? fallback : value;
	}

	/** getOption as a bool: 1, true, yes and on are true, 0, false, no and off are false; fallback for anything else. */
	public static function getOptionBool(name:String, fallback:Bool):Bool
		return Config.toBool(getOption(name, null), fallback);

	/** getOption as a number; fallback for anything that isn't one. */
	public static function getOptionFloat(name:String, fallback:Float):Float
		return Config.toFloat(getOption(name, null), fallback);

	/** getOption as a whole number; fallback for anything that isn't one. */
	public static function getOptionInt(name:String, fallback:Int):Int
		return Config.toInt(getOption(name, null), fallback);

	/** Whether quitting closes anything, so whether to offer a quit key: not in a browser page, where quit stops the program but the page stays. */
	public static function canQuit():Bool
		return runner.getHost().canQuit();

	/** Ends the program after this frame: the services close and the app's cleanup runs. Natively the window closes; in a browser page the
		frames stop and the canvas keeps its last one. */
	public static function quit():Void
		runner.getHost().quit();
}
