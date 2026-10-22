package helix.font;

import haxe.io.Bytes;

/** A glyph's outline in font units (y up): closed contours, each a list of points, x and y in turn, with whether each is on the curve; two
	off-curve points in a row have an on-curve point between them, as TrueType draws quadratic curves. */
typedef GlyphOutline = Array<{points:Array<Float>, onCurve:Array<Bool>}>;

/** A TrueType font file (glyf outlines) as read: its metrics, its characters' glyphs and their outlines, and the kerning between pairs (the
	GPOS table's pair adjustments, or the older kern table). Read in Haxe, the same on every target; Font bakes it into a texture. Throws,
	saying why, for a file it can't read: no glyf outlines (a CFF font), or a table missing or cut short. */
class TrueType {
	var data:Bytes;
	var tables = new Map<String, {offset:Int, length:Int}>();
	var glyphCount:Int;
	var longLoca:Bool;
	var metricCount:Int;
	var cmapOffset = -1;
	var cmapFormat = -1;

	/** Font units in an em: what the metrics below are counted in. */
	public final unitsPerEm:Int;

	/** How far the font reaches above the baseline, in font units. */
	public final ascent:Int;

	/** How far it reaches below the baseline, in font units: 0 or negative. */
	public final descent:Int;

	/** The extra space between lines, in font units. */
	public final lineGap:Int;

	/** Reads a TrueType file (the first font of a collection). */
	public function new(data:Bytes) {
		this.data = data;
		var at = 0;
		if (data.length >= 12 && data.getString(0, 4) == "ttcf")
			at = u32(12);
		if (data.length < at + 12)
			throw "Not a TrueType file";
		var version = u32(at);
		if (version == 0x4F54544F)
			throw "A CFF (PostScript outline) font: only TrueType (glyf) outlines are read";
		if (version != 0x00010000 && version != 0x74727565)
			throw "Not a TrueType file";
		var count = u16(at + 4);
		for (i in 0...count) {
			var record = at + 12 + i * 16;
			if (record + 16 > data.length)
				throw "Cut short (table records)";
			var offset = u32(record + 8), length = u32(record + 12);
			if (offset < 0 || length < 0 || offset + length > data.length)
				throw 'Cut short (table ${data.getString(record, 4)})';
			tables[data.getString(record, 4)] = {offset: offset, length: length};
		}
		for (name in ["head", "hhea", "hmtx", "maxp", "cmap", "loca", "glyf"])
			if (!tables.exists(name))
				throw 'No $name table';
		var head = table("head"), hhea = table("hhea");
		unitsPerEm = u16(head + 18);
		longLoca = s16(head + 50) != 0;
		ascent = s16(hhea + 4);
		descent = s16(hhea + 6);
		lineGap = s16(hhea + 8);
		metricCount = u16(hhea + 34);
		glyphCount = u16(table("maxp") + 4);
		findCmap();
	}

	inline function u8(at:Int):Int
		return data.get(at);

	inline function u16(at:Int):Int
		return data.get(at) << 8 | data.get(at + 1);

	inline function s16(at:Int):Int {
		var v = u16(at);
		return v >= 0x8000 ? v - 0x10000 : v;
	}

	inline function u32(at:Int):Int
		return data.get(at) << 24 | data.get(at + 1) << 16 | data.get(at + 2) << 8 | data.get(at + 3);

	function table(name:String):Int {
		var t = tables[name];
		return t == null ? -1 : t.offset;
	}

	// The best character map: Unicode's full range (format 12), else its basic plane (format 4).
	function findCmap():Void {
		var cmap = table("cmap"), count = u16(cmap + 2);
		for (i in 0...count) {
			var platform = u16(cmap + 4 + i * 8),
				encoding = u16(cmap + 6 + i * 8),
				offset = cmap + u32(cmap + 8 + i * 8);
			var unicode = platform == 0 || platform == 3 && (encoding == 1 || encoding == 10);
			if (!unicode)
				continue;
			var format = u16(offset);
			if (format == 12 || format == 4 && cmapFormat != 12) {
				cmapOffset = offset;
				cmapFormat = format;
			}
		}
		if (cmapOffset < 0)
			throw "No Unicode character map";
	}

