package helix.platform.adapters.fontrasterizer.canvas;

import haxe.io.Bytes;
import helix.math.DistanceField2D;
import helix.platform.IFontRasterizer;
import helix.platform.RasterGlyph;
import helix.platform.adapters.fontrasterizer.canvas.internal.FontTables;

/** Provides `IFontRasterizer` in a page: the font loaded as a `FontFace` and its glyphs drawn with `fillText` on an `OffscreenCanvas`.

	What stb_truetype reads from the font's tables is read here the same way (`FontTables`): the metrics, which glyphs it has, the
	advances, and a TrueType glyph's box, so glyphs are placed and sized as natively. The pixels are the browser's: coverage may differ by
	a level or so at a glyph's edges, and an OpenType glyph with CFF outlines is boxed by what the canvas measures. Signed distances come
	from the glyph drawn 8 times larger, by a distance transform, within about a sixteenth of a pixel of stb_truetype's. */
class CanvasFontRasterizerAdapter implements IFontRasterizer {
	static inline final SDF_PADDING = 4;
	static inline final SDF_EDGE = 128;
	static inline final SDF_SCALE = 64.;
	static inline final OVERSAMPLE = 8;

	static var faces = 0;

	var closed = false;

	/** Creates the rasterizer. */
	public function new() {}

	public function rasterize(encoded:Bytes, size:Float, codepoints:Array<Int>, sdf:Bool,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void {
		var tables = try new FontTables(encoded) catch (e:String) {
			js.Browser.window.setTimeout(() -> if (!closed) failed('Font rasterize failed: $e'), 0);
			return;
		}
		var wanted = codepoints.copy();
		var family = 'helix-font-${faces++}';
		var face:Dynamic = js.Syntax.code("new FontFace({0}, {1})", family, encoded.getData());
		var fonts:Dynamic = js.Syntax.code("document.fonts");
		face.load().then(_ -> {
			fonts.add(face);
			var glyphs = [for (codepoint in wanted) glyph(tables, family, size, codepoint, sdf)];
			fonts.delete(face);
			var scale = tables.scaleFor(size);
			if (!closed)
				rasterized(glyphs, tables.ascent * scale, tables.descent * scale, tables.lineGap * scale);
		},
			(error:Dynamic) -> if (!closed) failed("Font rasterize failed: " + Std.string(error)));
	}

	function glyph(tables:FontTables, family:String, size:Float, codepoint:Int, sdf:Bool):RasterGlyph {
		var index = tables.glyphIndex(codepoint);
		if (index == 0)
			return empty(codepoint, false, 0, 0, 0);
		var scale = tables.scaleFor(size),
			advance = tables.advance(index) * scale,
			text = String.fromCharCode(codepoint);
		var context = canvas(1, 1);
		context.font = '${tables.unitsPerEm * scale}px "$family"';
		// stb_truetype's box: the outline's, scaled, out to whole pixels, y down.
		var x0:Int, y0:Int, x1:Int, y1:Int;
		if (tables.hasGlyf) {
			var box = tables.box(index);
			if (box == null)
				return empty(codepoint, true, 0, 0, advance);
			x0 = Math.floor(box[0] * scale);
			y0 = Math.floor(-box[3] * scale);
			x1 = Math.ceil(box[2] * scale);
			y1 = Math.ceil(-box[1] * scale);
		} else {
			var measured:Dynamic = context.measureText(text);
			x0 = Math.floor(-measured.actualBoundingBoxLeft);
			y0 = Math.floor(-measured.actualBoundingBoxAscent);
			x1 = Math.ceil(measured.actualBoundingBoxRight);
			y1 = Math.ceil(measured.actualBoundingBoxDescent);
		}
		if (x1 <= x0 || y1 <= y0)
			return empty(codepoint, true, x0, y0, advance);
		if (!sdf) {
			var width = x1 - x0, height = y1 - y0;
			return {
				codepoint: codepoint,
				found: true,
				width: width,
				height: height,
				offsetX: x0,
				offsetY: y0,
				advance: advance,
				pixels: coverage(family, tables.unitsPerEm * scale, text, -x0, -y0, width, height)
			};
		}
		x0 -= SDF_PADDING;
		y0 -= SDF_PADDING;
		x1 += SDF_PADDING;
		y1 += SDF_PADDING;
		var width = x1 - x0, height = y1 - y0;
		return {
			codepoint: codepoint,
			found: true,
			width: width,
			height: height,
			offsetX: x0,
			offsetY: y0,
			advance: advance,
			pixels: distances(family, tables.unitsPerEm * scale, text, -x0, -y0, width, height)
		};
	}

	static function empty(codepoint:Int, found:Bool, x:Int, y:Int, advance:Float):RasterGlyph
		return {
			codepoint: codepoint,
			found: found,
			width: 0,
			height: 0,
			offsetX: x,
			offsetY: y,
			advance: advance,
			pixels: Bytes.alloc(0)
		};

	// The glyph drawn with its pen at (x, y) on a width by height canvas, its alpha as coverage.
	static function coverage(family:String, em:Float, text:String, x:Float, y:Float, width:Int, height:Int):Bytes {
		var alpha = draw(family, em, text, x, y, width, height);
		var pixels = Bytes.alloc(width * height);
		for (i in 0...pixels.length)
			pixels.set(i, alpha[i * 4 + 3]);
		return pixels;
	}

	// Signed distances, as stb_truetype's: drawn OVERSAMPLE times larger, split inside from outside at half coverage, and each pixel's
	// center measured to the nearest pixel across the edge (less half a pixel, the edge lying between them).
	static function distances(family:String, em:Float, text:String, x:Float, y:Float, width:Int, height:Int):Bytes {
		var k = OVERSAMPLE, w = width * k, h = height * k;
		var alpha = draw(family, em * k, text, x * k, y * k, w, h);
		var toOutside = [for (i in 0...w * h) alpha[i * 4 + 3] >= 128 ? 1e20 : 0.],
			toInside = [for (i in 0...w * h) alpha[i * 4 + 3] >= 128 ? 0. : 1e20];
		DistanceField2D.transform(toOutside, w, h);
		DistanceField2D.transform(toInside, w, h);
		var pixels = Bytes.alloc(width * height);
		for (py in 0...height)
			for (px in 0...width) {
				var i = Std.int((py + .5) * k) * w + Std.int((px + .5) * k);
				var distance = toOutside[i] > 0 ? (Math.sqrt(toOutside[i]) - .5) / k : -(Math.sqrt(toInside[i]) - .5) / k;
				var value = SDF_EDGE + SDF_SCALE * distance;
				pixels.set(py * width + px, value < 0 ? 0 : value > 255 ? 255 : Std.int(value));
			}
		return pixels;
	}

	static var shared:Dynamic = null;

	static function canvas(width:Int, height:Int):Dynamic {
		if (shared == null)
			shared = js.Syntax.code("new OffscreenCanvas(1, 1)");
		shared.width = width;
		shared.height = height;
		return shared.getContext("2d", {willReadFrequently: true});
	}

	static function draw(family:String, em:Float, text:String, x:Float, y:Float, width:Int, height:Int):js.lib.Uint8ClampedArray {
		var context = canvas(width, height);
		context.clearRect(0, 0, width, height);
		context.font = '${em}px "$family"';
		context.textBaseline = "alphabetic";
		context.textAlign = "left";
		context.fillStyle = "#000";
		context.fillText(text, x, y);
		return context.getImageData(0, 0, width, height).data;
	}

	/** Does nothing: the page's promises already resolve on the main thread. */
	public function poll():Void {}

	public function dispose():Void
		closed = true;
}
