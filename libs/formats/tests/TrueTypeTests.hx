import helix.formats.truetype.TrueTypeTables;

/** Checks TrueTypeTables with the library alone, on a real font (JetBrains Mono, `tests/assets`, SIL Open Font License 1.1, embedded
	as the test compiles): its units per em and
	vertical metrics, a glyph found for a codepoint it has and none for one it lacks, an advance, a box and an empty glyph's, the scale
	for a pixel height, and what isn't a font; and kerning, on fonts the test makes (three glyphs, for A, B and C): `kern`'s pairs, and
	`GPOS`'s pair adjustments by pair and by class taking precedence over `kern`, as stb_truetype reads them. (On DejaVu Sans, Liberation
	Sans, FreeSans and FreeSerif, every pair of U+0020 to U+017E kerned the same as stb_truetype's `GetGlyphKernAdvance`, checked apart.) */
class TrueTypeTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// Big-endian 16-bit values as bytes.
	static function words(values:Array<Int>):haxe.io.Bytes {
		var b = haxe.io.Bytes.alloc(values.length * 2);
		for (i in 0...values.length) {
			b.set(i * 2, values[i] >> 8 & 0xff);
			b.set(i * 2 + 1, values[i] & 0xff);
		}
		return b;
	}

	// A font of the tables given, with a head, hhea, hmtx and cmap of its own: glyphs 1, 2 and 3 for A, B and C.
	static function made(extra:Map<String, haxe.io.Bytes>):haxe.io.Bytes {
		var tables = [
			"head" => words([for (i in 0...27) i == 9 ? 1000 : 0]),
			"hhea" => words([for (i in 0...18) i == 2 ? 800 : i == 3 ? 0x10000 - 200 : i == 17 ? 4 : 0]),
			"hmtx" => words([500, 0, 500, 0, 500, 0, 500, 0]),
			"cmap" => words([0, 1, 3, 1, 0, 12, 6, 16, 0, 65, 3, 1, 2, 3])
		];
		for (tag => bytes in extra)
			tables.set(tag, bytes);
		var tags = [for (tag in tables.keys()) tag];
		var out = new haxe.io.BytesBuffer(), at = 12 + 16 * tags.length;
		out.add(words([1, 0, tags.length, 0, 0, 0]));
		for (tag in tags) {
			out.addString(tag);
			out.add(words([0, 0, at >> 16, at & 0xffff, 0, tables[tag].length]));
			at += tables[tag].length + 3 & ~3;
		}
		for (tag in tags) {
			out.add(tables[tag]);
			for (_ in 0...(4 - tables[tag].length % 4) % 4)
				out.addByte(0);
		}
		return out.getBytes();
	}

	static function kerning():Void {
		// kern: one horizontal format-0 table, A then B closing up by 50, B then A opening by 30.
		var kern = words([0, 1, 0, 30, 1, 2, 0, 0, 0, 1, 2, 0x10000 - 50, 2, 1, 30]);
		var kerned = new TrueTypeTables(made(["kern" => kern]));
		check(kerned.hasKerning && kerned.kerning(1, 2) == -50 && kerned.kerning(2, 1) == 30 && kerned.kerning(1, 3) == 0,
			"kern: a pair's adjustment, none for a pair it doesn't list");
		check(kerned.canKern(1) && kerned.canKern(2) && !kerned.canKern(3), "kern: which glyphs start a pair");
		// GPOS: two pair adjustment lookups. The first by pairs: A then B by -40, A then C by -10. The second by classes: B and C (class 1
		// of the first) then A (class 1 of the second) by 25.
		var pairs = words([2, 0, 1, 8, 1, 12, 4, 0, 1, 18, 1, 1, 1, 2, 2, 0x10000 - 40, 3, 0x10000 - 10]);
		var classes = words([
			2, 0, 1, 8, 2, 24, 4, 0, 34, 44, 2, 2, 0, 0, 0, 25, 2, 1, 2, 3, 0, 1, 2, 2, 1, 1, 2, 1, 1, 1, 1
		]);
		var lookups = words([2, 6, 6 + pairs.length]);
		var list = new haxe.io.BytesBuffer();
		list.add(words([1, 0, 0, 0, 10]));
		list.add(lookups);
		list.add(pairs);
		list.add(classes);
		var gpos = new TrueTypeTables(made([
			"GPOS" => list.getBytes(),
			"kern" => words([0, 1, 0, 24, 1, 1, 0, 0, 0, 1, 2, 0x10000 - 999])
		]));
		check(gpos.kerning(1, 2) == -40 && gpos.kerning(1, 3) == -10, 'GPOS: by pairs, taking precedence over the kern table: ${gpos.kerning(1, 2)}');
		check(gpos.kerning(2, 1) == 25 && gpos.kerning(3, 1) == 25 && gpos.kerning(2, 3) == 0 && gpos.kerning(1, 1) == 0,
			"GPOS: by classes; a class pair of none, and a glyph no lookup covers, 0");
		check(gpos.canKern(1) && gpos.canKern(2) && gpos.canKern(3), "GPOS: the glyphs its lookups cover start a pair");
	}

	// A file's bytes, read as the test compiles: the path is from the library's directory, this file's directory's parent.
	static macro function embed(path:String):haxe.macro.Expr {
		var root = haxe.io.Path.directory(haxe.io.Path.directory(haxe.macro.Context.getPosInfos(haxe.macro.Context.currentPos()).file));
		var file = haxe.io.Path.join([root == "" ? "." : root, path]);
		return macro haxe.crypto.Base64.decode($v{haxe.crypto.Base64.encode(sys.io.File.getBytes(file))});
	}

	static function main():Void {
		var bytes = embed("tests/assets/JetBrainsMono-Regular.ttf");
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
		// A damaged font: a TrueType version, one table, its tag bytes that aren't UTF-8 (a browser's getString throws a RangeError for
		// them, not a String).
		var damaged = haxe.io.Bytes.alloc(64);
		damaged.set(1, 1);
		damaged.set(5, 1);
		for (i in 0...4)
			damaged.set(12 + i, [0xF4, 0x90, 0x80, 0x80][i]);
		var why = try {
			new TrueTypeTables(damaged);
			null;
		} catch (e:String)
			e;
		check(why != null && why.indexOf("missing") >= 0, "a table tag that isn't text throws a String: the tables are missing");
		// A table count running past the file's end.
		var short = haxe.io.Bytes.alloc(12);
		short.set(1, 1);
		short.set(4, 0xFF);
		var shortWhy = try {
			new TrueTypeTables(short);
			null;
		} catch (e:String)
			e;
		check(shortWhy != null, "a table directory past the file's end throws a String");
		check(!tables.hasKerning || tables.kerning(a, tables.glyphIndex("V".code)) == 0, "a monospace font kerns nothing");
		kerning();
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
