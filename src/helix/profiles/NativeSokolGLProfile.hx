package helix.profiles;

import helix.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.adapters.host.sokol.SokolHostAdapter;
import helix.adapters.graphics.sokol.SokolGraphicsAdapter;
import helix.adapters.input.sokol.SokolInputAdapter;
import helix.adapters.audio.sokol.SokolAudioAdapter;
import helix.adapters.fetch.haxehttp.HaxeHttpFetchAdapter;
import helix.adapters.storage.filesystem.FileStorageAdapter;

/** Linux native composition; host and graphics share the existing Sokol context. */
class NativeSokolGLProfile extends SokolHostAdapter {
	/** A native host: assets from HELIX_ASSET_HOST when set, else from assets/ beside the program, cached in HELIX_CACHE or cache/ beside it. */
	public function new() {
		super(() -> {
			var root = haxe.io.Path.directory(Sys.programPath()),
				cache = Sys.getEnv("HELIX_CACHE");
			if (cache == null)
				cache = haxe.io.Path.join([root, "cache"]);
			var input = new SokolInputAdapter(),
				audio = new SokolAudioAdapter();
			return {
				graphics: new SokolGraphicsAdapter(),
				input: input,
				audio: audio,
				fetch: new HaxeHttpFetchAdapter(),
				storage: new FileStorageAdapter(cache),
				packaged: new FileStorageAdapter(haxe.io.Path.join([root, "assets"]), true),
				base: Sys.getEnv("HELIX_ASSET_HOST"),
				pollInput: input.poll,
				endInputFrame: input.endFrame,
				focusInput: active -> {},
				unlockAudio: () -> {},
				suspendAudio: () -> {},
				shutdownInput: input.shutdown,
				info: () -> {
					var value = audio.info();
					value.backend = "sokol-glcore";
					value.renderer = Std.string(GraphicsBridge.renderer());
					return value;
				}
			};
		});
	}
}
