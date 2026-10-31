import helix.formats.truetype.TrueTypeTables;

/** Checks TrueTypeTables with the library alone, on a real font (JetBrains Mono, `tests/assets`, SIL Open Font License 1.1, embedded
	as the test compiles): its units per em and
	vertical metrics, a glyph found for a codepoint it has and none for one it lacks, an advance, a box and an empty glyph's, the scale
	for a pixel height, and what isn't a font. */
class TrueTypeTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// A file's bytes, read as the test compiles: the path is from the repository's root, beside this file's directory's parent.
	static macro function embed(path:String):haxe.macro.Expr {
		var root = haxe.io.Path.directory(haxe.io.Path.directory(haxe.macro.Context.getPosInfos(haxe.macro.Context.currentPos()).file));
		var file = haxe.io.Path.join([root == "" ? "." : root, "..", path]);
		return macro haxe.crypto.Base64.decode($v{haxe.crypto.Base64.encode(sys.io.File.getBytes(file))});
	}

	static function main():Void {
		var bytes = embed("formats/tests/assets/JetBrainsMono-Regular.ttf");
		var tables = new TrueTypeTables(bytes);
		check(tables.unitsPerEm == 1000, "head: JetBrains Mono's 1000 units per em");
		check(tables.ascent == 1020 && tables.descent == -300 && tables.lineGap == 0, "hhea: its ascent, descent and line gap");
		check(tables.hasGlyf, "it has TrueType outlines");
		var a = tables.glyphIndex("A".code);
		check(a != 0, "cmap: A has a glyph");
		check(tables.glyphIndex(0x4E00) == 0, "cmap: U+4E00 has none");
		check(tables.advance(a) == 600, "hmtx: a monospace advance of 600");
		var box = tables.box(a);
		check(box != null && box[0] >= 0 && box[2] <= 600 && box[1] == 0 && box[3] > 0 && box[3] <= tables.ascent, "glyf: A's box, on the baseline");
		check(tables.box(tables.glyphIndex(" ".code)) == null, "glyf: a space has no outline");
		check(tables.scaleFor(32) == 32 / 1320, "scaleFor: a pixel height over ascent less descent");
		var refused = try {
			new TrueTypeTables(haxe.io.Bytes.ofString("not a font at all"));
			false;
		} catch (e:String)
			true;
		check(refused, "what isn't a font throws");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
