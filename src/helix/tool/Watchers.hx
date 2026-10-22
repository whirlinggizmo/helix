package helix.tool;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import helix.tool.shader.ShaderPacker;
import helix.tool.shared.CommandError;
#end

/** What runs beside a game's dev loop, repacking a source as it changes, as macros an hxml of its own calls (`--macro
	helix.tool.Watchers.<watcher>(...)`), run by the compiler from the game's directory until Ctrl+C.

	- `watchShaders(?directory, sdlGpu = false)`: the game's `shaders/*.glsl` packed into `assets/shaders/<name>.hxshader` (or directory),
	  those changed since they were last packed at once, then again as each changes and as new ones appear; with sdlGpu, SDL_GPU's
	  dialects too. A shader that fails is reported and its last packed file kept, so the running page keeps it. When the assets carry
	  manifests (`tools/gen_manifest.py`'s), they're rewritten from their root down to the shaders' directory. */
class Watchers {
	#if macro
	/** The game's shaders packed into directory (assets/shaders), and again as they change, until Ctrl+C. */
	public static function watchShaders(?directory:String, sdlGpu = false):Void {
		var root = Path.normalize(Path.join([Path.directory(Context.resolvePath("helix/tool/Watchers.hx")), "..", "..", ".."]));
		try {
			new ShaderPacker(root).packShaders(".", [], directory == null ? "assets/shaders" : directory, sdlGpu, true, true);
		} catch (error:CommandError) {
			Sys.stderr().writeString(error.message + "\n");
			Sys.exit(1);
		}
	}
	#end
}
