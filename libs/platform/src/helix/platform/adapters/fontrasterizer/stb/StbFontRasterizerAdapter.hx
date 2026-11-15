package helix.platform.adapters.fontrasterizer.stb;

import haxe.io.Bytes;
import helix.platform.IFontRasterizer;
import helix.platform.RasterFont;
import helix.platform.RasterGlyph;
import helix.platform.adapters.fontrasterizer.stb.internal.FontBridge;
import helix.platform.adapters.shared.Mailbox;
import sys.thread.Thread;

/** A font `openFont` opened: stb_truetype's, as the bridge opened it. */
@:allow(helix.platform.adapters.fontrasterizer.stb.StbFontRasterizerAdapter)
@:unreflective
private class OpenFont {
	// Set once it's made: hxcpp makes a class from Dynamic arguments, which can't hold a raw pointer.
	var font:cpp.RawPointer<cpp.Void> = null;

	function new() {}
}

/** Provides `IFontRasterizer` natively over stb_truetype, each rasterize on a worker thread. */
class StbFontRasterizerAdapter implements IFontRasterizer {
	var mailbox = new Mailbox();
	var closed = false;
	final fonts = new Map<Int, OpenFont>();
	var nextFont = 1;

	/** Creates the rasterizer. */
	public function new() {}

	public function rasterize(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void
		run(encoded, size, codepoints, false, rasterized, failed);

	public function rasterizeDistanceField(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void
		run(encoded, size, codepoints, true, rasterized, failed);

	// Rasterizes on a worker thread, as coverage or signed distances, and answers at a poll.
	function run(encoded:Bytes, size:Float, codepoints:Array<Int>, sdf:Bool,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void {
		var wanted = codepoints.copy();
		Thread.create(() -> {
			var font = FontBridge.open(cast cpp.Pointer.arrayElem(encoded.getData(), 0).raw, encoded.length);
			if (font == null) {
				mailbox.post(() -> failed("Font rasterize failed: not a TrueType or OpenType font"));
				return;
			}
			var done = glyphs(font, size, wanted, sdf);
			FontBridge.close(font);
			mailbox.post(() -> rasterized(done.glyphs, done.ascent, done.descent, done.lineGap));
		});
	}

	public function openFont(encoded:Bytes, opened:(font:Int) -> Void, failed:String->Void):Void {
		var font = FontBridge.open(cast cpp.Pointer.arrayElem(encoded.getData(), 0).raw, encoded.length);
		if (font == null) {
			mailbox.post(() -> failed("Font open failed: not a TrueType or OpenType font"));
			return;
		}
		var id = nextFont++;
		var open = new OpenFont();
		open.font = font;
		fonts.set(id, open);
		mailbox.post(() -> opened(id));
	}

	public function rasterizeOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont
		return glyphs(fonts.get(font).font, size, codepoints, false);

	public function rasterizeDistanceFieldOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont
		return glyphs(fonts.get(font).font, size, codepoints, true);

	public function closeFont(font:Int):Void {
		var opened = fonts.get(font);
		if (opened == null)
			return;
		fonts.remove(font);
		FontBridge.close(opened.font);
	}

	// Each glyph of an open font, as coverage or signed distances, with the font's metrics at the size.
	static function glyphs(font:cpp.RawPointer<cpp.Void>, size:Float, codepoints:Array<Int>, sdf:Bool):RasterFont {
		var metrics = new Array<cpp.Float32>();
		metrics.resize(3);
		FontBridge.metrics(cast font, size, cast cpp.Pointer.arrayElem(metrics, 0).raw);
		var box = [0, 0, 0, 0, 0], advance = new Array<cpp.Float32>();
		advance.resize(1);
		var glyphs:Array<RasterGlyph> = [];
		for (codepoint in codepoints) {
			var bitmap = FontBridge.glyph(cast font, size, codepoint, sdf ? 1 : 0, cast cpp.Pointer.arrayElem(box, 0).raw,
				cast cpp.Pointer.arrayElem(advance, 0).raw);
			var pixels = Bytes.alloc(box[1] * box[2]);
			if (bitmap != null) {
				FontBridge.copy(cast bitmap, pixels.length, cast cpp.Pointer.arrayElem(pixels.getData(), 0).raw);
				FontBridge.freeBitmap(bitmap, sdf ? 1 : 0);
			}
			glyphs.push({
				codepoint: codepoint,
				found: box[0] == 1,
				width: box[1],
				height: box[2],
				offsetX: box[3],
				offsetY: box[4],
				advance: advance[0],
				pixels: pixels
			});
		}
		return {
			glyphs: glyphs,
			ascent: metrics[0],
			descent: metrics[1],
			lineGap: metrics[2]
		};
	}

	public function poll():Void
		if (!closed)
			mailbox.deliver();

	/** Closes the rasterizer and every font it opened: a rasterize still running on its worker finishes, and its answer is dropped. */
	public function dispose():Void {
		closed = true;
		for (font in [for (id in fonts.keys()) id])
			closeFont(font);
	}
}
