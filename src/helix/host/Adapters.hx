package helix.host;

import helix.asset.IExport;
import helix.asset.IHttp;
import helix.asset.IStore;
import helix.audio.IAudio;
import helix.audio.IAudioDecoder;
import helix.debug.ITestHarness;
import helix.graphics.IGraphics;
import helix.graphics.IImageDecoder;
import helix.input.IInputSource;

/** A profile's choice of adapter for each platform contract, which the Runner builds the app's services over. */
typedef Adapters = {
	/** The GPU. */
	final graphics:IGraphics;

	/** Keyboard, mouse, touch and gamepads. */
	final input:IInputSource;

	/** Sound output. */
	final audio:IAudio;

	/** Compressed audio decoding. */
	final audioDecoder:IAudioDecoder;

	/** Image decoding. */
	final images:IImageDecoder;

	/** HTTP downloads. */
	final http:IHttp;

	/** The writable cache downloaded assets are kept in. */
	final storage:IStore;

	/** The assets shipped with the build, read when base is null (read-only). */
	final packaged:IStore;

	/** Opens the store the game's saves are kept in, apart from the cache (which a game may clear): called once, by the first use of Saves,
		so a game that saves nothing opens nothing. */
	final saves:Void->IStore;

	/** The URL prefix assets are fetched from; null reads them from packaged instead. */
	final base:Null<String>;

	/** The root asset manifest's path under base (IAssets.setManifest), or null for none. */
	final manifest:Null<String>;

	/** Where results go for the check that launched the program. */
	final harness:ITestHarness;

	/** Where files made for the user (screenshots) go. */
	final export:IExport;

	/** The program's name, beginning the names of the files it makes (Identity.product). */
	final name:String;
}
