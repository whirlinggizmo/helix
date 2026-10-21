package helix.macro;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.io.Process;
#end

/** What a build on `-lib helix` needs beyond the library's class path, run by the library's extraParams.hxml
	(`--macro helix.macro.Haxelib.configure()`), so a game's hxml carries nothing of the library's layout:

	- the generated code's class paths, `generated/shaders` and `generated/fonts` at the library's root (the framework's programs, the
	  packed shader library and the built-in font, committed and shipped: docs/DECISIONS.md 138), and `generated/shaders-sdlgpu` when the
	  build defines `helix_sdl3_gpu` (SDL_GPU's dialects, which only its builds carry);
	- natively, hxcpp's architecture define for this machine, `HXCPP_ARM64` on arm64 and `HXCPP_M64` elsewhere, when the build sets none
	  (hxcpp picks 32-bit on Windows from a 64-bit process, which has no `PROCESSOR_ARCHITEW6432`).

	The repository's own builds list the class paths and the define themselves (`tools/example.py`), which is also what the dev loop watches. */
class Haxelib {
	#if macro
	/** Adds the generated code's class paths and, natively, this machine's architecture define. */
	public static function configure():Void {
		var root = Path.normalize(Path.join([Path.directory(Context.resolvePath("helix/macro/Haxelib.hx")), "..", "..", ".."]));
		Compiler.addClassPath(Path.join([root, "generated", "shaders"]));
		Compiler.addClassPath(Path.join([root, "generated", "fonts"]));
		if (Context.defined("helix_sdl3_gpu"))
			Compiler.addClassPath(Path.join([root, "generated", "shaders-sdlgpu"]));
		if (Context.defined("cpp")
			&& !Context.defined("HXCPP_M64")
			&& !Context.defined("HXCPP_M32")
			&& !Context.defined("HXCPP_ARM64"))
			Compiler.define(isArm64() ? "HXCPP_ARM64" : "HXCPP_M64");
	}

	/** True on an arm64 machine (Apple silicon, Linux aarch64, Windows on ARM): hxcpp's own test, read from the process here. */
	static function isArm64():Bool {
		if (Sys.systemName() == "Windows") {
			var arch = Sys.getEnv("PROCESSOR_ARCHITEW6432");
			if (arch == null)
				arch = Sys.getEnv("PROCESSOR_ARCHITECTURE");
			return arch != null && arch.toUpperCase() == "ARM64";
		}
		var process = new Process("uname", ["-m"]);
		var output = process.stdout.readAll().toString();
		process.close();
		return output.indexOf("aarch64") >= 0 || output.indexOf("arm64") >= 0;
	}
	#end
}
