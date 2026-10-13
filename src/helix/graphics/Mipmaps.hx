package helix.graphics;

import haxe.io.Bytes;

/** Mipmap chains for IGraphics.createTexture, built the same on every target so their images match. */
class Mipmaps {
	/** rgba (width x height RGBA8) and each level below it, half the size of the last (at least 1), down to 1x1: each texel the rounded average of
		the 2x2 above it, an odd edge repeating its last row or column. */
	public static function build(width:Int, height:Int, rgba:Bytes):Array<Bytes> {
		var levels = [rgba], sw = width, sh = height;
		while (sw > 1 || sh > 1) {
			var src = levels[levels.length - 1],
				lw = sw > 1 ? Std.int(sw / 2) : 1,
				lh = sh > 1 ? Std.int(sh / 2) : 1,
				dst = Bytes.alloc(lw * lh * 4);
			for (y in 0...lh) {
				var y0 = y * 2 < sh ? y * 2 : sh - 1,
					y1 = y * 2 + 1 < sh ? y * 2 + 1 : sh - 1;
				for (x in 0...lw) {
					var x0 = x * 2 < sw ? x * 2 : sw - 1,
						x1 = x * 2 + 1 < sw ? x * 2 + 1 : sw - 1;
					for (c in 0...4) {
						var sum = src.get((y0 * sw + x0) * 4 + c) + src.get((y0 * sw + x1) * 4 + c) + src.get((y1 * sw + x0) * 4 + c)
							+ src.get((y1 * sw + x1) * 4 + c);
						dst.set((y * lw + x) * 4 + c, Std.int((sum + 2) / 4));
					}
				}
			}
			levels.push(dst);
			sw = lw;
			sh = lh;
		}
		return levels;
	}
}
