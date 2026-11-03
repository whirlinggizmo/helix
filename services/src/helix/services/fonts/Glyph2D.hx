package helix.services.fonts;

/** Represents one of a font's glyphs: where it is on the atlas, where it sits from the pen, and how far it moves the pen. */
class Glyph2D {
	/** Gets the character. */
	public final codepoint:Int;

	/** Gets its place on the atlas: left edge, in texels. */
	public final x:Int;

	/** Gets its top edge on the atlas, in texels. */
	public final y:Int;

	/** Gets its width on the atlas, in texels; 0 for a glyph with nothing to draw, such as a space. */
	public final width:Int;

	/** Gets its height on the atlas, in texels. */
	public final height:Int;

	/** Gets its left edge from the pen, in pixels at the font's size. */
	public final offsetX:Float;

	/** Gets its top edge from the baseline, in pixels at the font's size, down positive: above the baseline it is negative. */
	public final offsetY:Float;

	/** Gets how far the pen moves after it, in pixels at the font's size. */
	public final advance:Float;

	/** Creates a glyph.

		@param codepoint  The character.
		@param x  Its left edge on the atlas, in texels.
		@param y  Its top edge on the atlas, in texels.
		@param width  Its width on the atlas, in texels; 0 for nothing to draw.
		@param height  Its height on the atlas, in texels.
		@param offsetX  Its left edge from the pen, in pixels at the font's size.
		@param offsetY  Its top edge from the baseline, in pixels at the font's size, down positive.
		@param advance  How far the pen moves after it, in pixels at the font's size. */
	public function new(codepoint:Int, x:Int, y:Int, width:Int, height:Int, offsetX:Float, offsetY:Float, advance:Float) {
		this.codepoint = codepoint;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.advance = advance;
	}
}
