package helix.tool.setup;

import helix.tool.shared.CommandError;
import helix.tool.shared.Downloads;
import helix.tool.shared.Files;
import haxe.io.Path;
import helix.tool.shader.GpuShaders;
import helix.tool.shader.Shdc;

/** `setup`: the tools the commands fetch or build the first time they need them, made ready ahead (for a machine about to go offline, or a
	CI's cache), then listed: each one's version, where it is and the room it takes. */
class ToolCache {
	/** sokol-shdc made ready, and SDL_GPU's translators too when sdlGpu, for the library at root; each tool listed on the standard output,
		those not asked for as they stand. */
	public static function run(root:String, sdlGpu:Bool):Void {
		var pins:Dynamic = haxe.Json.parse(sys.io.File.getContent(Path.join([root, "dependencies.json"])));
		var tools = [
			{
				name: "sokol-shdc",
				version: (pins.sokolToolsBin : String).substr(0, 12),
				variable: "HELIX_SHDC",
				make: Shdc.path,
				location: Shdc.location,
				wanted: true
			},
			{
				name: "spirv-cross",
				version: pins.gpuShaders.spirvCross.version,
				variable: "HELIX_SPIRV_CROSS",
				make: GpuShaders.spirvCross,
				location: GpuShaders.spirvCrossLocation,
				wanted: sdlGpu
			},
			{
				name: "glslang",
				version: pins.gpuShaders.glslang.version,
				variable: "HELIX_GLSLANG",
				make: GpuShaders.glslang,
				location: GpuShaders.glslangLocation,
				wanted: sdlGpu
			}
		];
		var rows = [];
		for (tool in tools) {
			var given = Downloads.given(tool.variable);
			if (given != null) {
				rows.push([tool.name, tool.variable, given, megabytes(Files.size(given))]);
				continue;
			}
			if (tool.wanted)
				tool.make(root);
			var program = try tool.location(root) catch (error:CommandError) {
				rows.push([tool.name, tool.version, error.message, ""]);
				continue;
			}
			if (Files.isFile(program))
				rows.push([tool.name, tool.version, program, megabytes(Files.size(directoryOf(program)))]);
			else
				rows.push([
					tool.name,
					tool.version,
					"not there yet: setup --sdl-gpu (only SDL_GPU's dialects need it)",
					""
				]);
		}
		var widths = [0, 0, 0];
		for (row in rows)
			for (column in 0...3)
				if (row[column].length > widths[column])
					widths[column] = row[column].length;
		for (row in rows) {
			var cells = [for (column in 0...3) StringTools.rpad(row[column], " ", widths[column])];
			Sys.println(StringTools.rtrim(cells.join("  ") + "  " + row[3]));
		}
		Sys.println('cache: ${Downloads.cache()}');
	}

	// The tool's own directory in the cache: what's under it all belongs to it.
	static function directoryOf(program:String):String {
		var cache = Downloads.cache();
		return Path.join([cache, Files.relative(program, cache).split("/")[0]]);
	}

	static function megabytes(bytes:Float):String
		return '${Math.round(bytes / 104857.6) / 10} MB';
}
