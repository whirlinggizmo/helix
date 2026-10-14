package helix.profiles;

import helix.adapters.audiodecoder.libsndfile.LibsndfileAudioDecoderAdapter;
import helix.adapters.audiodecoder.libsndfile.LibsndfilePcmFiles;
import helix.adapters.audio.sokol.SokolAudioAdapter;
import helix.adapters.http.haxehttp.HaxeHttpAdapter;
import helix.adapters.graphics.sokol.SokolGraphicsAdapter;
import helix.adapters.testharness.stdio.StdioTestHarnessAdapter;
import helix.adapters.host.sokol.SokolHostAdapter;
import helix.adapters.imagedecoder.stb.StbImageDecoderAdapter;
import helix.adapters.inputsource.sokol.SokolInputSourceAdapter;
import helix.adapters.store.filesystem.FileSystemStoreAdapter;
import helix.app.IApp;
import helix.host.Runner;
import helix.host.Services;

/** Linux natively: a sokol_app window, sokol_gfx on GL 4.1, sokol_audio with libsndfile, evdev gamepads, haxe.Http and files, stb_image. */
class NativeSokolGLProfile {
	/** Runs the app makeApp builds over its services, for identity: assets from HELIX_ASSET_HOST when set, else from assets/ beside the program;
		downloads cached in HELIX_CACHE, else the user's cache directory for identity (FileSystemStoreAdapter.getCacheDirectory), else cache/ beside the
		program. Returns when the window closes. */
	public static function run(identity:helix.host.Identity, makeApp:Services->IApp):Void {
		var host = new SokolHostAdapter();
		var runner = new Runner(host, () -> {
			var root = haxe.io.Path.directory(Sys.programPath()), cache = Sys.getEnv("HELIX_CACHE");
			if (cache == null)
				cache = FileSystemStoreAdapter.getCacheDirectory(identity.getCompany(), identity.getProduct());
			if (cache == null)
				cache = haxe.io.Path.join([root, "cache"]);
			return {
				graphics: new SokolGraphicsAdapter(),
				input: new SokolInputSourceAdapter(),
				audio: new SokolAudioAdapter(new LibsndfilePcmFiles()),
				audioDecoder: new LibsndfileAudioDecoderAdapter(),
				images: new StbImageDecoderAdapter(),
				http: new HaxeHttpAdapter(),
				storage: new FileSystemStoreAdapter(cache),
				packaged: new FileSystemStoreAdapter(haxe.io.Path.join([root, "assets"])),
				base: Sys.getEnv("HELIX_ASSET_HOST"),
				harness: new StdioTestHarnessAdapter()
			};
		});
		runner.run(makeApp(runner.services));
	}
}
