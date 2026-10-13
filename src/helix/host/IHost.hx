package helix.host;

import helix.audio.IAudio;
import helix.audio.AudioResources;
import helix.assets.IAssets;
import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.input.IInput;
import helix.debug.IDiagnostics;
import helix.graphics.IGraphics;
import helix.app.IApp;

/** Composition and window lifecycle. Services have independent contracts. */
interface IHost {
	/** Drawing. Natively the services are set when run starts, before the app's init; in a browser, when the host is made. */
	public var graphics(default, null):IGraphics;

	/** Keyboard, mouse and touch. */
	public var input(default, null):IInput;

	/** Sound playback. */
	public var audio(default, null):IAudio;

	/** Sounds loaded through assets and decoded for audio. */
	public var audioResources(default, null):AudioResources;

	/** Downloads over the network. */
	public var fetch(default, null):IFetch;

	/** The writable cache: IndexedDB in a browser, files natively (HELIX_CACHE, or cache/ beside the program). */
	public var storage(default, null):IStorage;

	/** Assets by path, from the network, the cache or the build. */
	public var assets(default, null):IAssets;

	/** Experiment options, probes and captures. */
	public var diagnostics(default, null):IDiagnostics;

	/** The window the app draws in (the page, on the web). */
	public var window(default, null):IWindow;

	/** Whether the window (the page, on the web) has the keyboard. */
	public function isFocused():Bool;

	/** Whether quit() means anything: not in a browser page. */
	public function canQuit():Bool;

	/** Calls the app's init, then its frame once a display refresh, then its cleanup when the window or page closes. Natively it returns only after the window closes. */
	public function run(app:IApp):Void;

	/** Seconds on a monotonic clock. */
	public function getTime():Float;

	/** The drawable area in framebuffer pixels (IWindow's sizes are logical pixels). */
	public function getFramebufferWidth():Int;

	/** The drawable height in framebuffer pixels. */
	public function getFramebufferHeight():Int;

	/** Framebuffer pixels per logical pixel. */
	public function getPixelRatio():Float;

	/** Closes the window after this frame; the app's cleanup runs. In a browser page it only stops calling frame (canQuit). */
	public function quit():Void;
}
