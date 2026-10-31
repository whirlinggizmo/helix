package helix.platform;

import haxe.io.Bytes;

/** Represents one glyph from `IFontRasterizer.rasterize`: its bitmap, where it sits, and how far it moves the pen. */
typedef RasterGlyph = {
	/** The codepoint asked for. */
	final codepoint:Int;

	/** Whether the font has a glyph for it. When it doesn't, the bitmap is empty and the advance 0. */
	final found:Bool;

	/** The bitmap's width, in pixels; 0 for a glyph with no outline, such as a space. */
	final width:Int;

	/** The bitmap's height, in pixels. */
	final height:Int;

	/** The bitmap's left edge from the pen, in pixels. */
	final offsetX:Int;

	/** The bitmap's top edge from the baseline, in pixels, down positive: above the baseline it is negative. */
	final offsetY:Int;

	/** How far the pen moves after the glyph, in pixels. */
	final advance:Float;

	/** The bitmap, `width * height` bytes, rows top to bottom: coverage, 0 to 255, or signed distances. */
	final pixels:Bytes;
}