	/** The glyph of character code, or 0 (the missing glyph) when the font has none. */
	public function getGlyphIndex(code:Int):Int {
		var at = cmapOffset;
		if (cmapFormat == 12) {
			var groups = u32(at + 12), low = 0, high = groups - 1;
			while (low <= high) {
				var middle = (low + high) >> 1, group = at + 16 + middle * 12;
				if (code < u32(group))
					high = middle - 1;
				else if (code > u32(group + 4))
					low = middle + 1;
				else
					return u32(group + 8) + code - u32(group);
			}
			return 0;
		}
		if (code > 0xFFFF)
			return 0;
		var segments = u16(at + 6) >> 1,
			ends = at + 14,
			starts = ends + segments * 2 + 2,
			deltas = starts + segments * 2,
			ranges = deltas + segments * 2;
		for (i in 0...segments) {
			if (code > u16(ends + i * 2))
				continue;
			var start = u16(starts + i * 2);
			if (code < start)
				return 0;
			var range = u16(ranges + i * 2);
			if (range == 0)
				return (code + u16(deltas + i * 2)) & 0xFFFF;
			var glyph = u16(ranges + i * 2 + range + (code - start) * 2);
			return glyph == 0 ? 0 : (glyph + u16(deltas + i * 2)) & 0xFFFF;
		}
		return 0;
	}

	/** How far the pen moves after glyph, in font units. */
	public function getAdvance(glyph:Int):Int {
		var hmtx = table("hmtx");
		return u16(hmtx + (glyph < metricCount ? glyph : metricCount - 1) * 4);
	}

	// Where glyph's data is in the file and how long, 0 for an empty glyph (a space).
	function glyphRange(glyph:Int):{offset:Int, length:Int} {
		if (glyph < 0 || glyph >= glyphCount)
			return {offset: 0, length: 0};
		var loca = table("loca"), glyf = table("glyf");
		var start = longLoca ? u32(loca + glyph * 4) : u16(loca + glyph * 2) * 2,
			end = longLoca ? u32(loca + glyph * 4 + 4) : u16(loca + glyph * 2 + 2) * 2;
		if (end <= start || glyf + end > data.length)
			return {offset: 0, length: 0};
		return {offset: glyf + start, length: end - start};
	}

	/** glyph's outline in font units, y up: empty for a glyph with none (a space). Composite glyphs are assembled from their parts. */
	public function getOutline(glyph:Int):GlyphOutline {
		var out:GlyphOutline = [];
		addOutline(glyph, [1, 0, 0, 1, 0, 0], out, 0);
		return out;
	}

	// Adds glyph's contours to out, each point placed by m (a, b, c, d, dx, dy: x' = a x + c y + dx, y' = b x + d y + dy).
	function addOutline(glyph:Int, m:Array<Float>, out:GlyphOutline, depth:Int):Void {
		var range = glyphRange(glyph);
		if (range.length < 10 || depth > 8)
			return;
		var at = range.offset, contours = s16(at);
		if (contours >= 0) {
			simple(at, contours, m, out);
			return;
		}
		// A composite: parts placed by offsets and, optionally, a scale or a 2x2 matrix.
		at += 10;
		var more = true;
		while (more) {
			var flags = u16(at), part = u16(at + 2);
			at += 4;
			var dx = 0., dy = 0.;
			if (flags & 1 != 0) {
				dx = s16(at);
				dy = s16(at + 2);
				at += 4;
			} else {
				dx = (u8(at) ^ 0x80) - 0x80;
				dy = (u8(at + 1) ^ 0x80) - 0x80;
				at += 2;
			}
			// Point-matched placement (args not x and y offsets) is rare and not read: the part goes unmoved.
			if (flags & 2 == 0)
				dx = dy = 0;
			var a = 1., b = 0., c = 0., d = 1.;
			inline function f2dot14(at:Int):Float
				return s16(at) / 16384;
			if (flags & 8 != 0) {
				a = d = f2dot14(at);
				at += 2;
			} else if (flags & 0x40 != 0) {
				a = f2dot14(at);
				d = f2dot14(at + 2);
				at += 4;
			} else if (flags & 0x80 != 0) {
				a = f2dot14(at);
				b = f2dot14(at + 2);
				c = f2dot14(at + 4);
				d = f2dot14(at + 6);
				at += 8;
			}
			// The part's transform, then the parent's.
			addOutline(part, [
				m[0] * a + m[2] * b,
				m[1] * a + m[3] * b,
				m[0] * c + m[2] * d,
				m[1] * c + m[3] * d,
				m[0] * dx + m[2] * dy + m[4],
				m[1] * dx + m[3] * dy + m[5]
			], out, depth + 1);
			more = flags & 0x20 != 0;
		}
	}

