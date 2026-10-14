package helix.profiles;

import helix.adapters.audio.libsndfile.LibsndfileDecoder;
import helix.adapters.audio.libsndfile.LibsndfileFiles;
import helix.adapters.audio.sokol.SokolAudioAdapter;
import helix.adapters.fetch.haxehttp.HaxeHttpFetchAdapter;
import helix.adapters.graphics.sokol.SokolGraphicsAdapter;
import helix.adapters.harness.stdio.StdioTestHarness;
import helix.adapters.host.sokol.SokolHostAdapter;
import helix.adapters.images.stb.StbImagesAdapter;
import helix.adapters.input.sokol.SokolInputAdapter;
import helix.adapters.storage.filesystem.FileStorageAdapter;
import helix.app.IApp;
import helix.host.Runner;
import helix.host.Services;

/** Linux natively: a sokol_app window, sokol_gfx on GL 4.1, sokol_audio with libsndfile, evdev gamepads, haxe.Http and files, stb_image. */
class NativeSokolGLProfile {
	/** Runs the app makeApp builds over its services, for identity: assets from HELIX_ASSET_HOST when set, else from assets/ beside the program;
		downloads cached in HELIX_CACHE, else the user's cache directory for identity (FileStorageAdapter.getCacheDirectory), else cache/ beside the
		program. Returns when the window closes. */
	public static function run(identity:helix.host.Identity, makeApp:Services->IApp):Void {
		var host = new SokolHostAdapter();
		var runner = new Runner(host, () -> {
			var root = haxe.io.Path.directory(Sys.programPath()), cache = Sys.getEnv("HELIX_CACHE");
			if (cache == null)
				cache = FileStorageAdapter.getCacheDirectory(identity.getCompany(), identity.getProduct());
			if (cache == null)
				cache = haxe.io.Path.join([root, "cache"]);
			return {
				graphics: new SokolGraphicsAdapter(),
				input: new SokolInputAdapter(),
				audio: new SokolAudioAdapter(new LibsndfileFiles()),
				audioDecoder: new LibsndfileDecoder(),
				images: new StbImagesAdapter(),
				http: new HaxeHttpFetchAdapter(),
				storage: new FileStorageAdapter(cache),
				packaged: new FileStorageAdapter(haxe.io.Path.join([root, "assets"])),
				base: Sys.getEnv("HELIX_ASSET_HOST"),
				harness: new StdioTestHarness()
			};
		});
		runner.run(makeApp(runner.services));
	}
}
