package helix.raylib.internal;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import sys.FileSystem;

/** Points a program at raylib's types when it names one it hasn't imported: `Model` unresolved stops the build with the import that
	brings it, as a refused call names its replacement. Only raylib's type names, and only where nothing else defines the name, so a
	program's own `Model` is never touched. */
class TypeHints {
	/** Registers the hint with the compiler, from helix-raylib's extraParams.hxml. */
	public static function register():Void {
		var names:Null<Map<String, Bool>> = null;
		Context.onTypeNotFound(name -> {
			if (name.indexOf(".") >= 0)
				return null;
			if (names == null)
				names = typeNames();
			if (names.exists(name))
				Context.warning('$name is helix.raylib.$name: import helix.raylib.*;', Context.currentPos());
			return null;
		});
	}

	// The types of the package helix.raylib, by their modules' names: each type of raylib's is a module of its own there.
	static function typeNames():Map<String, Bool> {
		var names = new Map<String, Bool>();
		for (root in Context.getClassPath()) {
			var directory = Path.join([root == "" ? "." : root, "helix", "raylib"]);
			if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
				continue;
			for (file in FileSystem.readDirectory(directory))
				if (Path.extension(file) == "hx")
					names.set(Path.withoutExtension(file), true);
		}
		return names;
	}
}
#end
