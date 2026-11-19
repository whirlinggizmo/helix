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

	/** Opens a font, so its glyphs are rasterized during a call (`rasterizeOpened`, `rasterizeDistanceFieldOpened`) at any size.
		Opening is what a page does only asynchronously, the browser loading the font as a face.

		One of `opened` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The font file's bytes, TTF or OTF; the first font of a collection is not read.
		@param opened  Receives the opened font, until `closeFont`.
		@param failed  Receives why the font can't be read. */
	function openFont(encoded:Bytes, opened:(font:Int) -> Void, failed:String->Void):Void;

	/** Returns an opened font's glyphs as 8-bit coverage, rasterized on the main thread during the call, as `rasterize` returns them.

		@param font  The font, from `openFont`.
		@param size  The pixel height.
		@param codepoints  The glyphs wanted.
		@return  A glyph for each codepoint, in their order, and the font's metrics at the size. */
	function rasterizeOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont;

	/** Returns an opened font's glyphs as signed distances to their outlines, rasterized on the main thread during the call, as
		`rasterizeDistanceField` returns them.

		@param font  The font, from `openFont`.
		@param size  The pixel height.
		@param codepoints  The glyphs wanted.
		@return  A glyph for each codepoint, in their order, and the font's metrics at the size. */
	function rasterizeDistanceFieldOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont;

	/** Closes a font `openFont` opened. Its id is then no font's.

		@param font  The font. */
	function closeFont(font:Int):Void;

	/** Delivers what finished on the platform's threads since the last poll. The program calls it once a frame. */
	function poll():Void;

	/** Closes the rasterizer. A rasterize still running finishes without calling back. */
	function dispose():Void;
}
