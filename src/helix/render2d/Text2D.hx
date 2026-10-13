package helix.render2d;

/** Which point of the text x names: its left edge, center or right edge. */
enum abstract Align2D(Int) {
	var Left;
	var Center;
	var Right;
}

/** Text in world units. size is the glyph height; x is the left edge, center or right edge by align; y is the top. */
class Text2D {
	/** The width text would take at size. */
	public static function measure(font:Font2D, text:String, size:Float):Float {
		var unit = size / font.getGlyphHeight();
		return text.length == 0 ? 0 : ((text.length - 1) * font.getAdvance() + font.getGlyphWidth()) * unit;
	}

	/** Draws text into batch with its built-in font, tinted color (0xRRGGBBAA); characters without a glyph leave a space. */
	public static function draw(batch:Batch2D, text:String, x:Float, y:Float, size:Float, color:Int, align:Align2D = Left):Void {
		var font = batch.getFont(),
			unit = size / font.getGlyphHeight(),
			w = measure(font, text, size);
		if (align == Center)
			x -= w / 2;
		else if (align == Right)
			x -= w;
		batch.useTexture(font.getTexture());
		for (i in 0...text.length) {
			var uv = font.getGlyph(text.charCodeAt(i));
			if (uv != null)
				batch.quad(x + i * font.getAdvance() * unit, y, font.getGlyphWidth() * unit, size, uv[0], uv[1], uv[2], uv[3], color);
		}
	}
}
