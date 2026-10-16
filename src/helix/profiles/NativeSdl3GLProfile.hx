package helix.profiles;

import helix.adapters.audiodecoder.libsndfile.LibsndfileAudioDecoderAdapter;
import helix.adapters.audiodecoder.libsndfile.LibsndfilePcmFiles;
import helix.adapters.audio.sdl3.Sdl3AudioAdapter;
import helix.adapters.http.haxehttp.HaxeHttpAdapter;
import helix.adapters.graphics.sokol.SokolGraphicsAdapter;
import helix.adapters.testharness.stdio.StdioTestHarnessAdapter;
import helix.adapters.host.sdl3.Sdl3HostAdapter;
import helix.adapters.imagedecoder.stb.StbImageDecoderAdapter;
import helix.adapters.inputsource.sdl3.Sdl3InputSourceAdapter;
import helix.adapters.export.filesystem.FileSystemExportAdapter;
import helix.adapters.store.filesystem.FileSystemStoreAdapter;
import helix.app.IApp;
import helix.host.Runner;
import helix.host.Services;

/** The desktop through SDL3: an SDL window, its input and gamepads, sokol_gfx on GL 4.1 in its context, an SDL audio stream with libsndfile, haxe.Http and files, stb_image. */
class NativeSdl3GLProfile {
	/** Runs the app makeApp builds over its services, for identity: assets from HELIX_ASSET_HOST when set, else from assetFolder, a folder relative to the program's (a game's own: "assets", beside it);
		downloads cached in HELIX_CACHE, else the user's cache directory for identity (FileSystemStoreAdapter.getCacheDirectory), else cache/ beside the
		program; files made for the user (screenshots) in HELIX_EXPORT, else the user's pictures directory for the product
		(FileSystemExportAdapter.getPicturesDirectory), else exports/ beside the program. The window opens as options ask (the defaults when not given). Returns when the window closes. */
	public static function run(identity:helix.host.Identity, assetFolder:String, makeApp:Services->IApp, ?options:helix.host.WindowOptions):Void {
		var host = new Sdl3HostAdapter(options != null ? options.getMsaaSamples() : new helix.host.WindowOptions().getMsaaSamples(), true);
		var runner = new Runner(host, () -> {
			var root = haxe.io.Path.directory(Sys.programPath()), cache = Sys.getEnv("HELIX_CACHE");
			if (cache == null)
				cache = FileSystemStoreAdapter.getCacheDirectory(identity.getCompany(), identity.getProduct());
			if (cache == null)
				cache = haxe.io.Path.join([root, "cache"]);
			var exports = Sys.getEnv("HELIX_EXPORT");
			if (exports == null)
				exports = FileSystemExportAdapter.getPicturesDirectory(identity.getProduct());
			if (exports == null)
				exports = haxe.io.Path.join([root, "exports"]);
			return {
				graphics: new SokolGraphicsAdapter(),
				input: new Sdl3InputSourceAdapter(),
				audio: new Sdl3AudioAdapter(new LibsndfilePcmFiles()),
				audioDecoder: new LibsndfileAudioDecoderAdapter(),
				images: new StbImageDecoderAdapter(),
				http: new HaxeHttpAdapter(),
				storage: new FileSystemStoreAdapter(cache),
				packaged: new FileSystemStoreAdapter(haxe.io.Path.normalize(haxe.io.Path.join([root, assetFolder]))),
				base: Sys.getEnv("HELIX_ASSET_HOST"),
				harness: new StdioTestHarnessAdapter(),
				export: new FileSystemExportAdapter(exports),
				name: identity.getProduct()
			};
		});
		runner.run(makeApp(runner.services));
	}
}
