package helix.platform;

import haxe.io.Bytes;

/** Defines rasterizing a TrueType or OpenType font's glyphs at a size, as 8-bit coverage or signed distances.

	Sizes and metrics are stb_truetype's: the size is the font's pixel height (its ascent minus its descent), and every length is in
	pixels at that size. */
interface IFontRasterizer extends IPollable {
	/** Rasterizes glyphs as 8-bit coverage, off the main thread where the platform can.

		One of `rasterized` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The font file's bytes, TTF or OTF; the first font of a collection is not read.
		@param size  The pixel height.
		@param codepoints  The glyphs wanted.
		@param rasterized  Receives a glyph for each codepoint, in their order, and the font's ascent, descent (below the baseline,
			negative) and line gap.
		@param failed  Receives why the font can't be read. */
	function rasterize(encoded:Bytes, size:Float, codepoints:Array<Int>,
		rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void;

	/** Rasterizes glyphs as signed distances to their outlines, off the main thread where the platform can.

		A glyph has 4 pixels of padding around its outline; a pixel on the outline is 128, and each pixel inside is 64 more, each outside
		64 less, clamped to 0 and 255. One of `rasterized` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The font file's bytes, TTF or OTF; the first font of a collection is not read.
		@param size  The pixel height.
		@param codepoints  The glyphs wanted.
		@param rasterized  Receives a glyph for each codepoint, in their order, and the font's ascent, descent (below the baseline,
			negative) and line gap.
		@param failed  Receives why the font can't be read. */
	function rasterizeDistanceField(encoded:Bytes, size:Float, codepoints:Array<Int>,
		rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Closes the rasterizer. A rasterize still running finishes without calling back. */
	function dispose():Void;
}