	function simple(at:Int, contours:Int, m:Array<Float>, out:GlyphOutline):Void {
		var ends = [for (i in 0...contours) u16(at + 10 + i * 2)];
		var count = contours == 0 ? 0 : ends[contours - 1] + 1;
		var p = at + 10 + contours * 2;
		p += 2 + u16(p); // the instructions, skipped
		var flags = [];
		while (flags.length < count) {
			var f = u8(p++);
			flags.push(f);
			if (f & 8 != 0) {
				var repeat = u8(p++);
				for (_ in 0...repeat)
					flags.push(f);
			}
		}
		var xs = [], ys = [], x = 0, y = 0;
		for (i in 0...count) {
			var f = flags[i];
			if (f & 2 != 0) {
				var dx = u8(p++);
				x += f & 16 != 0 ? dx : -dx;
			} else if (f & 16 == 0) {
				x += s16(p);
				p += 2;
			}
			xs.push(x);
		}
		for (i in 0...count) {
			var f = flags[i];
			if (f & 4 != 0) {
				var dy = u8(p++);
				y += f & 32 != 0 ? dy : -dy;
			} else if (f & 32 == 0) {
				y += s16(p);
				p += 2;
			}
			ys.push(y);
		}
		var first = 0;
		for (end in ends) {
			var points = [], onCurve = [];
			for (i in first...end + 1) {
				points.push(m[0] * xs[i] + m[2] * ys[i] + m[4]);
				points.push(m[1] * xs[i] + m[3] * ys[i] + m[5]);
				onCurve.push(flags[i] & 1 != 0);
			}
			if (onCurve.length > 1)
				out.push({points: points, onCurve: onCurve});
			first = end + 1;
		}
	}

	/** The horizontal kerning between glyphs left and right, in font units: added to left's advance (usually negative, closing the pair). From
		GPOS pair adjustments when the font has them, else its kern table; 0 for none. */
	public function getKerning(left:Int, right:Int):Int {
		if (tables.exists("GPOS")) {
			var gpos = gposKerning(left, right);
			if (gpos != null)
				return gpos;
		}
		return tables.exists("kern") ? kernKerning(left, right) : 0;
	}

	// The kern table's first horizontal format 0 subtable: pairs sorted by left << 16 | right.
	function kernKerning(left:Int, right:Int):Int {
		var kern = table("kern");
		if (u16(kern) != 0 || u16(kern + 2) < 1 || u16(kern + 8) & 3 != 1)
			return 0;
		var pairs = u16(kern + 10), low = 0, high = pairs - 1, key = left << 16 | right;
		while (low <= high) {
			var middle = (low + high) >> 1,
				pair = kern + 18 + middle * 6,
				k = u16(pair) << 16 | u16(pair + 2);
			if (key < k)
				high = middle - 1;
			else if (key > k)
				low = middle + 1;
			else
				return s16(pair + 4);
		}
		return 0;
	}

