package helix.ray.internal;

import haxe.io.Bytes;

/** Makes a texture's mipmaps on the CPU as GL's `glGenerateMipmap` makes them on the GPU, which raylib's `GenTextureMipmaps` calls: each
	level half the last, each texel the rounded average of the 2 by 2 above it, channel by channel (not weighted by alpha, as services'
	`Image.getMipmaps` is). The platform makes no mipmaps on the GPU, so helix-ray makes them here, the same on every target. */
@:noCompletion
class Mipmaps {
	/** Returns the levels after an RGBA8 image, each half the size of the last, rounded down and at least 1, down to 1 by 1: each texel the
		rounded average of the 2 by 2 above it, an edge of 1 repeating its one row or column.

		@param width  The image's width.
		@param height  The image's height.
		@param rgba  Its pixels, 8-bit RGBA, rows top first.
		@return  The levels' pixels, largest first; none for an image 1 by 1. */
	public static function build(width:Int, height:Int, rgba:Bytes):Array<Bytes> {
		var levels = [], src = rgba, sw = width, sh = height;
		while (sw > 1 || sh > 1) {
			var lw = sw > 1 ? sw >> 1 : 1,
				lh = sh > 1 ? sh >> 1 : 1,
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
						dst.set((y * lw + x) * 4 + c, (sum + 2) >> 2);
					}
				}
			}
			levels.push(dst);
			src = dst;
			sw = lw;
			sh = lh;
		}
		return levels;
	}
}
