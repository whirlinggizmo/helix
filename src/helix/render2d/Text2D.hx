package helix.render2d;

/** Which point of the text x names: its left edge, center or right edge. */
enum abstract Align2D(Int) {
	var Left;
	var Center;
	var Right;
}

/** One line of text in world units: size is the font's height, ascent to descent; x is the left edge, center or right edge by align; y is the top. */
class Text2D {
	/** How far text moves the pen at size: its width, by its glyphs' advances. Characters without a glyph count as nothing. */
	public static function measure(font:Font2D, text:String, size:Float):Float {
		var unit = size / font.getSize(), width = 0.;
		for (i in 0...text.length) {
			var glyph = font.getGlyph(text.charCodeAt(i));
			if (glyph != null)
				width += glyph.advance * unit;
		}
		return width;
	}

	/** Draws text into batch, tinted color (0xRRGGBBAA), in font or the batch's built-in font. Characters without a glyph are skipped. */
	public static function draw(batch:Batch2D, text:String, x:Float, y:Float, size:Float, color:Int, align:Align2D = Left, ?font:Font2D):Void {
		if (font == null)
			font = batch.getFont();
		var unit = size / font.getSize();
		if (align == Center)
			x -= measure(font, text, size) / 2;
		else if (align == Right)
			x -= measure(font, text, size);
		var baseline = y + font.getAscent() * unit,
			field = font.isDistanceField();
		batch.useTexture(font.getTexture());
		for (i in 0...text.length) {
			var glyph = font.getGlyph(text.charCodeAt(i));
			if (glyph == null)
				continue;
			if (glyph.width > 0)
				batch.quad(x + glyph.x * unit, baseline + glyph.y * unit, glyph.width * unit, glyph.height * unit, glyph.u0, glyph.v0, glyph.u1, glyph.v1,
					color, field);
			x += glyph.advance * unit;
		}
	}
}
