package helix.tools.shader;

import helix.tools.shader.JsonText;
import haxe.io.Path;
import helix.tools.shared.CommandError;

/** The packer as the repository's Python tools run it (tools/shader_tool.py), in the library's folder: `haxe --run helix.tools.shader.ShaderTool
	<command>`. Results go to the standard output (as JSON where they're data), messages to the standard error; a refusal exits with 1.

	- `pack [--sdl-gpu] IN OUT [IN OUT ...]`: each IN (.glsl) packed into its OUT (.hxshader).
	- `library OUT [--sdl-gpu-out DIR] [--sources DIR]`: the shader library packed into generated Haxe (ShaderPacker.packLibrary); the stems
	  packed, as a JSON array.
	- `translate`: the programs on the standard input (a JSON array, each {vertex, fragment, blocks, textures}) in SDL_GPU's dialects, as a
	  JSON array (GpuShaders.translate).
	- `shdc`: sokol-shdc's path, fetched when missing. */
class ShaderTool {
	static function main():Void {
		var root = Path.removeTrailingSlashes(Path.normalize(sys.FileSystem.absolutePath(Sys.getCwd())));
		var args = Sys.args();
		try {
			switch args.shift() {
				case "pack":
					var sdlGpu = args.remove("--sdl-gpu");
					if (args.length == 0 || args.length % 2 != 0)
						throw new CommandError("shader: pack takes IN OUT pairs");
					var packer = new ShaderPacker(root);
					var i = 0;
					while (i < args.length) {
						packer.pack(args[i], args[i + 1], sdlGpu);
						i += 2;
					}
				case "library":
					var out = args.shift();
					var gpuOut = option(args, "--sdl-gpu-out"),
						sources = option(args, "--sources");
					if (out == null || args.length > 0)
						throw new CommandError("shader: library OUT [--sdl-gpu-out DIR] [--sources DIR]");
					Sys.println(haxe.Json.stringify(new ShaderPacker(root).packLibrary(out, gpuOut, sources)));
				case "translate":
					var programs:Array<Dynamic> = haxe.Json.parse(Sys.stdin().readAll().toString());
					Sys.println(JsonText.compact(JArray([
						for (p in programs)
							GpuShaders.translate(root, p.vertex, p.fragment, p.blocks, p.textures)
					])));
				case "shdc":
					Sys.println(Shdc.path(root));
				case other:
					throw new CommandError('shader: unknown command $other: pack, library, translate or shdc');
			}
		} catch (error:CommandError) {
			Sys.stderr().writeString(error.message + "\n");
			Sys.exit(1);
		}
	}

	// The value after name in args, both removed; null when it isn't there.
	static function option(args:Array<String>, name:String):Null<String> {
		var at = args.indexOf(name);
		if (at < 0 || at + 1 >= args.length)
			return null;
		var value = args[at + 1];
		args.splice(at, 2);
		return value;
	}
}
