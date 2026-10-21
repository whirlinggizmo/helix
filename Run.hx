import haxe.io.Path;
import sys.FileSystem;

/** `haxelib run helix <command>`: the library's front door (haxelib.json's `main`), running a command (tools/game/FrontDoor.hx) on the game
	in the folder it was given from: haxelib starts this in the library's folder and appends the caller's folder as the last argument (saying
	so with HAXELIB_RUN=1); run as `haxe --run Run` it works in the current folder. `shader` is still tools/game.py's, run with Python 3:
	HELIX_PYTHON names the Python, else `python3` (`python` on Windows) is looked for on PATH, and a clear message says when neither is
	there. Deliberately outside the framework's class path (src/), so no game compiles it. The commands: `--help`. */
class Run {
	static function main():Void {
		var args = Sys.args();
		var game = Sys.getCwd();
		if (Sys.getEnv("HAXELIB_RUN") == "1" && args.length > 0)
			game = args.pop();
		Sys.setCwd(game);
		Sys.exit(tools.game.FrontDoor.run(args, libraryRoot(), shader));
	}

	// tools/game.py's shader command with args, under Python 3.
	static function shader(args:Array<String>):Int {
		var python = findPython();
		if (python == null) {
			var chosen = Sys.getEnv("HELIX_PYTHON");
			Sys.stderr()
				.writeString(chosen != null
					&& chosen != "" ? 'helix: HELIX_PYTHON names $chosen, which is not there (a path, or a program on PATH)\n' : "helix: Python 3 was not found (" +
					defaultPython() + " on PATH); install it, or set HELIX_PYTHON to the Python to run\n");
			return 1;
		}
		return Sys.command(python, [Path.join([libraryRoot(), "tools", "game.py"]), "shader"].concat(args));
	}

	// The Python a system calls its own.
	static function defaultPython():String
		return Sys.systemName() == "Windows" ? "python" : "python3";

	// HELIX_PYTHON (a path, which must exist, or a program's name) or the system's Python, where PATH holds it; null when it holds none.
	static function findPython():Null<String> {
		var windows = Sys.systemName() == "Windows";
		var name = defaultPython();
		var chosen = Sys.getEnv("HELIX_PYTHON");
		if (chosen != null && chosen != "") {
			if (chosen.indexOf("/") >= 0 || chosen.indexOf("\\") >= 0)
				return FileSystem.exists(chosen) && !FileSystem.isDirectory(chosen) ? chosen : null;
			name = chosen;
		}
		var path = Sys.getEnv("PATH");
		if (path == null)
			return null;
		for (folder in path.split(windows ? ";" : ":")) {
			if (folder == "")
				continue;
			for (candidate in (windows ? [name + ".exe", name] : [name])) {
				var full = Path.join([folder, candidate]);
				if (FileSystem.exists(full) && !FileSystem.isDirectory(full))
					return full;
			}
		}
		return null;
	}

	// The library's folder, this file's, fixed as the build resolved it: not the working folder, which haxelib sets and a user may not.
	static macro function libraryRoot():haxe.macro.Expr {
		var file = haxe.macro.Context.resolvePath("Run.hx");
		var root = FileSystem.absolutePath(Path.directory(file));
		return macro $v{root};
	}
}
