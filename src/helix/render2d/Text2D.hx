package helix.render2d;

/** Which point of the text x names: its left edge, center or right edge. */
enum abstract Align2D(Int) {
	var Left;
	var Center;
	var Right;
}

/** One line of text in world units: size is the font's height, ascent to descent; x is the left edge, center or right edge by align; y is the top. */
class Text2D {
	/** How far text moves the pen at size: its width, by its glyphs' advances and the kerning between them. Characters without a glyph count as
		nothing. */
	public static function measure(font:Font2D, text:String, size:Float):Float {
		var unit = size / font.size, width = 0.;
		for (i in 0...text.length) {
			var code = text.charCodeAt(i), glyph = font.getGlyph(code);
			if (glyph != null)
				width += glyph.advance * unit;
			if (i + 1 < text.length)
				width += font.getKerning(code, text.charCodeAt(i + 1)) * unit;
		}
		return width;
	}

	/** text broken into lines no wider than width in world units at size: at spaces, and a word wider than a line within it, between its
		letters; a line break ("\n") always breaks. Lines keep no trailing spaces. */
	public static function wrap(font:Font2D, text:String, size:Float, width:Float):Array<String> {
		var lines = [];
		for (paragraph in text.split("\n")) {
			var line = "";
			for (word in paragraph.split(" ")) {
				var tried = line == "" ? word : line + " " + word;
				if (measure(font, tried, size) <= width) {
					line = tried;
					continue;
				}
				if (line != "")
					lines.push(line);
				// A word wider than a line: as many of its letters as fit, line after line.
				line = word;
				while (line.length > 1 && measure(font, line, size) > width) {
					var fit = 1;
					while (fit < line.length && measure(font, line.substr(0, fit + 1), size) <= width)
						fit++;
					lines.push(line.substr(0, fit));
					line = line.substr(fit);
				}
			}
			lines.push(line);
		}
		return lines;
	}

	/** The height text takes wrapped to width at size (wrap), its lines lineHeight times size apart: what drawWrapped returns, known before
		drawing, for what's laid out under it (a button below a title that may wrap). */
	public static function measureWrapped(font:Font2D, text:String, size:Float, width:Float, lineHeight = 1.25):Float
		return wrap(font, text, size, width).length * size * lineHeight;

	/** Draws text wrapped to width (wrap), its lines lineHeight times size apart, the first's top at y, each placed by align at x. Returns the
		height its lines take, so what follows can go under them (a HUD's lines on a narrow screen). */
	public static function drawWrapped(batch:Batch2D, text:String, x:Float, y:Float, size:Float, width:Float, color:Int, align:Align2D = Left,
			lineHeight = 1.25, ?font:Font2D):Float {
		var f = font == null ? batch.font : font, row = 0;
		for (line in wrap(f, text, size, width))
			draw(batch, line, x, y + size * lineHeight * row++, size, color, align, font);
		return size * lineHeight * row;
	}

	/** Draws text into batch, tinted color (0xRRGGBBAA), in font or the batch's built-in font. Characters without a glyph are skipped. */
	public static function draw(batch:Batch2D, text:String, x:Float, y:Float, size:Float, color:Int, align:Align2D = Left, ?font:Font2D):Void {
		if (font == null)
			font = batch.font;
		var unit = size / font.size;
		if (align == Center)
			x -= measure(font, text, size) / 2;
		else if (align == Right)
			x -= measure(font, text, size);
		var baseline = y + font.ascent * unit, field = font.distanceField;
		batch.useTexture(font.texture);
		for (i in 0...text.length) {
			var code = text.charCodeAt(i), glyph = font.getGlyph(code);
			if (glyph != null) {
				if (glyph.width > 0)
					batch.quad(x + glyph.x * unit, baseline + glyph.y * unit, glyph.width * unit, glyph.height * unit, glyph.u0, glyph.v0, glyph.u1, glyph.v1,
						color, field);
				x += glyph.advance * unit;
			}
			if (i + 1 < text.length)
				x += font.getKerning(code, text.charCodeAt(i + 1)) * unit;
		}
	}
}
