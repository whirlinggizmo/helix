package helix.platform;

/** Represents the glyphs `IFontRasterizer.rasterizeOpened` returns, with the font's metrics at their size. */
typedef RasterFont = {
	/** A glyph for each codepoint asked for, in their order. */
	final glyphs:Array<RasterGlyph>;

	/** The font's ascent, in pixels above the baseline. */
	final ascent:Float;

	/** The font's descent, in pixels below the baseline, negative. */
	final descent:Float;

	/** The gap between one line's descent and the next line's ascent, in pixels. */
	final lineGap:Float;
}
