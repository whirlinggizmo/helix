package helix.services.fonts;

import helix.services.images.Image;

/** Represents a font: its kind, its metrics, its glyphs, the atlas they are drawn from, and its kerning pairs.

	`Fonts` makes one from a font file, or from glyph images (`Fonts.packFont`). A program or an engine layer holding a font's atlas and
	glyphs of its own (raylib's default font) constructs one. */
class Font2D {
	/** Gets what its glyphs hold: coverage, hard-edged coverage, or signed distances, as it was made. */
	public final kind:FontKind;

	/** Gets the size it was made at: the pixel height of a line from its ascent to its descent. */
	public final size:Float;

	/** Gets how far the tallest glyphs rise above the baseline, in pixels. */
	public final ascent:Float;

	/** Gets how far the lowest glyphs fall below it, in pixels, negative. */
	public final descent:Float;

	/** Gets the space a line leaves below its descent before the next line's ascent, in pixels. */
	public final lineGap:Float;

	/** Gets the atlas: white, each glyph's coverage (or distance) as alpha, rows top to bottom. */
	public final atlas:Image;

	/** Gets the glyphs, in the order their characters were asked for; a character the font lacks has none. */
	public final glyphs:Array<Glyph2D>;

	/** Gets the glyph the font draws for a character it lacks, its .notdef: a BMFont's invalid-character glyph (character -1, also among
		`glyphs`); null when the font has none, as a TrueType font loaded by `Fonts.load` has none. */
	public final notdef:Null<Glyph2D>;

	/** Gets the kerning pairs: a TrueType font's between the characters it was made with, from its `GPOS` pair adjustments or else its
		`kern` table; a BMFont's from its .fnt. Empty for a font with none. */
	public var kernings(get, never):Array<Kerning2D>;

	final byCodepoint = new Map<Int, Glyph2D>();
	var pairs:Null<Array<Kerning2D>>;
	var bySecond:Null<Map<Int, Map<Int, Float>>>;

	/** Creates a font from its atlas and its glyphs' places on it.

		@param kind  What its glyphs hold.
		@param size  The pixel height of a line from its ascent to its descent.
		@param ascent  How far the tallest glyphs rise above the baseline, in pixels.
		@param descent  How far the lowest fall below it, in pixels, negative.
		@param lineGap  The space between one line's descent and the next line's ascent, in pixels.
		@param atlas  The atlas: white, each glyph's coverage or distance as alpha.
		@param glyphs  The glyphs, each its place on the atlas.
		@param kernings  Optional. The kerning pairs; none when omitted.
		@param notdef  Optional. The glyph drawn for a character the font lacks, also among `glyphs`; none when omitted. */
	public function new(kind:FontKind, size:Float, ascent:Float, descent:Float, lineGap:Float, atlas:Image, glyphs:Array<Glyph2D>, ?kernings:Array<Kerning2D>,
			?notdef:Glyph2D) {
		this.kind = kind;
		this.size = size;
		this.ascent = ascent;
		this.descent = descent;
		this.lineGap = lineGap;
		this.atlas = atlas;
		this.glyphs = glyphs;
		this.notdef = notdef;
		pairs = kernings;
		for (glyph in glyphs)
			byCodepoint.set(glyph.codepoint, glyph);
	}

	function get_kernings():Array<Kerning2D> {
		if (pairs == null)
			pairs = [];
		return pairs;
	}

	/** Returns a character's glyph.

		@param codepoint  The character.
		@return  Its glyph, or null when the font has none. */
	public function getGlyph(codepoint:Int):Null<Glyph2D>
		return byCodepoint.get(codepoint);

	/** Returns how far the pen moves between two characters beyond the first's advance, from `kernings`.

		@param first  The first character.
		@param second  The character following it.
		@return  The amount, in pixels at the font's size: negative to close up, 0 for a pair the font doesn't kern. */
	public function getKerning(first:Int, second:Int):Float {
		if (bySecond == null) {
			bySecond = [];
			for (k in kernings) {
				var row = bySecond.get(k.first);
				if (row == null)
					bySecond.set(k.first, row = []);
				row.set(k.second, k.amount);
			}
		}
		var row = bySecond.get(first);
		if (row == null)
			return 0;
		var amount = row.get(second);
		return amount == null ? 0 : amount;
	}
}
