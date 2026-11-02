package helix.formats.truetype;

import haxe.io.Bytes;
import helix.formats.text.Utf8Text;

/** Represents the tables of a TrueType or OpenType font, read as stb_truetype reads them.

	It reads the vertical metrics (`hhea`), the units per em (`head`), each codepoint's glyph (`cmap`, the subtable stb_truetype picks),
	its advance (`hmtx`) and, for TrueType outlines, its box (`glyf`), so glyphs are found, measured and placed as a native build places
	them. An OpenType font with CFF outlines has no `glyf`: `hasGlyf` is false, and its boxes are not read. Nothing is drawn: outlines,
	kerning and font collections are not read.

	```haxe
	var tables = new TrueTypeTables(bytes);
	var scale = tables.scaleFor(32);
	var advance = tables.advance(tables.glyphIndex("A".code)) * scale;
	``` */
class TrueTypeTables {
	final data:Bytes;
	final head:Int;
	final hhea:Int;
	final hmtx:Int;
	final loca:Int;
	final glyf:Int;
	final indexMap:Int;

	/** Gets the font's units per em, from `head`. */
	public final unitsPerEm:Int;

	/** Gets the font's ascent, from `hhea`: in font units above the baseline, y up. */
	public final ascent:Int;

	/** Gets the font's descent, from `hhea`: in font units, y up, so below the baseline it is negative. */
	public final descent:Int;

	/** Gets the font's line gap, from `hhea`: in font units, the space between one line's descent and the next line's ascent. */
	public final lineGap:Int;

	/** Reads a font's tables.

		The bytes are kept, not copied: the glyph lookups read them.

		@param data  The font file.
		@throws String  It isn't a TrueType or OpenType font, or lacks a table stb_truetype needs. */
	public function new(data:Bytes) {
		this.data = data;
		if (data.length < 12)
			throw "not a TrueType or OpenType font";
		var version = u32(0);
		if (version != 0x00010000 && version != 0x4F54544F && version != 0x74727565 && version != 0x00020000)
			throw "not a TrueType or OpenType font";
		head = find("head");
		hhea = find("hhea");
		hmtx = find("hmtx");
		var cmap = find("cmap");
		if (head < 0 || hhea < 0 || hmtx < 0 || cmap < 0)
			throw "not a TrueType or OpenType font: a table it needs is missing";
		glyf = find("glyf");
		loca = find("loca");
		unitsPerEm = u16(head + 18);
		ascent = s16(hhea + 4);
		descent = s16(hhea + 6);
		lineGap = s16(hhea + 8);
		// As stb_truetype: the last Unicode subtable, Microsoft's BMP or full, or any of the Unicode platform's.
		var map = -1;
		for (i in 0...u16(cmap + 2)) {
			var record = cmap + 4 + 8 * i,
				platform = u16(record),
				encoding = u16(record + 2);
			if (platform == 3 && (encoding == 1 || encoding == 10) || platform == 0)
				map = cmap + u32(record + 4);
		}
		if (map < 0)
			throw "the font has no Unicode character map";
		indexMap = map;
	}

	/** Returns the scale for a pixel height, as stb_truetype's `ScaleForPixelHeight`.

		@param size  The pixel height.
		@return  Pixels per font unit. */
	public function scaleFor(size:Float):Float
		return size / (ascent - descent);

	/** Gets a value indicating whether the font has TrueType outlines in `glyf`, whose boxes `box` reads. */
	public var hasGlyf(get, never):Bool;

	function get_hasGlyf():Bool
		return glyf >= 0 && loca >= 0;

	/** Returns a codepoint's glyph, as stb_truetype's `FindGlyphIndex` finds it, or 0 for none.

		@param codepoint  The codepoint.
		@return  The glyph index. */
	public function glyphIndex(codepoint:Int):Int {
		var map = indexMap;
		switch u16(map) {
			case 0:
				var bytes = u16(map + 2);
				return codepoint < bytes - 6 ? data.get(map + 6 + codepoint) : 0;
			case 6:
				var first = u16(map + 6), count = u16(map + 8);
				return codepoint >= first && codepoint < first + count ? u16(map + 10 + (codepoint - first) * 2) : 0;
			case 4:
				if (codepoint > 0xffff)
					return 0;
				var segments = u16(map + 6) >> 1,
					ends = map + 14,
					starts = ends + segments * 2 + 2;
				for (i in 0...segments) {
					if (u16(ends + i * 2) < codepoint)
						continue;
					var start = u16(starts + i * 2);
					if (codepoint < start)
						return 0;
					var rangeOffset = u16(starts + segments * 4 + i * 2);
					// stb_truetype adds the delta only where there is no range offset.
					if (rangeOffset == 0)
						return (codepoint + s16(starts + segments * 2 + i * 2)) & 0xffff;
					return u16(starts + segments * 4 + i * 2 + rangeOffset + (codepoint - start) * 2);
				}
				return 0;
			case 12 | 13:
				var groups = u32(map + 12);
				for (i in 0...groups) {
					var group = map + 16 + i * 12,
						start = u32(group),
						end = u32(group + 4);
					if (codepoint < start)
						return 0;
					if (codepoint <= end)
						return u16(map) == 12 ? u32(group + 8) + codepoint - start : u32(group + 8);
				}
				return 0;
			case _:
				return 0;
		}
	}

	/** Returns a glyph's advance, in font units.

		@param glyphIndex  The glyph index.
		@return  The advance. */
	public function advance(glyphIndex:Int):Int {
		var metrics = u16(hhea + 34);
		return u16(hmtx + 4 * (glyphIndex < metrics ? glyphIndex : metrics - 1));
	}

	/** Returns a TrueType glyph's box, in font units: x0, y0, x1, y1, y up; null for one with no outline.

		Only a font with `hasGlyf` has boxes to read.

		@param glyphIndex  The glyph index.
		@return  The box. */
	public function box(glyphIndex:Int):Null<Array<Int>> {
		var long = s16(head + 50) == 1;
		var start = long ? u32(loca + glyphIndex * 4) : u16(loca + glyphIndex * 2) * 2,
			end = long ? u32(loca + glyphIndex * 4 + 4) : u16(loca + glyphIndex * 2 + 2) * 2;
		if (start == end)
			return null;
		var at = glyf + start;
		return [s16(at + 2), s16(at + 4), s16(at + 6), s16(at + 8)];
	}

	function find(tag:String):Int {
		for (i in 0...u16(4)) {
			var record = 12 + 16 * i;
			if (record + 16 > data.length)
				break;
			if (Utf8Text.matchesAscii(data, record, tag))
				return u32(record + 8);
		}
		return -1;
	}

	inline function u16(at:Int):Int
		return data.get(at) << 8 | data.get(at + 1);

	inline function s16(at:Int):Int {
		var v = u16(at);
		return v >= 0x8000 ? v - 0x10000 : v;
	}

	inline function u32(at:Int):Int
		return data.get(at) << 24 | data.get(at + 1) << 16 | data.get(at + 2) << 8 | data.get(at + 3);
}
