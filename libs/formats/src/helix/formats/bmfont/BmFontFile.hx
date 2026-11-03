package helix.formats.bmfont;

/** Represents a bitmap font read from AngelCode BMFont's text format (.fnt): its size and line metrics, its pages, glyphs and kerning
	pairs, in pixels.

	`read` takes the file's text and its path. The pages are images in files of their own, each path resolved against the .fnt file's
	directory, for the caller to load. Each line is a tag (`info`, `common`, `page`, `char`, `kerning`) and its `key=value` pairs, a value
	quoted when it holds spaces; unknown tags and keys are skipped, and a key a line omits reads as 0. BMFont's XML and binary formats
	are not read.

	```haxe
	var font = BmFontFile.read(text, "fonts/title.fnt");
	for (page in font.pages) load(page.path);
	``` */
class BmFontFile {
	/** Gets the font's face name, `info`'s `face`: empty when the file gives none. */
	public final face:String;

	/** Gets the size the font was made at, `info`'s `size`, in pixels: negative when it is the glyphs' cell height rather than the
		em's. */
	public final size:Int;

	/** Gets the distance from one line's top to the next's, `common`'s `lineHeight`, in pixels. */
	public final lineHeight:Int;

	/** Gets the distance from a line's top to its baseline, `common`'s `base`, in pixels. */
	public final base:Int;

	/** Gets the width of each page's image, `common`'s `scaleW`, in pixels. */
	public final scaleWidth:Int;

	/** Gets the height of each page's image, `common`'s `scaleH`, in pixels. */
	public final scaleHeight:Int;

	/** Gets the font's pages, in the file's order. */
	public final pages:Array<BmFontPage>;

	/** Gets the font's glyphs, in the file's order. */
	public final chars:Array<BmFontChar>;

	/** Gets the font's kerning pairs, in the file's order: empty when it has none. */
	public final kernings:Array<BmFontKerning>;

	/** Reads a BMFont text file.

		@param text  The file's text.
		@param path  The file's path, against whose directory its pages' paths are resolved.
		@return  The font.
		@throws String  It is not BMFont's text format (it has no `common` line, or is BMFont's XML or binary format), or a number in it
			isn't one. */
	public static function read(text:String, path:String):BmFontFile {
		if (StringTools.startsWith(text, "BMF"))
			throw "A binary BMFont file: only the text format is read";
		if (StringTools.startsWith(StringTools.ltrim(text), "<"))
			throw "An XML BMFont file: only the text format is read";
		return new BmFontFile(text, haxe.io.Path.directory(path));
	}

	function new(text:String, directory:String) {
		var face = "", size = 0, lineHeight = 0, base = 0, scaleWidth = 0, scaleHeight = 0, common = false;
		pages = [];
		chars = [];
		kernings = [];
		var number = 0;
		for (raw in text.split("\n")) {
			number++;
			var line = StringTools.trim(raw);
			var space = 0;
			while (space < line.length && !StringTools.isSpace(line, space))
				space++;
			var values = pairs(line, space);
			function int(key:String):Int {
				var value = values.get(key);
				if (value == null)
					return 0;
				var parsed = Std.parseInt(value);
				if (parsed == null)
					throw 'Line $number: $key=$value is not a number';
				return parsed;
			}
			switch line.substr(0, space) {
				case "info":
					face = values.exists("face") ? values.get("face") : "";
					size = int("size");
				case "common":
					common = true;
					lineHeight = int("lineHeight");
					base = int("base");
					scaleWidth = int("scaleW");
					scaleHeight = int("scaleH");
				case "page":
					var file = values.exists("file") ? values.get("file") : "";
					pages.push(new BmFontPage(int("id"), directory == "" ? file : directory + "/" + file));
				case "char":
					chars.push(new BmFontChar(int("id"), int("x"), int("y"), int("width"), int("height"), int("xoffset"), int("yoffset"), int("xadvance"),
						int("page"), int("chnl")));
				case "kerning":
					kernings.push(new BmFontKerning(int("first"), int("second"), int("amount")));
				case _:
			}
		}
		if (!common)
			throw "Not a BMFont text file: it has no common line";
		this.face = face;
		this.size = size;
		this.lineHeight = lineHeight;
		this.base = base;
		this.scaleWidth = scaleWidth;
		this.scaleHeight = scaleHeight;
	}

	// A line's key=value pairs from at on, a quoted value's quotes taken off; a key without a value is empty.
	static function pairs(line:String, at:Int):Map<String, String> {
		var values = new Map<String, String>();
		while (at < line.length) {
			while (at < line.length && StringTools.isSpace(line, at))
				at++;
			var start = at;
			while (at < line.length && line.charAt(at) != "=" && !StringTools.isSpace(line, at))
				at++;
			var key = line.substring(start, at);
			var value = "";
			if (at < line.length && line.charAt(at) == "=") {
				at++;
				if (at < line.length && line.charAt(at) == '"') {
					var end = line.indexOf('"', at + 1);
					if (end < 0)
						end = line.length;
					value = line.substring(at + 1, end);
					at = end + 1;
				} else {
					start = at;
					while (at < line.length && !StringTools.isSpace(line, at))
						at++;
					value = line.substring(start, at);
				}
			}
			if (key != "")
				values.set(key, value);
		}
		return values;
	}
}
