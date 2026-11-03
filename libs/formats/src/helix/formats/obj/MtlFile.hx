package helix.formats.obj;

import haxe.io.Bytes;

/** Represents a Wavefront material library read from an .mtl file, or several combined: the materials an OBJ model's `usemtl` lines
	name.

	Its text is decoded as UTF-8 when the bytes are UTF-8, and otherwise as Latin-1, each byte the character of its value (U+0000 to
	U+00FF), as older tools write files in their system's 8-bit encoding; a NUL byte is refused, as text has none. A name or path is
	kept as its characters: a path reaches the file system as a String, which each target spells as its file names are (UTF-8 on Linux
	and macOS and in URLs, UTF-16 on Windows), so a Latin-1 file's `é` names the file whose name is `é`.

	```haxe
	var library = MtlFile.read(bytes, "models/house.mtl");
	var wall = library.findMaterial("wall");
	var color = (wall != null ? wall : MtlMaterial.DEFAULT).computeDiffuse();
	``` */
class MtlFile {
	/** Gets the materials, in the file's order: a new one at each `newmtl` line. */
	public final materials:haxe.ds.ReadOnlyArray<MtlMaterial>;

	/** Returns the material of a name.

		@param name  The name, as `newmtl` gives it; case counts.
		@return  The material, the first when several share the name, or null when there is none of that name. */
	public function findMaterial(name:String):Null<MtlMaterial> {
		for (m in materials)
			if (m.name == name)
				return m;
		return null;
	}

	/** Returns several libraries as one, as an OBJ model that names them all uses them: their materials in turn, a name already
		given by an earlier library left out.

		@param libraries  The libraries, in the order the model names them; none gives a library with no materials.
		@return  The library. */
	public static function combine(libraries:Array<MtlFile>):MtlFile {
		var all = [], names = new Map<String, Bool>();
		for (library in libraries)
			for (m in library.materials)
				if (!names.exists(m.name)) {
					names.set(m.name, true);
					all.push(m);
				}
		return new MtlFile(all);
	}

	/** Reads a material library.

		@param bytes  The file's bytes: UTF-8 text, or Latin-1.
		@param path  The file's path, whose directory texture paths are resolved against.
		@return  The library.
		@throws String  Its bytes hold a NUL byte, or a line can't be read, naming its number: read each library apart to skip one
			that's broken. Only a String is thrown. */
	public static function read(bytes:Bytes, path:String):MtlFile {
		var lines = ObjText.lines(bytes);
		var materials:Array<MtlMaterial> = [];
		// The material being read: its name, colors, numbers and texture paths by statement; null before the first newmtl, whose
		// statements are ignored.
		var name:Null<String> = null;
		var colors = new Map<String, haxe.ds.ReadOnlyArray<Float>>(),
			numbers = new Map<String, Float>(),
			statements:Array<String> = [],
			paths:Array<String> = [];
		var illumination:Null<Int> = null;
		function flush():Void {
			if (name == null)
				return;
			var opacity:Null<Float> = numbers.exists("d") ? numbers.get("d") : numbers.exists("Tr") ? 1 - numbers.get("Tr") : null;
			materials.push(new MtlMaterial(name, true, colors, numbers, opacity, illumination, statements, paths));
		}
		for (k => text in lines) {
			var line = k + 1, words = ObjText.words(text);
			if (words.length == 0)
				continue;
			var keyword = words[0];
			if (keyword == "newmtl") {
				flush();
				name = ObjText.rest(text, "newmtl");
				if (name == "")
					throw 'Line $line: newmtl names no material';
				colors = new Map();
				numbers = new Map();
				statements = [];
				paths = [];
				illumination = null;
				continue;
			}
			if (name == null)
				continue;
			switch keyword {
				case "Ka" | "Kd" | "Ks" | "Ke" | "Tf":
					// "spectral" and "xyz" colors aren't read: the line is skipped.
					if (words.length > 1 && (words[1] == "spectral" || words[1] == "xyz"))
						continue;
					if (words.length != 2 && words.length != 4)
						throw 'Line $line: $keyword has ${words.length - 1} values, not 1 or 3';
					var r = ObjText.number(words[1], line);
					colors.set(keyword, words.length == 2 ? [r, r, r] : [r, ObjText.number(words[2], line), ObjText.number(words[3], line)]);
				case "Ns" | "Ni" | "d" | "Tr" | "Pr" | "Pm":
					// d's -halo option is read past.
					var at = keyword == "d" && words.length > 1 && words[1] == "-halo" ? 2 : 1;
					if (words.length != at + 1)
						throw 'Line $line: $keyword has ${words.length - 1} values, not 1';
					numbers.set(keyword, ObjText.number(words[at], line));
				case "illum":
					if (words.length != 2)
						throw 'Line $line: illum has ${words.length - 1} values, not 1';
					illumination = ObjText.integer(words[1], line);
				case "map_Ka" | "map_Kd" | "map_Ks" | "map_Ns" | "map_Ke" | "map_d" | "map_bump" | "map_Bump" | "bump" | "disp" | "norm" | "map_Pr" | "map_Pm":
					statements.push(keyword);
					paths.push(ObjText.resolve(texturePath(text, keyword, line), path));
				case _:
			}
		}
		flush();
		return new MtlFile(materials);
	}

	// A texture line's path: what follows its options, each option's values read past (`-o`, `-s` and `-t` take up to 3 numbers, `-mm` 2,
	// the rest 1).
	static function texturePath(text:String, keyword:String, line:Int):String {
		var rest = ObjText.rest(text, keyword);
		var words = ~/[ \t]+/g.split(rest), at = 0;
		while (at < words.length && StringTools.startsWith(words[at], "-") && !ObjText.isNumber(words[at])) {
			var option = words[at++];
			switch option {
				case "-o" | "-s" | "-t":
					var taken = 0;
					while (taken < 3 && at < words.length && ObjText.isNumber(words[at])) {
						at++;
						taken++;
					}
				case "-mm":
					at += 2;
				case _:
					at++;
			}
		}
		if (at >= words.length)
			throw 'Line $line: $keyword names no texture';
		return words.slice(at).join(" ");
	}

	function new(materials:haxe.ds.ReadOnlyArray<MtlMaterial>) {
		this.materials = materials;
	}
}