	// The first pair adjustment (GPOS lookup type 2, formats 1 and 2) for left then right: its x advance; null for none.
	function gposKerning(left:Int, right:Int):Null<Int> {
		var gpos = table("GPOS");
		if (u16(gpos) != 1)
			return null;
		var lookups = gpos + u16(gpos + 8), count = u16(lookups);
		for (l in 0...count) {
			var lookup = lookups + u16(lookups + 2 + l * 2),
				type = u16(lookup);
			var subtables = u16(lookup + 4);
			for (s in 0...subtables) {
				var sub = lookup + u16(lookup + 6 + s * 2);
				// An extension subtable points at its real one.
				var subType = type;
				if (type == 9 && u16(sub) == 1) {
					subType = u16(sub + 2);
					sub = sub + u32(sub + 4);
				}
				if (subType != 2)
					continue;
				var coverage = coverageIndex(sub + u16(sub + 2), left);
				if (coverage < 0)
					continue;
				var format = u16(sub),
					valueFormat1 = u16(sub + 4),
					valueFormat2 = u16(sub + 6);
				// Only a first value record that holds an x advance is read.
				if (valueFormat1 & 4 == 0)
					continue;
				var size1 = valueSize(valueFormat1),
					size2 = valueSize(valueFormat2);
				var xAdvance = 2 * bitsBelow(valueFormat1, 4);
				if (format == 1) {
					var set = sub + u16(sub + 10 + coverage * 2),
						pairs = u16(set),
						record = 2 + size1 + size2;
					var low = 0, high = pairs - 1;
					while (low <= high) {
						var middle = (low + high) >> 1,
							pair = set + 2 + middle * record,
							second = u16(pair);
						if (right < second)
							high = middle - 1;
						else if (right > second)
							low = middle + 1;
						else
							return s16(pair + 2 + xAdvance);
					}
				} else if (format == 2) {
					var class1 = classOf(sub + u16(sub + 8), left),
						class2 = classOf(sub + u16(sub + 10), right);
					var class2Count = u16(sub + 14);
					if (class1 >= u16(sub + 12) || class2 >= class2Count)
						continue;
					var record = sub + 16 + (class1 * class2Count + class2) * (size1 + size2);
					var value = s16(record + xAdvance);
					if (value != 0)
						return value;
				}
			}
		}
		return null;
	}

	// A value record's size in bytes: 2 for each bit of its format.
	static function valueSize(format:Int):Int
		return 2 * bitsBelow(format, 256);

	// How many bits of format are set below bit.
	static function bitsBelow(format:Int, bit:Int):Int {
		var n = 0, b = 1;
		while (b < bit) {
			if (format & b != 0)
				n++;
			b <<= 1;
		}
		return n;
	}

	// glyph's index in a coverage table, or -1.
	function coverageIndex(at:Int, glyph:Int):Int {
		var format = u16(at), count = u16(at + 2);
		if (format == 1) {
			var low = 0, high = count - 1;
			while (low <= high) {
				var middle = (low + high) >> 1, g = u16(at + 4 + middle * 2);
				if (glyph < g)
					high = middle - 1;
				else if (glyph > g)
					low = middle + 1;
				else
					return middle;
			}
		} else if (format == 2) {
			for (i in 0...count) {
				var range = at + 4 + i * 6;
				if (glyph >= u16(range) && glyph <= u16(range + 2))
					return u16(range + 4) + glyph - u16(range);
			}
		}
		return -1;
	}

	// glyph's class in a class definition table, 0 when it has none.
	function classOf(at:Int, glyph:Int):Int {
		var format = u16(at);
		if (format == 1) {
			var start = u16(at + 2), count = u16(at + 4);
			return glyph >= start && glyph < start + count ? u16(at + 6 + (glyph - start) * 2) : 0;
		}
		if (format == 2)
			for (i in 0...u16(at + 2)) {
				var range = at + 4 + i * 6;
				if (glyph >= u16(range) && glyph <= u16(range + 2))
					return u16(range + 4);
			}
		return 0;
	}
}
