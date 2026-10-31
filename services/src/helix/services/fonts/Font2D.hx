package helix.services.fonts;

import helix.services.images.Image;

/** Represents a font made by `Fonts`: its metrics, its glyphs, and the atlas they are drawn from. */
class Font2D {
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

	final byCodepoint = new Map<Int, Glyph2D>();

	@:allow(helix.services.fonts)
	function new(size:Float, ascent:Float, descent:Float, lineGap:Float, atlas:Image, glyphs:Array<Glyph2D>) {
		this.size = size;
		this.ascent = ascent;
		this.descent = descent;
		this.lineGap = lineGap;
		this.atlas = atlas;
		this.glyphs = glyphs;
		for (glyph in glyphs)
			byCodepoint.set(glyph.codepoint, glyph);
	}

	/** Returns a character's glyph.

		@param codepoint  The character.
		@return  Its glyph, or null when the font has none. */
	public function getGlyph(codepoint:Int):Null<Glyph2D>
		return byCodepoint.get(codepoint);
}
