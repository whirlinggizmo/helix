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
import helix.adapters.export.filesystem.FileSystemExportAdapter;
import helix.adapters.store.filesystem.FileSystemStoreAdapter;
import helix.app.IApp;
import helix.host.Runner;

/** Linux natively: a sokol_app window, sokol_gfx on GL 4.1, sokol_audio with libsndfile, evdev gamepads, haxe.Http and files, stb_image. */
class NativeSokolGLProfile {
	/** Runs the app makeApp builds once its services are bound, for identity: assets from HELIX_ASSET_HOST when set (following the manifest tree from HELIX_ASSET_MANIFEST under it when that's set too,
		"manifest.json"), else from assetFolder, a folder relative to the program's (a game's own: "assets", beside it);
		downloads cached in HELIX_CACHE, else the user's cache directory for identity (FileSystemStoreAdapter.getCacheDirectory), else cache/ beside the
		program; files made for the user (screenshots) in HELIX_EXPORT, else the user's pictures directory for the product
		(FileSystemExportAdapter.getPicturesDirectory), else exports/ beside the program. The window opens as options ask (the defaults when not given). Returns when the window closes. */
	public static function run(identity:helix.host.Identity, assetFolder:String, makeApp:Void->IApp, ?options:helix.host.WindowOptions):Void {
		var host = new SokolHostAdapter(options != null ? options.msaaSamples : new helix.host.WindowOptions().msaaSamples);
		var runner = new Runner(host, () -> {
			var root = haxe.io.Path.directory(Sys.programPath()), cache = Sys.getEnv("HELIX_CACHE");
			if (cache == null)
				cache = FileSystemStoreAdapter.getCacheDirectory(identity.company, identity.product);
			if (cache == null)
				cache = haxe.io.Path.join([root, "cache"]);
			var exports = Sys.getEnv("HELIX_EXPORT");
			if (exports == null)
				exports = FileSystemExportAdapter.getPicturesDirectory(identity.product);
			if (exports == null)
				exports = haxe.io.Path.join([root, "exports"]);
			return {
				graphics: new SokolGraphicsAdapter(),
				input: new SokolInputSourceAdapter(),
				audio: new SokolAudioAdapter(new LibsndfilePcmFiles()),
				audioDecoder: new LibsndfileAudioDecoderAdapter(),
				images: new StbImageDecoderAdapter(),
				http: new HaxeHttpAdapter(),
				storage: new FileSystemStoreAdapter(cache),
				packaged: new FileSystemStoreAdapter(haxe.io.Path.normalize(haxe.io.Path.join([root, assetFolder]))),
				base: Sys.getEnv("HELIX_ASSET_HOST"),
				manifest: Sys.getEnv("HELIX_ASSET_MANIFEST"),
				harness: new StdioTestHarnessAdapter(),
				export: new FileSystemExportAdapter(exports),
				name: identity.product
			};
		});
		runner.run(makeApp);
	}
}
