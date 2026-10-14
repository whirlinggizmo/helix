package helix.host;

import helix.assets.IHttp;
import helix.assets.IStore;
import helix.audio.IAudio;
import helix.debug.ITestHarness;
import helix.graphics.IGraphics;
import helix.graphics.IImageDecoder;
import helix.input.IInputDevice;

/** A profile's choice of adapter for each platform contract, which the Runner builds the app's Services over. */
typedef Adapters = {
	/** The GPU. */
	var graphics:IGraphics;

	/** Keyboard, mouse, touch and gamepads. */
	var input:IInputDevice;

	/** Sound output and decoding. */
	var audio:IAudio;

	/** Image decoding. */
	var images:IImageDecoder;

	/** HTTP downloads. */
	var http:IHttp;

	/** The writable cache downloaded assets are kept in. */
	var storage:IStore;

	/** The assets shipped with the build, read when base is null (read-only). */
	var packaged:IStore;

	/** The URL prefix assets are fetched from; null reads them from packaged instead. */
	var base:Null<String>;

	/** Where results go for the check that launched the program. */
	var harness:ITestHarness;

	/** Backend facts for Services.getInfo: the graphics backend, its renderer, the audio's. */
	var info:Void->Dynamic;
}
