import haxe.io.Bytes;
import helix.platform.IFontRasterizer;
import helix.platform.RasterFont;
import helix.platform.RasterGlyph;

/** Rasterizes "font" bytes into glyphs of known shapes, at its next poll: each codepoint a box as wide as its order (1, 2, 3...) and as
	tall as the size, its coverage 100 but its last pixel's 50, offset 1 right and the size up, advancing its width plus 1; a codepoint of
	0x4E00 isn't in it. A TrueType file's bytes rasterize so too, its glyphs not read. Any other bytes fail. A font opened answers at its
	next poll, and rasterizes during the call. */
class FakeFontRasterizer implements IFontRasterizer {
	final pending:Array<Void->Void> = [];

	/** Whether the last rasterize asked for signed distances. */
	public var sdf(default, null) = false;

	/** The fonts open, by id. */
	public final openFonts:Array<Int> = [];

	var nextFont = 1;

	/** Creates it. */
	public function new() {}

	public function rasterize(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void
		run(encoded, size, codepoints, false, rasterized, failed);

	public function rasterizeDistanceField(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void
		run(encoded, size, codepoints, true, rasterized, failed);

	function run(encoded:Bytes, size:Float, codepoints:Array<Int>, sdf:Bool,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void {
		this.sdf = sdf;
		var font = isFont(encoded);
		pending.push(() -> if (!font) failed("not a font") else {
			var done = glyphs(size, codepoints);
			rasterized(done.glyphs, done.ascent, done.descent, done.lineGap);
		});
	}

	public function openFont(encoded:Bytes, opened:(font:Int) -> Void, failed:String->Void):Void {
		var font = isFont(encoded), id = nextFont++;
		pending.push(() -> if (!font) failed("not a font") else {
			openFonts.push(id);
			opened(id);
		});
	}

	public function rasterizeOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont {
		sdf = false;
		return glyphs(size, codepoints);
	}

	public function rasterizeDistanceFieldOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont {
		sdf = true;
		return glyphs(size, codepoints);
	}

	public function closeFont(font:Int):Void
		openFonts.remove(font);

	static function isFont(encoded:Bytes):Bool
		return encoded.length == 4 && encoded.toString() == "font" || encoded.length > 4 && encoded.get(1) == 1 && encoded.get(0) == 0;

	static function glyphs(size:Float, codepoints:Array<Int>):RasterFont {
		var glyphs:Array<RasterGlyph> = [];
		for (i in 0...codepoints.length) {
			var found = codepoints[i] != 0x4E00,
				w = found ? i + 1 : 0,
				h = found ? Std.int(size) : 0;
			var pixels = Bytes.alloc(w * h);
			pixels.fill(0, pixels.length, 100);
			if (pixels.length > 0)
				pixels.set(pixels.length - 1, 50);
			glyphs.push({
				codepoint: codepoints[i],
				found: found,
				width: w,
				height: h,
				offsetX: found ? 1 : 0,
				offsetY: found ? -Std.int(size) : 0,
				advance: found ? w + 1 : 0,
				pixels: pixels
			});
		}
		return {
			glyphs: glyphs,
			ascent: size * .75,
			descent: -size * .25,
			lineGap: 0
		};
	}

	/** Delivers what was rasterized. */
	public function poll():Void {
		var now = pending.copy();
		pending.resize(0);
		for (f in now)
			f();
	}

	/** Does nothing. */
	public function dispose():Void {}
}
