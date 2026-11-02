package helix.platform.adapters.fontrasterizer.stb;

import haxe.io.Bytes;
import helix.platform.IFontRasterizer;
import helix.platform.RasterGlyph;
import helix.platform.adapters.fontrasterizer.stb.internal.FontBridge;
import helix.platform.adapters.shared.Mailbox;
import sys.thread.Thread;

/** Provides `IFontRasterizer` natively over stb_truetype, each rasterize on a worker thread. */
class StbFontRasterizerAdapter implements IFontRasterizer {
	var mailbox = new Mailbox();
	var closed = false;

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
			var metrics = new Array<cpp.Float32>();
			metrics.resize(3);
			FontBridge.metrics(cast font, size, cast cpp.Pointer.arrayElem(metrics, 0).raw);
			var box = [0, 0, 0, 0, 0], advance = new Array<cpp.Float32>();
			advance.resize(1);
			var glyphs:Array<RasterGlyph> = [];
			for (codepoint in wanted) {
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
			FontBridge.close(font);
			var ascent:Float = metrics[0],
				descent:Float = metrics[1],
				lineGap:Float = metrics[2];
			mailbox.post(() -> rasterized(glyphs, ascent, descent, lineGap));
		});
	}

	public function poll():Void
		if (!closed)
			mailbox.deliver();

	/** Closes the rasterizer: a rasterize still running on its worker finishes, and its answer is dropped. */
	public function dispose():Void
		closed = true;
}
