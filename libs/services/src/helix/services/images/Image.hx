package helix.services.images;

import haxe.ds.Vector;
import haxe.io.Bytes;
import helix.math.Bounds2D;
import helix.math.Random;
import helix.services.fonts.Font2D;
import helix.services.fonts.Glyph2D;

/** Represents an image in memory: its size and its pixels, 8-bit RGBA.

	An image is made here, loaded by `Images.load`, or decoded by `Images.decode`; then changed, drawn into and copied, and made a texture.
	What changes the size (cropping, resizing, rotating) returns a new image; everything else changes the pixels in place and returns the
	image, so calls chain (`image.grayscale().contrast(20)`). Positions are in pixels from the top-left, and what falls outside the image
	is skipped. Colors are 0xAARRGGBB, as `helix.math.Color` reads them.

	The operations are raylib's, in its arithmetic: each gives the pixels raylib's function of the same name gives an R8G8B8A8 image,
	byte for byte, on every target. They are raylib 5.5's, but for the lines and the filled circle (`drawLine`, `drawThickLine`,
	`drawCircle`), which are 6.2's, as it fixed them. Shapes overwrite the pixels they cover, as raylib's do; images and text blend over
	them.

	```haxe
	var badge = Image.filled(64, 64, 0);
	badge.drawCircle(32, 32, 30, 0xffe03030);
	badge.drawText(font, "7", 24, 16, 32, 0, 0xffffffff);
	var small = badge.resize(32, 32, Bilinear);
	```

	Natively the generated C++ is compiled with `-fwrapv` on GCC and clang, as Haxe's Int wraps on overflow and C++'s int doesn't. */
@:buildXml("<files id='haxe'><compilerflag value='-fwrapv' unless='windows'/></files>")
class Image {
	/** Gets the path it was loaded from, or "" for one made or decoded from bytes. */
	public final path:String;

	/** Gets the width, in pixels. */
	public final width:Int;

	/** Gets the height, in pixels. */
	public final height:Int;

	/** Gets the pixels: 8-bit red, green, blue and alpha, `width * height * 4` bytes, rows top first, alpha not premultiplied. */
	public final pixels:Bytes;

	/** Creates an image over its pixels, which it keeps rather than copies.

		@param path  The path it was loaded from, or "".
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param pixels  The pixels: `width * height * 4` bytes of red, green, blue and alpha, rows top first. */
	public function new(path:String, width:Int, height:Int, pixels:Bytes) {
		this.path = path;
		this.width = width;
		this.height = height;
		this.pixels = pixels;
	}

	// ---- Made ----

	/** Returns an image of one color.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param color  The color, as 0xAARRGGBB.
		@return  The image. */
	public static function filled(width:Int, height:Int, color:Int):Image {
		var image = blank(width, height);
		image.fill(color);
		return image;
	}

	/** Returns a gradient from one color to another along a direction.

		The colors are at the image's two farthest edges along the direction, and blend across the middle.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param radians  The direction, in radians clockwise: 0 left to right, π/2 top to bottom.
		@param start  The color it starts from, as 0xAARRGGBB.
		@param end  The color it ends at.
		@return  The image. */
	public static function gradientLinear(width:Int, height:Int, radians:Float, start:Int, end:Int):Image {
		var image = blank(width, height), p = image.pixels;
		// raylib's direction counts from vertical, in degrees; this is its (90 - direction) / 180 * 3.14159, the same angle.
		radians = f32(radians);
		var cosDir = f32(Math.cos(radians)), sinDir = f32(Math.sin(radians));
		var startingPos = f32(f32(0.5 - f32(f32(cosDir * width) / 2)) - f32(f32(sinDir * height) / 2));
		var maxPosValue = signbit(sinDir) == signbit(cosDir) ? Math.abs(startingPos) : Math.abs(f32(startingPos + f32(width * cosDir)));
		var sr = red(start),
			sg = green(start),
			sb = blue(start),
			sa = alpha(start);
		var er = red(end), eg = green(end), eb = blue(end), ea = alpha(end);
		for (i in 0...width)
			for (j in 0...height) {
				var factor = f32(f32(startingPos + f32(f32(i * cosDir) + f32(j * sinDir))) / maxPosValue);
				factor = factor > 1 ? 1 : factor;
				factor = factor < -1 ? -1 : factor;
				factor = f32(f32(factor / 2) + 0.5);
				var rest = f32(1 - factor), at = (j * width + i) * 4;
				p.set(at, byte(f32(f32(er * factor) + f32(sr * rest))));
				p.set(at + 1, byte(f32(f32(eg * factor) + f32(sg * rest))));
				p.set(at + 2, byte(f32(f32(eb * factor) + f32(sb * rest))));
				p.set(at + 3, byte(f32(f32(ea * factor) + f32(sa * rest))));
			}
		return image;
	}

	/** Returns a gradient out from the middle, round.

		The inner color holds out to `density` of the way to the nearer edge, then blends to the outer color at the edge; past it, the outer
		color holds.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param density  How far the inner color holds, 0 (the middle alone) to 1 (out to the edge).
		@param inner  The color in the middle, as 0xAARRGGBB.
		@param outer  The color at the edge and beyond.
		@return  The image. */
	public static function gradientRadial(width:Int, height:Int, density:Float, inner:Int, outer:Int):Image {
		var image = blank(width, height), p = image.pixels;
		density = f32(density);
		var radius = f32((width < height ? width : height) / 2),
			centerX = f32(width / 2),
			centerY = f32(height / 2);
		var held = f32(radius * density),
			span = f32(radius * f32(1 - density));
		for (y in 0...height)
			for (x in 0...width) {
				var dx = f32(x - centerX), dy = f32(y - centerY);
				// hypotf, which glibc computes in double.
				var dist = f32(Math.sqrt(dx * dx + dy * dy));
				var factor = f32(f32(dist - held) / span);
				factor = factor > 0 ? factor : 0;
				factor = factor < 1 ? factor : 1;
				mix(p, (y * width + x) * 4, inner, outer, factor);
			}
		return image;
	}

	/** Returns a gradient out from the middle to the edges, square.

		The inner color holds out to `density` of the way to the edges, then blends to the outer color at them.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param density  How far the inner color holds, 0 (the middle alone) to 1 (out to the edges).
		@param inner  The color in the middle, as 0xAARRGGBB.
		@param outer  The color at the edges.
		@return  The image. */
	public static function gradientSquare(width:Int, height:Int, density:Float, inner:Int, outer:Int):Image {
		var image = blank(width, height), p = image.pixels;
		density = f32(density);
		var centerX = f32(width / 2),
			centerY = f32(height / 2),
			span = f32(1 - density);
		for (y in 0...height)
			for (x in 0...width) {
				var nx = f32(Math.abs(f32(x - centerX)) / centerX),
					ny = f32(Math.abs(f32(y - centerY)) / centerY);
				var factor = f32(f32((nx > ny ? nx : ny) - density) / span);
				factor = factor > 0 ? factor : 0;
				factor = factor < 1 ? factor : 1;
				mix(p, (y * width + x) * 4, inner, outer, factor);
			}
		return image;
	}

	/** Returns a checkerboard of two colors.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param squareWidth  The width of each square, in pixels; clamped to 1 or more.
		@param squareHeight  The height of each square, in pixels; clamped to 1 or more.
		@param first  The color of the top-left square, as 0xAARRGGBB.
		@param second  The color of the squares beside it.
		@return  The image. */
	public static function checked(width:Int, height:Int, squareWidth:Int, squareHeight:Int, first:Int, second:Int):Image {
		var image = blank(width, height), p = image.pixels;
		if (squareWidth < 1)
			squareWidth = 1;
		if (squareHeight < 1)
			squareHeight = 1;
		for (y in 0...height)
			for (x in 0...width)
				put(p, (y * width + x) * 4, (Std.int(x / squareWidth) + Std.int(y / squareHeight)) % 2 == 0 ? first : second);
		return image;
	}

	/** Returns white noise: each pixel white or black, opaque.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param factor  The chance of white, 0 to 1, in hundredths: the rest of it is dropped.
		@param random  The generator the pixels are drawn from, one number a pixel, rows top first.
		@return  The image. */
	public static function whiteNoise(width:Int, height:Int, factor:Float, random:Random):Image {
		var image = blank(width, height), p = image.pixels;
		var limit = Std.int(f32(f32(factor) * 100));
		for (i in 0...width * height)
			put(p, i * 4, random.nextInt(100) < limit ? 0xffffffff : 0xff000000);
		return image;
	}

	/** Returns Perlin noise in gray, opaque: fractal Brownian motion over 6 octaves of stb_perlin's noise.

		The same arguments give the same image on every target. The longer side is scaled to keep the noise square.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param offsetX  How far it is moved left, in pixels: images side by side at their widths join up.
		@param offsetY  How far it is moved up, in pixels.
		@param scale  How much of the noise it shows across the image: larger is finer.
		@return  The image. */
	public static function perlinNoise(width:Int, height:Int, offsetX:Int, offsetY:Int, scale:Float):Image {
		var image = blank(width, height), p = image.pixels;
		scale = f32(scale);
		var aspectRatio = f32(width / height),
			stepX = f32(scale / width),
			stepY = f32(scale / height);
		for (y in 0...height)
			for (x in 0...width) {
				var nx = f32((x + offsetX) * stepX),
					ny = f32((y + offsetY) * stepY);
				if (width > height)
					nx = f32(nx * aspectRatio);
				else
					ny = f32(ny / aspectRatio);
				var n = fbm(nx, ny, 1);
				n = n < -1 ? -1 : n > 1 ? 1 : n;
				var intensity = Std.int(f32(f32(f32(n + 1) / 2) * 255));
				put(p, (y * width + x) * 4, 0xff000000 | intensity << 16 | intensity << 8 | intensity);
			}
		return image;
	}

	/** Returns cellular (Worley) noise in gray, opaque: each pixel's distance to the nearest of points scattered one to a tile.

		A tile left over at the right or bottom edge has no point of its own.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param tileSize  The size of the square tiles, in pixels; clamped to 1 or more. Bigger is bigger cells.
		@param random  The generator the points are drawn from, two numbers a tile (its y, then its x), rows top first.
		@return  The image. */
	public static function cellular(width:Int, height:Int, tileSize:Int, random:Random):Image {
		var image = blank(width, height), p = image.pixels;
		if (tileSize < 1)
			tileSize = 1;
		var seedsPerRow = Std.int(width / tileSize),
			seedsPerCol = Std.int(height / tileSize),
			seedCount = seedsPerRow * seedsPerCol;
		var seedX = new Vector<Int>(seedCount),
			seedY = new Vector<Int>(seedCount);
		for (i in 0...seedCount) {
			seedY[i] = Std.int(i / seedsPerRow) * tileSize + random.nextInt(tileSize);
			seedX[i] = (i % seedsPerRow) * tileSize + random.nextInt(tileSize);
		}
		for (y in 0...height) {
			var tileY = Std.int(y / tileSize);
			for (x in 0...width) {
				var tileX = Std.int(x / tileSize), minDistance = 65536.;
				for (i in -1...2) {
					if (tileX + i < 0 || tileX + i >= seedsPerRow)
						continue;
					for (j in -1...2) {
						if (tileY + j < 0 || tileY + j >= seedsPerCol)
							continue;
						var seed = (tileY + j) * seedsPerRow + tileX + i,
							dx = x - seedX[seed],
							dy = y - seedY[seed];
						var dist = f32(Math.sqrt(dx * dx + dy * dy));
						if (dist < minDistance)
							minDistance = dist;
					}
				}
				var intensity = Std.int(f32(f32(minDistance * 256) / tileSize));
				if (intensity > 255)
					intensity = 255;
				put(p, (y * width + x) * 4, 0xff000000 | intensity << 16 | intensity << 8 | intensity);
			}
		}
		return image;
	}

	/** Returns a copy, its path "".

		@return  The copy. */
	public function copy():Image {
		return new Image("", width, height, pixels.sub(0, pixels.length));
	}

	/** Returns one channel as gray, opaque.

		@param channel  The channel: 0 red, 1 green, 2 blue, 3 alpha; clamped to 0 to 3.
		@return  The image, each pixel's red, green and blue the channel's value. */
	public function getChannel(channel:Int):Image {
		channel = channel < 0 ? 0 : channel > 3 ? 3 : channel;
		var image = blank(width, height), p = image.pixels;
		for (i in 0...width * height) {
			var v = byte(f32(f32(pixels.get(i * 4 + channel) / 255) * 255));
			put(p, i * 4, 0xff000000 | v << 16 | v << 8 | v);
		}
		return image;
	}

	// ---- Resized: a new image ----

	/** Returns a rectangle of it.

		The rectangle is clamped to the image; one wholly outside it gives an image 0 by 0.
		@param x  The rectangle's left edge, in pixels.
		@param y  Its top edge.
		@param width  Its width, in pixels.
		@param height  Its height.
		@return  The image. */
	public function crop(x:Int, y:Int, width:Int, height:Int):Image {
		if (x < 0) {
			width += x;
			x = 0;
		}
		if (y < 0) {
			height += y;
			y = 0;
		}
		if (x + width > this.width)
			width = this.width - x;
		if (y + height > this.height)
			height = this.height - y;
		if (width <= 0 || height <= 0)
			return blank(0, 0);
		var image = blank(width, height);
		for (row in 0...height)
			image.pixels.blit(row * width * 4, pixels, ((y + row) * this.width + x) * 4, width * 4);
		return image;
	}

	/** Returns it scaled to a size.

		`Nearest` is raylib's `ImageResizeNN`. `Bilinear` and `Bicubic` are this library's own (raylib's `ImageResize` is stb_image_resize2):
		they sample each pixel's middle, take the edge pixels beyond the edges, and weight colors by alpha, so clear pixels don't darken
		the colors beside them.
		@param width  The width, in pixels; 0 or less gives an image 0 by 0.
		@param height  The height, in pixels; 0 or less gives an image 0 by 0.
		@param filter  How the pixels between pixels are made.
		@return  The image. */
	public function resize(width:Int, height:Int, filter:ImageFilter):Image {
		if (width <= 0 || height <= 0)
			return blank(0, 0);
		if (this.width == 0 || this.height == 0)
			return blank(width, height);
		return switch filter {
			case Nearest: resizeNearest(width, height);
			case Bilinear: resample(width, height, 2);
			case Bicubic: resample(width, height, 4);
		}
	}

	/** Returns it on a canvas of another size.

		What falls outside the canvas is cropped.
		@param width  The canvas's width, in pixels.
		@param height  The canvas's height, in pixels.
		@param offsetX  Where its left edge goes on the canvas, in pixels; negative crops its left.
		@param offsetY  Where its top edge goes.
		@param fill  The color of the canvas around it, as 0xAARRGGBB.
		@return  The image. */
	public function resizeCanvas(width:Int, height:Int, offsetX:Int, offsetY:Int, fill:Int):Image {
		if (width < 0)
			width = 0;
		if (height < 0)
			height = 0;
		var image = filled(width, height, fill);
		var srcX = 0, srcY = 0, srcWidth = this.width, srcHeight = this.height, dstX = offsetX, dstY = offsetY;
		if (offsetX < 0) {
			srcX = -offsetX;
			srcWidth += offsetX;
			dstX = 0;
		} else if (offsetX + this.width > width)
			srcWidth = width - offsetX;
		if (offsetY < 0) {
			srcY = -offsetY;
			srcHeight += offsetY;
			dstY = 0;
		} else if (offsetY + this.height > height)
			srcHeight = height - offsetY;
		if (width < srcWidth)
			srcWidth = width;
		if (height < srcHeight)
			srcHeight = height;
		if (srcWidth > 0)
			for (row in 0...srcHeight)
				image.pixels.blit(((dstY + row) * width + dstX) * 4, pixels, ((row + srcY) * this.width + srcX) * 4, srcWidth * 4);
		return image;
	}

	/** Returns it on the smallest canvas whose sides are powers of two, at the top-left.

		@param fill  The color of the canvas around it, as 0xAARRGGBB.
		@return  The image: a copy when its sides are powers of two already. */
	public function toPowerOfTwo(fill:Int):Image {
		var w = 1, h = 1;
		while (w < width)
			w <<= 1;
		while (h < height)
			h <<= 1;
		return w == width && h == height ? copy() : resizeCanvas(w, h, 0, 0, fill);
	}

	/** Returns it cropped to the pixels whose alpha is over a threshold.

		@param threshold  The threshold, 0 to 1, in 255ths: the rest of it is dropped.
		@return  The image: a copy when no pixel is over it. */
	public function cropAlpha(threshold:Float):Image {
		var border = getAlphaBorder(threshold);
		return border.isEmpty ? copy() : crop(Std.int(border.minX), Std.int(border.minY), Std.int(border.width), Std.int(border.height));
	}

	/** Returns it turned by an angle, on a canvas big enough to hold it, transparent around it.

		Each pixel blends the four it falls between, alpha not weighted.
		@param radians  The angle, in radians clockwise.
		@return  The image. */
	public function rotate(radians:Float):Image {
		radians = f32(radians);
		var sinRadius = f32(Math.sin(radians)),
			cosRadius = f32(Math.cos(radians));
		var w = Std.int(f32(Math.abs(f32(width * cosRadius)) + Math.abs(f32(height * sinRadius))));
		var h = Std.int(f32(Math.abs(f32(height * cosRadius)) + Math.abs(f32(width * sinRadius))));
		var image = blank(w, h), p = image.pixels;
		if (width == 0 || height == 0)
			return image;
		var halfW = f32(w / 2),
			halfH = f32(h / 2),
			oldHalfW = f32(width / 2),
			oldHalfH = f32(height / 2);
		for (y in 0...h) {
			var dy = f32(y - halfH);
			for (x in 0...w) {
				var dx = f32(x - halfW);
				var oldX = f32(f32(f32(dx * cosRadius) + f32(dy * sinRadius)) + oldHalfW);
				var oldY = f32(f32(f32(dy * cosRadius) - f32(dx * sinRadius)) + oldHalfH);
				if (oldX >= 0 && oldX < width && oldY >= 0 && oldY < height) {
					var x1 = Std.int(Math.floor(oldX)),
						y1 = Std.int(Math.floor(oldY));
					var x2 = x1 + 1 < width - 1 ? x1 + 1 : width - 1,
						y2 = y1 + 1 < height - 1 ? y1 + 1 : height - 1;
					var px = f32(oldX - x1),
						py = f32(oldY - y1),
						qx = f32(1 - px),
						qy = f32(1 - py);
					var a1 = (y1 * width + x1) * 4,
						a2 = (y1 * width + x2) * 4,
						a3 = (y2 * width + x1) * 4,
						a4 = (y2 * width + x2) * 4;
					var at = (y * w + x) * 4;
					for (i in 0...4) {
						var v = f32(f32(f32(f32(pixels.get(a1 + i) * qx) * qy) + f32(f32(pixels.get(a2 + i) * px) * qy))
							+ f32(f32(pixels.get(a3 + i) * qx) * py));
						v = f32(v + f32(f32(pixels.get(a4 + i) * px) * py));
						p.set(at + i, byte(v));
					}
				}
			}
		}
		return image;
	}

	/** Returns it turned a quarter turn clockwise.

		@return  The image, its width and height swapped. */
	public function rotateClockwise():Image {
		var image = blank(height, width), p = image.pixels;
		for (y in 0...height)
			for (x in 0...width)
				p.setInt32((x * height + (height - y - 1)) * 4, pixels.getInt32((y * width + x) * 4));
		return image;
	}

	/** Returns it turned a quarter turn counterclockwise.

		@return  The image, its width and height swapped. */
	public function rotateCounterclockwise():Image {
		var image = blank(height, width), p = image.pixels;
		for (y in 0...height)
			for (x in 0...width)
				p.setInt32((x * height + y) * 4, pixels.getInt32((y * width + (width - x - 1)) * 4));
		return image;
	}

	/** Returns its mipmap chain, the levels after it: each half the size of the last, rounded down, down to 1 by 1.

		Each level is the last one resized `Bilinear`, which at exactly half the size is the average of each 2 by 2 square, weighted by
		alpha. (raylib's `ImageMipmaps` resizes with stb_image_resize2.)
		@return  The levels, largest first; none for an image 1 by 1 or empty. */
	public function getMipmaps():Array<Image> {
		var levels = [], level = this, w = width, h = height;
		if (w == 0 || h == 0)
			return levels;
		while (w != 1 || h != 1) {
			w = w > 1 ? w >> 1 : 1;
			h = h > 1 ? h >> 1 : 1;
			level = level.resize(w, h, Bilinear);
			levels.push(level);
		}
		return levels;
	}

	// ---- Changed in place ----

	/** Turns it upside down.

		@return  This image. */
	public function flipVertical():Image {
		var row = Bytes.alloc(width * 4), stride = width * 4;
		for (y in 0...height >> 1) {
			var top = y * stride, bottom = (height - 1 - y) * stride;
			row.blit(0, pixels, top, stride);
			pixels.blit(top, pixels, bottom, stride);
			pixels.blit(bottom, row, 0, stride);
		}
		return this;
	}

	/** Mirrors it left to right.

		@return  This image. */
	public function flipHorizontal():Image {
		for (y in 0...height) {
			var left = y * width * 4, right = left + (width - 1) * 4;
			while (left < right) {
				var t = pixels.getInt32(left);
				pixels.setInt32(left, pixels.getInt32(right));
				pixels.setInt32(right, t);
				left += 4;
				right -= 4;
			}
		}
		return this;
	}

	/** Multiplies each pixel by a color, channel by channel, alpha included: white leaves it unchanged.

		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function tint(color:Int):Image {
		var t = [red(color), green(color), blue(color), alpha(color)];
		for (i in 0...width * height * 4)
			pixels.set(i, Std.int(pixels.get(i) * t[i & 3] / 255));
		return this;
	}

	/** Inverts each pixel's red, green and blue; alpha is unchanged.

		@return  This image. */
	public function invert():Image {
		for (i in 0...width * height)
			for (c in 0...3)
				pixels.set(i * 4 + c, 255 - pixels.get(i * 4 + c));
		return this;
	}

	/** Makes it gray, by luminance (0.299 red, 0.587 green, 0.114 blue); alpha is unchanged.

		@return  This image. */
	public function grayscale():Image {
		for (i in 0...width * height) {
			var v = luminance(pixels, i * 4);
			pixels.set(i * 4, v);
			pixels.set(i * 4 + 1, v);
			pixels.set(i * 4 + 2, v);
		}
		return this;
	}

	/** Changes its contrast: red, green and blue pushed away from mid-gray, or pulled toward it; alpha is unchanged.

		@param amount  How far, -100 (all mid-gray) to 100 (the most); 0 leaves it unchanged. Clamped to -100 to 100.
		@return  This image. */
	public function contrast(amount:Float):Image {
		amount = f32(amount);
		amount = amount < -100 ? -100 : amount > 100 ? 100 : amount;
		var c = f32(f32(100 + amount) / 100);
		c = f32(c * c);
		for (i in 0...width * height)
			for (k in 0...3) {
				var v = f32(f32(f32(f32(f32(pixels.get(i * 4 + k) / 255) - 0.5) * c) + 0.5) * 255);
				pixels.set(i * 4 + k, Std.int(v < 0 ? 0 : v > 255 ? 255 : v));
			}
		return this;
	}

	/** Changes its brightness: the same amount added to red, green and blue; alpha is unchanged.

		A channel taken below 0 becomes 1, not 0, as raylib's does; one taken over 255 becomes 255.
		@param amount  The amount, -255 to 255; clamped to that.
		@return  This image. */
	public function brighten(amount:Int):Image {
		amount = amount < -255 ? -255 : amount > 255 ? 255 : amount;
		for (i in 0...width * height)
			for (k in 0...3) {
				var v = pixels.get(i * 4 + k) + amount;
				pixels.set(i * 4 + k, v < 0 ? 1 : v > 255 ? 255 : v);
			}
		return this;
	}

	/** Changes every pixel of one color to another.

		@param from  The color changed, as 0xAARRGGBB, alpha included.
		@param to  The color it becomes.
		@return  This image. */
	public function replaceColor(from:Int, to:Int):Image {
		var f = rgba(from), t = rgba(to);
		for (i in 0...width * height)
			if (pixels.getInt32(i * 4) == f)
				pixels.setInt32(i * 4, t);
		return this;
	}

	/** Changes every pixel whose alpha is at or under a threshold to a color.

		@param color  The color, as 0xAARRGGBB.
		@param threshold  The threshold, 0 to 1, in 255ths: the rest of it is dropped.
		@return  This image. */
	public function clearAlpha(color:Int, threshold:Float):Image {
		var limit = byte(f32(f32(threshold) * 255)), c = rgba(color);
		for (i in 0...width * height)
			if (pixels.get(i * 4 + 3) <= limit)
				pixels.setInt32(i * 4, c);
		return this;
	}

	/** Takes its alpha from another image of the same size: the mask's luminance (0.299 red, 0.587 green, 0.114 blue).

		A white mask leaves it opaque, a black one clear; the mask's own alpha is ignored. A mask of another size changes nothing.
		@param mask  The mask.
		@return  This image. */
	public function maskAlpha(mask:Image):Image {
		if (mask.width != width || mask.height != height)
			return this;
		for (i in 0...width * height)
			pixels.set(i * 4 + 3, luminance(mask.pixels, i * 4));
		return this;
	}

	/** Multiplies each pixel's red, green and blue by its alpha, rounding down.

		@return  This image. */
	public function premultiplyAlpha():Image {
		for (i in 0...width * height) {
			var a = pixels.get(i * 4 + 3);
			if (a == 0)
				for (k in 0...3)
					pixels.set(i * 4 + k, 0);
			else if (a < 255) {
				var f = f32(a / 255);
				for (k in 0...3)
					pixels.set(i * 4 + k, byte(f32(pixels.get(i * 4 + k) * f)));
			}
		}
		return this;
	}

	/** Blurs it: an approximate Gaussian, four passes of a box blur across and down, over premultiplied alpha.

		@param radius  How far each box reaches either side of a pixel, in pixels; 0 or less changes nothing.
		@return  This image. */
	public function blur(radius:Int):Image {
		if (width == 0 || height == 0 || radius <= 0)
			return this;
		premultiplyAlpha();
		var count = width * height * 4,
			a = new Vector<Float>(count),
			b = new Vector<Float>(count);
		for (i in 0...count)
			a[i] = pixels.get(i);
		var sums = new Vector<Float>(4);
		for (_ in 0...4) {
			// Across, a into b: a running sum of the box, as floats.
			for (row in 0...height) {
				var base = row * width * 4,
					size = radius < width ? radius : width;
				for (k in 0...4) {
					var s = 0.;
					for (i in 0...size)
						s = f32(s + a[base + i * 4 + k]);
					sums[k] = s;
				}
				for (x in 0...width) {
					if (x - radius - 1 >= 0) {
						var at = base + (x - radius - 1) * 4;
						for (k in 0...4)
							sums[k] = f32(sums[k] - a[at + k]);
						size--;
					}
					if (x + radius < width) {
						var at = base + (x + radius) * 4;
						for (k in 0...4)
							sums[k] = f32(sums[k] + a[at + k]);
						size++;
					}
					for (k in 0...4)
						b[base + x * 4 + k] = f32(sums[k] / size);
				}
			}
			// Down, b into a, each value then cut to a byte.
			var stride = width * 4;
			for (col in 0...width) {
				var base = col * 4, size = radius < height ? radius : height;
				for (k in 0...4) {
					var s = 0.;
					for (i in 0...size)
						s = f32(s + b[base + i * stride + k]);
					sums[k] = s;
				}
				for (y in 0...height) {
					if (y - radius - 1 >= 0) {
						var at = base + (y - radius - 1) * stride;
						for (k in 0...4)
							sums[k] = f32(sums[k] - b[at + k]);
						size--;
					}
					if (y + radius < height) {
						var at = base + (y + radius) * stride;
						for (k in 0...4)
							sums[k] = f32(sums[k] + b[at + k]);
						size++;
					}
					for (k in 0...4)
						a[base + y * stride + k] = byte(f32(sums[k] / size));
				}
			}
		}
		// Back from premultiplied.
		for (i in 0...width * height) {
			var at = i * 4, w = a[at + 3];
			if (w == 0)
				pixels.setInt32(at, 0);
			else {
				var f = f32(w / 255);
				for (k in 0...3)
					pixels.set(at + k, byte(f32(a[at + k] / f)));
				pixels.set(at + 3, byte(w));
			}
		}
		return this;
	}

	/** Applies a square kernel to red, green and blue; alpha is unchanged.

		Each channel is the sum of the pixels around it times the kernel's weights, as fractions of 255, clamped to 0 to 1. A pixel past the
		left or right edge is taken from the row beside, and one past the top or bottom counts as black, as raylib's does. A kernel of even
		width reaches one pixel further up and left.
		@param kernel  The weights, rows top first: 9 for 3 by 3, 25 for 5 by 5, any square count. Another count changes nothing.
		@return  This image. */
	public function convolve(kernel:Array<Float>):Image {
		var size = kernel.length, kw = Std.int(f32(Math.sqrt(f32(size))));
		if (width == 0 || height == 0 || size == 0 || kw * kw != size)
			return this;
		var weights = new Vector<Float>(size),
			temp = new Vector<Float>(size * 3),
			out = new Vector<Float>(width * height * 3);
		for (i in 0...size)
			weights[i] = f32(kernel[i]);
		var half = Std.int(kw / 2), start = -half, end = kw % 2 == 0 ? half : half + 1, total = width * height;
		// raylib's x walks the rows and y the columns.
		for (x in 0...height)
			for (y in 0...width) {
				for (xk in start...end)
					for (yk in start...end) {
						var t = kw * (xk + half) + yk + half,
							index = width * (x + xk) + y + yk;
						if (index < 0 || index >= total)
							for (k in 0...3)
								temp[t * 3 + k] = 0;
						else
							for (k in 0...3)
								temp[t * 3 + k] = f32(f32(pixels.get(index * 4 + k) / 255) * weights[t]);
					}
				for (k in 0...3) {
					var s = 0.;
					for (i in 0...size)
						s = f32(s + temp[i * 3 + k]);
					out[(width * x + y) * 3 + k] = s < 0 ? 0 : s > 1 ? 1 : s;
				}
				for (i in 0...size * 3)
					temp[i] = 0;
			}
		for (i in 0...total)
			for (k in 0...3)
				pixels.set(i * 4 + k, byte(f32(out[i * 3 + k] * 255)));
		return this;
	}

	/** Dithers it to fewer bits a channel (Floyd-Steinberg), its pixels left 8-bit at the levels those bits hold.

		Each channel is cut to its top bits, and what was cut is spread to the pixels right and below. A level is widened back as raylib's
		`ImageFormat` widens a 16-bit format to 8 bits: 5 bits' 31 becomes 255, 4 bits' 15 becomes 254. Alpha is cut and not spread; with
		0 alpha bits it is opaque.
		@param redBits  Red's bits, 0 to 8; clamped to that. 8 keeps its levels.
		@param greenBits  Green's bits.
		@param blueBits  Blue's bits.
		@param alphaBits  Alpha's bits.
		@return  This image. */
	public function dither(redBits:Int, greenBits:Int, blueBits:Int, alphaBits:Int):Image {
		inline function clampBits(b:Int):Int
			return b < 0 ? 0 : b > 8 ? 8 : b;
		var bits = [
			clampBits(redBits),
			clampBits(greenBits),
			clampBits(blueBits),
			clampBits(alphaBits)
		];
		var levels = [for (k in 0...4) [for (v in 0...256) widen(v, bits[k], k == 3)]];
		inline function spread(at:Int, error:Int, k:Int, weight:Float)
			pixels.set(at + k, Std.int(Math.min(pixels.get(at + k) + Std.int(f32(f32(error * weight) / 16)), 255)));
		for (y in 0...height)
			for (x in 0...width) {
				var at = (y * width + x) * 4;
				for (k in 0...4) {
					var old = pixels.get(at + k),
						shift = 8 - bits[k],
						level = old >> shift;
					pixels.set(at + k, levels[k][level]);
					if (k == 3)
						continue;
					var error = old - (level << shift);
					if (x < width - 1)
						spread(at + 4, error, k, 7);
					if (x > 0 && y < height - 1)
						spread(at + (width - 1) * 4, error, k, 3);
					if (y < height - 1)
						spread(at + width * 4, error, k, 5);
					if (x < width - 1 && y < height - 1)
						spread(at + (width + 1) * 4, error, k, 1);
				}
			}
		return this;
	}

	// ---- Read ----

	/** Returns a pixel's color.

		@param x  The pixel's column, from the left.
		@param y  Its row, from the top.
		@return  The color, as 0xAARRGGBB; 0 (clear black) outside the image. */
	public function getPixel(x:Int, y:Int):Int {
		if (x < 0 || x >= width || y < 0 || y >= height)
			return 0;
		var at = (y * width + x) * 4;
		return pixels.get(at + 3) << 24 | pixels.get(at) << 16 | pixels.get(at + 1) << 8 | pixels.get(at + 2);
	}

	/** Returns its colors, each once, in the order first met, rows top first; clear pixels (alpha 0) are skipped.

		@param max  The most colors returned.
		@return  The colors, as 0xAARRGGBB. */
	public function getPalette(max:Int):Array<Int> {
		var palette:Array<Int> = [], seen = new Map<Int, Bool>();
		for (i in 0...width * height) {
			if (palette.length >= max)
				break;
			if (pixels.get(i * 4 + 3) == 0)
				continue;
			var c = getPixel(i % width, Std.int(i / width));
			if (!seen.exists(c)) {
				seen.set(c, true);
				palette.push(c);
			}
		}
		return palette;
	}

	/** Returns the smallest rectangle holding every pixel whose alpha is over a threshold.

		@param threshold  The threshold, 0 to 1, in 255ths: the rest of it is dropped.
		@param out  Optional. The bounds to set and return; new ones when omitted.
		@return  The bounds, in pixels, from the first pixel's top-left to past the last's bottom-right; empty when no pixel is over it. */
	public function getAlphaBorder(threshold:Float, ?out:Bounds2D):Bounds2D {
		if (out == null)
			out = new Bounds2D();
		var limit = byte(f32(f32(threshold) * 255)), xMin = 65536, xMax = 0, yMin = 65536, yMax = 0;
		for (y in 0...height)
			for (x in 0...width)
				if (pixels.get((y * width + x) * 4 + 3) > limit) {
					if (x < xMin)
						xMin = x;
					if (x > xMax)
						xMax = x;
					if (y < yMin)
						yMin = y;
					if (y > yMax)
						yMax = y;
				}
		return xMin == 65536 ? out.makeEmpty() : out.set(xMin, yMin, xMax + 1, yMax + 1);
	}

	// ---- Drawn into ----

	/** Fills it with a color.

		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function fill(color:Int):Image {
		var c = rgba(color);
		for (i in 0...width * height)
			pixels.setInt32(i * 4, c);
		return this;
	}

	/** Sets a pixel; one outside the image is skipped.

		@param x  The pixel's column, from the left.
		@param y  Its row, from the top.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function setPixel(x:Int, y:Int, color:Int):Image {
		if (x >= 0 && x < width && y >= 0 && y < height)
			pixels.setInt32((y * width + x) * 4, rgba(color));
		return this;
	}

	/** Draws a line one pixel wide, from its start to its end, both drawn; the rows (or columns) it steps across are rounded to the
		nearest.

		@param x0  The start's column, in pixels from the left.
		@param y0  The start's row, from the top.
		@param x1  The end's column.
		@param y1  The end's row.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawLine(x0:Int, y0:Int, x1:Int, y1:Int, color:Int):Image {
		var c = rgba(color),
			shortLen = y1 - y0,
			longLen = x1 - x0,
			yLonger = false;
		if (iabs(shortLen) > iabs(longLen)) {
			var t = shortLen;
			shortLen = longLen;
			longLen = t;
			yLonger = true;
		}
		var endVal = longLen + 1, sgnInc = 1;
		if (longLen < 0) {
			longLen = -longLen;
			sgnInc = -1;
			endVal -= 2;
		}
		// The minor axis in 16.16 fixed point, from a half for rounding.
		var decInc = longLen == 0 ? 0 : Std.int((shortLen << 16) / longLen), i = 0, j = 1 << 15;
		while (i != endVal) {
			if (yLonger)
				plot(x0 + (j >> 16), y0 + i, c);
			else
				plot(x0 + i, y0 + (j >> 16), c);
			i += sgnInc;
			j += decInc;
		}
		return this;
	}

	/** Draws a line of a thickness: as many `drawLine`s as it is thick, side by side, below and above the line for a line more across
		than down, right and left of it otherwise, the odd one out below or right.

		The ends are rounded to whole pixels; a line from a pixel to itself draws nothing.
		@param x0  The start's x, in pixels from the left.
		@param y0  The start's y, from the top.
		@param x1  The end's x.
		@param y1  The end's y.
		@param thickness  The thickness, in pixels; less than 1 draws the line alone.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawThickLine(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Int, color:Int):Image {
		var ax = Std.int(f32(f32(x0) + 0.5)),
			ay = Std.int(f32(f32(y0) + 0.5)),
			bx = Std.int(f32(f32(x1) + 0.5)),
			by = Std.int(f32(f32(y1) + 0.5));
		var dx = bx - ax, dy = by - ay;
		if (dx != 0 && iabs(Std.int(dy / dx)) < 1) {
			var wy = thickness - 1;
			for (i in 0...Std.int((wy + 1) / 2) + 1)
				drawLine(ax, ay + i, bx, by + i, color);
			for (i in 1...Std.int(wy / 2) + 1)
				drawLine(ax, ay - i, bx, by - i, color);
		} else if (dy != 0) {
			var wx = thickness - 1;
			for (i in 0...Std.int((wx + 1) / 2) + 1)
				drawLine(ax + i, ay, bx + i, by, color);
			for (i in 1...Std.int(wx / 2) + 1)
				drawLine(ax - i, ay, bx - i, by, color);
		}
		return this;
	}

	/** Fills a circle (midpoint algorithm), each row as wide either side of the middle.

		@param x  The middle's column, in pixels from the left.
		@param y  The middle's row, from the top.
		@param radius  The radius, in pixels.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawCircle(x:Int, y:Int, radius:Int, color:Int):Image {
		var cx = 0, cy = radius, decision = 3 - 2 * radius;
		while (cy >= cx) {
			drawRectangle(x - cx, y + cy, cx * 2 + 1, 1, color);
			drawRectangle(x - cx, y - cy, cx * 2 + 1, 1, color);
			drawRectangle(x - cy, y + cx, cy * 2 + 1, 1, color);
			drawRectangle(x - cy, y - cx, cy * 2 + 1, 1, color);
			cx++;
			if (decision > 0) {
				cy--;
				decision = decision + 4 * (cx - cy) + 10;
			} else
				decision = decision + 4 * cx + 6;
		}
		return this;
	}

	/** Outlines a circle, one pixel wide (midpoint algorithm).

		@param x  The middle's column, in pixels from the left.
		@param y  The middle's row, from the top.
		@param radius  The radius, in pixels.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawCircleLines(x:Int, y:Int, radius:Int, color:Int):Image {
		var c = rgba(color), cx = 0, cy = radius, decision = 3 - 2 * radius;
		while (cy >= cx) {
			plot(x + cx, y + cy, c);
			plot(x - cx, y + cy, c);
			plot(x + cx, y - cy, c);
			plot(x - cx, y - cy, c);
			plot(x + cy, y + cx, c);
			plot(x - cy, y + cx, c);
			plot(x + cy, y - cx, c);
			plot(x - cy, y - cx, c);
			cx++;
			if (decision > 0) {
				cy--;
				decision = decision + 4 * (cx - cy) + 10;
			} else
				decision = decision + 4 * cx + 6;
		}
		return this;
	}

	/** Fills a rectangle; what falls outside the image is skipped.

		A rectangle 0 wide still sets its top-left pixel, and one 0 high its top row, as raylib's does (its circles rely on it).
		@param x  The left edge, in pixels.
		@param y  The top edge.
		@param width  The width, in pixels.
		@param height  The height.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawRectangle(x:Int, y:Int, width:Int, height:Int, color:Int):Image {
		if (this.width == 0 || this.height == 0)
			return this;
		if (x < 0) {
			width += x;
			x = 0;
		}
		if (y < 0) {
			height += y;
			y = 0;
		}
		if (width < 0)
			width = 0;
		if (height < 0)
			height = 0;
		if (x + width >= this.width)
			width = this.width - x;
		if (y + height >= this.height)
			height = this.height - y;
		if (x >= this.width || y >= this.height || x + width <= 0 || y + height <= 0)
			return this;
		var c = rgba(color), first = (y * this.width + x) * 4;
		pixels.setInt32(first, c);
		for (i in 1...width)
			pixels.setInt32(first + i * 4, c);
		for (row in 1...height)
			pixels.blit(first + row * this.width * 4, pixels, first, width * 4);
		return this;
	}

	/** Outlines a rectangle, the outline inside it.

		@param x  The left edge, in pixels.
		@param y  The top edge.
		@param width  The width, in pixels.
		@param height  The height.
		@param thickness  The outline's thickness, in pixels.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawRectangleLines(x:Int, y:Int, width:Int, height:Int, thickness:Int, color:Int):Image {
		drawRectangle(x, y, width, thickness, color);
		drawRectangle(x, y + thickness, thickness, height - thickness * 2, color);
		drawRectangle(x + width - thickness, y + thickness, thickness, height - thickness * 2, color);
		drawRectangle(x, y + height - thickness, width, thickness, color);
		return this;
	}

	/** Fills a triangle, each corner its own color, blended across it.

		The corners may go either way round. When the three colors are the same the triangle is that color (raylib's `ImageDrawTriangle`);
		otherwise each channel is blended by the pixel's weights, each rounded down (raylib's `ImageDrawTriangleEx`).
		@param x0  The first corner's x, in pixels from the left.
		@param y0  The first corner's y, from the top.
		@param x1  The second corner's x.
		@param y1  The second corner's y.
		@param x2  The third corner's x.
		@param y2  The third corner's y.
		@param color0  The first corner's color, as 0xAARRGGBB.
		@param color1  The second corner's color.
		@param color2  The third corner's color.
		@return  This image. */
	public function drawTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color0:Int, color1:Int, color2:Int):Image {
		var ax = f32(x0), ay = f32(y0), bx = f32(x1), by = f32(y1), cx = f32(x2), cy = f32(y2);
		var xMin = Std.int(ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx));
		var yMin = Std.int(ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy));
		var xMax = Std.int(ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx));
		var yMax = Std.int(ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy));
		if (xMin < 0)
			xMin = 0;
		if (yMin < 0)
			yMin = 0;
		if (xMax > width)
			xMax = width;
		if (yMax > height)
			yMax = height;
		var signedArea = f32(f32(f32(bx - ax) * f32(cy - ay)) - f32(f32(cx - ax) * f32(by - ay)));
		var flip = signedArea > 0 ? -1 : 1;
		var w1XStep = Std.int(f32(cy - by)) * flip,
			w1YStep = Std.int(f32(bx - cx)) * flip;
		var w2XStep = Std.int(f32(ay - cy)) * flip,
			w2YStep = Std.int(f32(cx - ax)) * flip;
		var w3XStep = Std.int(f32(by - ay)) * flip,
			w3YStep = Std.int(f32(ax - bx)) * flip;
		var w1Row = Std.int(f32(f32(f32(xMin - bx) * w1XStep) + f32(w1YStep * f32(yMin - by))));
		var w2Row = Std.int(f32(f32(f32(xMin - cx) * w2XStep) + f32(w2YStep * f32(yMin - cy))));
		var w3Row = Std.int(f32(f32(f32(xMin - ax) * w3XStep) + f32(w3YStep * f32(yMin - ay))));
		var solid = color0 == color1 && color1 == color2, c = rgba(color0);
		var inv = f32(255 / f32(w1Row + w2Row + w3Row));
		var r0 = red(color0),
			g0 = green(color0),
			b0 = blue(color0),
			a0 = alpha(color0);
		var r1 = red(color1),
			g1 = green(color1),
			b1 = blue(color1),
			a1 = alpha(color1);
		var r2 = red(color2),
			g2 = green(color2),
			b2 = blue(color2),
			a2 = alpha(color2);
		for (y in yMin...yMax + 1) {
			var w1 = w1Row, w2 = w2Row, w3 = w3Row;
			for (x in xMin...xMax + 1) {
				if ((w1 | w2 | w3) >= 0) {
					if (solid)
						plot(x, y, c);
					else if (x < width && y < height) {
						var k1 = byte(f32(w1 * inv)),
							k2 = byte(f32(w2 * inv)),
							k3 = byte(f32(w3 * inv)),
							at = (y * width + x) * 4;
						pixels.set(at, Std.int((r0 * k1 + r1 * k2 + r2 * k3) / 255) & 255);
						pixels.set(at + 1, Std.int((g0 * k1 + g1 * k2 + g2 * k3) / 255) & 255);
						pixels.set(at + 2, Std.int((b0 * k1 + b1 * k2 + b2 * k3) / 255) & 255);
						pixels.set(at + 3, Std.int((a0 * k1 + a1 * k2 + a2 * k3) / 255) & 255);
					}
				}
				w1 += w1XStep;
				w2 += w2XStep;
				w3 += w3XStep;
			}
			w1Row += w1YStep;
			w2Row += w2YStep;
			w3Row += w3YStep;
		}
		return this;
	}

	/** Outlines a triangle with three `drawLine`s, its corners cut to whole pixels.

		@param x0  The first corner's x, in pixels from the left.
		@param y0  The first corner's y, from the top.
		@param x1  The second corner's x.
		@param y1  The second corner's y.
		@param x2  The third corner's x.
		@param y2  The third corner's y.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawTriangleLines(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int):Image {
		var ax = Std.int(f32(x0)),
			ay = Std.int(f32(y0)),
			bx = Std.int(f32(x1)),
			by = Std.int(f32(y1)),
			cx = Std.int(f32(x2)),
			cy = Std.int(f32(y2));
		drawLine(ax, ay, bx, by, color);
		drawLine(bx, by, cx, cy, color);
		drawLine(cx, cy, ax, ay, color);
		return this;
	}

	/** Draws a rectangle of another image into a rectangle of this one, tinted, blended over.

		The source rectangle is clamped to the source. When its whole-pixel size differs from the destination's it is resized `Bilinear`
		first (raylib's `ImageDraw` resizes with stb_image_resize2). Positions are cut to whole pixels.
		@param source  The image drawn from; it may be this one only when the rectangles don't overlap.
		@param sourceX  The source rectangle's left edge, in the source's pixels.
		@param sourceY  Its top edge.
		@param sourceWidth  Its width.
		@param sourceHeight  Its height.
		@param x  The destination rectangle's left edge, in pixels.
		@param y  Its top edge.
		@param width  Its width.
		@param height  Its height.
		@param tint  The color the source is multiplied by, as 0xAARRGGBB: white leaves it unchanged.
		@return  This image. */
	public function drawImage(source:Image, sourceX:Float, sourceY:Float, sourceWidth:Float, sourceHeight:Float, x:Float, y:Float, width:Float, height:Float,
			tint:Int):Image {
		if (this.width == 0 || this.height == 0 || source.width == 0 || source.height == 0)
			return this;
		var sx = f32(sourceX),
			sy = f32(sourceY),
			sw = f32(sourceWidth),
			sh = f32(sourceHeight);
		var dx = f32(x), dy = f32(y), dw = f32(width), dh = f32(height);
		if (sx < 0) {
			sw = f32(sw + sx);
			sx = 0;
		}
		if (sy < 0) {
			sh = f32(sh + sy);
			sy = 0;
		}
		if (f32(sx + sw) > source.width)
			sw = f32(source.width - sx);
		if (f32(sy + sh) > source.height)
			sh = f32(source.height - sy);
		var from = source;
		if (Std.int(sw) != Std.int(dw) || Std.int(sh) != Std.int(dh)) {
			if (Std.int(sw) <= 0 || Std.int(sh) <= 0 || Std.int(dw) <= 0 || Std.int(dh) <= 0)
				return this;
			from = source.crop(Std.int(sx), Std.int(sy), Std.int(sw), Std.int(sh)).resize(Std.int(dw), Std.int(dh), Bilinear);
			sx = 0;
			sy = 0;
			sw = from.width;
			sh = from.height;
		}
		if (dx < 0) {
			sx = f32(sx - dx);
			sw = f32(sw + dx);
			dx = 0;
		} else if (f32(dx + sw) > this.width)
			sw = f32(this.width - dx);
		if (dy < 0) {
			sy = f32(sy - dy);
			sh = f32(sh + dy);
			dy = 0;
		} else if (f32(dy + sh) > this.height)
			sh = f32(this.height - dy);
		if (this.width < sw)
			sw = this.width;
		if (this.height < sh)
			sh = this.height;
		var tr = red(tint) + 1, tg = green(tint) + 1, tb = blue(tint) + 1, ta = alpha(tint) + 1, src = from.pixels, dst = pixels;
		var columns = Std.int(sw);
		for (row in 0...Std.int(sh)) {
			var s = ((Std.int(sy) + row) * from.width + Std.int(sx)) * 4,
				d = ((Std.int(dy) + row) * this.width + Std.int(dx)) * 4;
			for (_ in 0...columns) {
				// raylib's ColorAlphaBlend, in its integers.
				var r = (src.get(s) * tr) >> 8,
					g = (src.get(s + 1) * tg) >> 8,
					b = (src.get(s + 2) * tb) >> 8,
					a = (src.get(s + 3) * ta) >> 8;
				if (a == 255) {
					dst.set(d, r);
					dst.set(d + 1, g);
					dst.set(d + 2, b);
					dst.set(d + 3, a);
				} else if (a != 0) {
					var weight = a + 1,
						under = dst.get(d + 3),
						rest = under * (256 - weight);
					var outA = (weight * 256 + rest) >> 8;
					if (outA > 0) {
						dst.set(d, (Std.int((r * weight * 256 + dst.get(d) * rest) / outA) >> 8) & 255);
						dst.set(d + 1, (Std.int((g * weight * 256 + dst.get(d + 1) * rest) / outA) >> 8) & 255);
						dst.set(d + 2, (Std.int((b * weight * 256 + dst.get(d + 2) * rest) / outA) >> 8) & 255);
					} else {
						dst.set(d, 255);
						dst.set(d + 1, 255);
						dst.set(d + 2, 255);
					}
					dst.set(d + 3, outA);
				}
				s += 4;
				d += 4;
			}
		}
		return this;
	}

	/** Draws text in a font, tinted, blended over.

		The text is laid out at the font's size, as raylib's `ImageDrawTextEx` lays it, then scaled to `size` (`Bilinear`) and drawn: each
		glyph at the pen and its offsets, the pen moved by its advance (or its width, for a glyph advancing 0) and `spacing`. A newline
		starts the next line, the font's size and line gap below. A character the font lacks is drawn as its "?", or as its first glyph;
		spaces and tabs only move the pen.
		@param font  The font.
		@param text  The text.
		@param x  The left edge of the text, in pixels.
		@param y  The top of its first line, in pixels: its ascent above the baseline.
		@param size  The height of a line, in pixels; the font's own size draws it unscaled.
		@param spacing  The pixels added after each character, at the font's size.
		@param color  The color, as 0xAARRGGBB.
		@return  This image. */
	public function drawText(font:Font2D, text:String, x:Float, y:Float, size:Float, spacing:Float, color:Int):Image {
		if (text.length == 0 || font.glyphs.length == 0)
			return this;
		spacing = f32(spacing);
		function glyphOf(codepoint:Int):Glyph2D {
			var glyph = font.getGlyph(codepoint);
			if (glyph == null)
				glyph = font.getGlyph("?".code);
			return glyph == null ? font.glyphs[0] : glyph;
		}
		// Measured as raylib's MeasureTextEx measures, at the font's size.
		var widest = 0., lineWidth = 0., most = 0, count = 0, lines = 1;
		for (codepoint in new haxe.iterators.StringIteratorUnicode(text)) {
			count++;
			if (codepoint == "\n".code) {
				if (widest < lineWidth)
					widest = lineWidth;
				lineWidth = 0;
				count = 0;
				lines++;
			} else {
				var glyph = glyphOf(codepoint);
				lineWidth = f32(lineWidth + (glyph.advance > 0 ? f32(glyph.advance) : f32(glyph.width + f32(glyph.offsetX))));
			}
			if (most < count)
				most = count;
		}
		if (widest < lineWidth)
			widest = lineWidth;
		var lineHeight = f32(f32(font.size) + f32(font.lineGap));
		var canvasWidth = Std.int(Math.ceil(f32(widest + f32((most - 1) * spacing))));
		var canvasHeight = Std.int(Math.ceil(f32(f32((lines - 1) * lineHeight) + f32(font.size))));
		if (canvasWidth <= 0 || canvasHeight <= 0)
			return this;
		var canvas = blank(canvasWidth, canvasHeight), penX = 0., penY = 0.;
		for (codepoint in new haxe.iterators.StringIteratorUnicode(text)) {
			if (codepoint == "\n".code) {
				penY = f32(penY + lineHeight);
				penX = 0;
				continue;
			}
			var glyph = glyphOf(codepoint);
			if (codepoint != " ".code && codepoint != "\t".code && glyph.width > 0 && glyph.height > 0)
				canvas.drawImage(font.atlas, glyph.x, glyph.y, glyph.width, glyph.height, f32(penX + f32(glyph.offsetX)),
					f32(f32(penY + f32(font.ascent)) + f32(glyph.offsetY)), glyph.width, glyph.height, color);
			penX = f32(penX + f32(f32(glyph.advance == 0 ? glyph.width : glyph.advance) + spacing));
		}
		size = f32(size);
		var base = f32(font.size);
		if (size != base) {
			var scale = f32(size / base);
			canvas = canvas.resize(Std.int(f32(canvasWidth * scale)), Std.int(f32(canvasHeight * scale)), Bilinear);
		}
		drawImage(canvas, 0, 0, canvas.width, canvas.height, x, y, canvas.width, canvas.height, 0xffffffff);
		return this;
	}

	// ---- Helpers ----
	// A transparent image, its pixels zeroed.
	static function blank(width:Int, height:Int):Image {
		if (width < 0)
			width = 0;
		if (height < 0)
			height = 0;
		var bytes = Bytes.alloc(width * height * 4);
		bytes.fill(0, bytes.length, 0);
		return new Image("", width, height, bytes);
	}

	// raylib's arithmetic is in single precision: each operation's result rounded to the nearest float.
	static inline function f32(x:Float):Float {
		#if js
		return js.lib.Math.fround(x);
		#elseif cpp
		var single:cpp.Float32 = x;
		return single;
		#else
		return haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(x));
		#end
	}

	// A number as C's (unsigned char) cast makes it: truncated, its low 8 bits.
	static inline function byte(x:Float):Int
		return Std.int(x) & 255;

	static inline function iabs(x:Int):Int
		return x < 0 ? -x : x;

	static inline function signbit(x:Float):Bool
		return x < 0 || (x == 0 && 1 / x < 0);

	static inline function red(color:Int):Int
		return (color >> 16) & 255;

	static inline function green(color:Int):Int
		return (color >> 8) & 255;

	static inline function blue(color:Int):Int
		return color & 255;

	static inline function alpha(color:Int):Int
		return (color >>> 24) & 255;

	// A color as the four bytes of a pixel read as one little-endian Int32.
	static inline function rgba(color:Int):Int
		return (color & 0xff00ff00) | ((color >> 16) & 255) | ((color & 255) << 16);

	static inline function put(p:Bytes, at:Int, color:Int):Void
		p.setInt32(at, rgba(color));

	inline function plot(x:Int, y:Int, rgba:Int):Void
		if (x >= 0 && x < width && y >= 0 && y < height)
			pixels.setInt32((y * width + x) * 4, rgba);

	// The gradients' blend: outer * factor + inner * (1 - factor), in floats, cut to bytes.
	static inline function mix(p:Bytes, at:Int, inner:Int, outer:Int, factor:Float):Void {
		var rest = f32(1 - factor);
		p.set(at, byte(f32(f32(red(outer) * factor) + f32(red(inner) * rest))));
		p.set(at + 1, byte(f32(f32(green(outer) * factor) + f32(green(inner) * rest))));
		p.set(at + 2, byte(f32(f32(blue(outer) * factor) + f32(blue(inner) * rest))));
		p.set(at + 3, byte(f32(f32(alpha(outer) * factor) + f32(alpha(inner) * rest))));
	}

	// raylib's grayscale conversion: the channels as fractions, weighted, back to a byte.
	static inline function luminance(p:Bytes, at:Int):Int {
		var r = f32(p.get(at) / 255),
			g = f32(p.get(at + 1) / 255),
			b = f32(p.get(at + 2) / 255);
		return byte(f32(f32(f32(f32(r * LUMA_R) + f32(g * LUMA_G)) + f32(b * LUMA_B)) * 255));
	}

	static final LUMA_R = f32(0.299);
	static final LUMA_G = f32(0.587);
	static final LUMA_B = f32(0.114);

	// A level of a channel cut to some bits, widened back to 8 as raylib's ImageFormat widens R5G6B5, R5G5B5A1 and R4G4B4A4.
	static function widen(level:Int, bits:Int, isAlpha:Bool):Int {
		if (bits == 8)
			return level;
		if (bits == 0)
			return isAlpha ? 255 : 0;
		return byte(f32(f32(level * f32(1 / ((1 << bits) - 1))) * 255));
	}

	function resizeNearest(newWidth:Int, newHeight:Int):Image {
		var image = blank(newWidth, newHeight), p = image.pixels;
		var xRatio = Std.int((width << 16) / newWidth) + 1,
			yRatio = Std.int((height << 16) / newHeight) + 1;
		for (y in 0...newHeight) {
			var row = ((y * yRatio) >> 16) * width;
			for (x in 0...newWidth)
				p.setInt32((y * newWidth + x) * 4, pixels.getInt32((row + ((x * xRatio) >> 16)) * 4));
		}
		return image;
	}

	// Bilinear (2 taps a side) and Catmull-Rom (4) over alpha-weighted colors, each pixel sampled at its middle, edges clamped.
	function resample(newWidth:Int, newHeight:Int, taps:Int):Image {
		var image = blank(newWidth, newHeight), p = image.pixels;
		var xIndex = new Vector<Int>(newWidth * taps),
			xWeight = new Vector<Float>(newWidth * taps);
		var yIndex = new Vector<Int>(newHeight * taps),
			yWeight = new Vector<Float>(newHeight * taps);
		function weights(index:Vector<Int>, weight:Vector<Float>, count:Int, size:Int)
			for (i in 0...count) {
				var at = (i + 0.5) * size / count - 0.5, base = Math.floor(at), t = at - base;
				var first = taps == 2 ? base : base - 1;
				for (k in 0...taps) {
					var j = Std.int(first) + k;
					index[i * taps + k] = (j < 0 ? 0 : j >= size ? size - 1 : j) * 4;
					weight[i * taps + k] = taps == 2 ? (k == 0 ? 1 - t : t) : catmullRom(k, t);
				}
			}
		weights(xIndex, xWeight, newWidth, width);
		weights(yIndex, yWeight, newHeight, height);
		var stride = width * 4;
		for (y in 0...newHeight)
			for (x in 0...newWidth) {
				var r = 0., g = 0., b = 0., a = 0.;
				for (ky in 0...taps) {
					var wy = yWeight[y * taps + ky],
						row = Std.int(yIndex[y * taps + ky] / 4) * stride;
					for (kx in 0...taps) {
						var at = row + xIndex[x * taps + kx],
							w = wy * xWeight[x * taps + kx],
							wa = w * pixels.get(at + 3);
						r += pixels.get(at) * wa;
						g += pixels.get(at + 1) * wa;
						b += pixels.get(at + 2) * wa;
						a += wa;
					}
				}
				var at = (y * newWidth + x) * 4;
				if (a > 0) {
					p.set(at, clampByte(r / a));
					p.set(at + 1, clampByte(g / a));
					p.set(at + 2, clampByte(b / a));
					p.set(at + 3, clampByte(a));
				}
			}
		return image;
	}

	static inline function clampByte(v:Float):Int
		return v <= 0 ? 0 : v >= 255 ? 255 : Math.round(v);

	// Catmull-Rom's weight for tap k (0 to 3) of the four around a point t (0 to 1) past the second.
	static inline function catmullRom(k:Int, t:Float):Float {
		var t2 = t * t, t3 = t2 * t;
		return switch k {
			case 0: (-t3 + 2 * t2 - t) / 2;
			case 1: (3 * t3 - 5 * t2 + 2) / 2;
			case 2: (-3 * t3 + 4 * t2 + t) / 2;
			case _: (t3 - t2) / 2;
		}
	}

	// stb_perlin's stb_perlin_fbm_noise3 as raylib calls it: lacunarity 2, gain 0.5, 6 octaves, no wrapping.
	static function fbm(x:Float, y:Float, z:Float):Float {
		var frequency = 1., amplitude = 1., sum = 0.;
		for (i in 0...6) {
			sum = f32(sum + f32(noise(f32(x * frequency), f32(y * frequency), f32(z * frequency), i) * amplitude));
			frequency = f32(frequency * 2);
			amplitude = f32(amplitude * 0.5);
		}
		return sum;
	}

	static inline function fastFloor(a:Float):Int {
		var i = Std.int(a);
		return a < i ? i - 1 : i;
	}

	static inline function ease(a:Float):Float
		return f32(f32(f32(f32(f32(f32(f32(a * 6) - 15) * a) + 10) * a) * a) * a);

	static inline function lerp(a:Float, b:Float, t:Float):Float
		return f32(a + f32(f32(b - a) * t));

	static inline function grad(index:Int, x:Float, y:Float, z:Float):Float {
		var at = PERLIN_GRAD_INDEX[index & 255] * 3;
		return f32(f32(f32(PERLIN_BASIS[at] * x) + f32(PERLIN_BASIS[at + 1] * y)) + f32(PERLIN_BASIS[at + 2] * z));
	}

	// stb_perlin_noise3_internal, its wraps 0 (every 256).
	static function noise(x:Float, y:Float, z:Float, seed:Int):Float {
		var px = fastFloor(x), py = fastFloor(y), pz = fastFloor(z);
		var x0 = px & 255, x1 = (px + 1) & 255, y0 = py & 255, y1 = (py + 1) & 255, z0 = pz & 255, z1 = (pz + 1) & 255;
		x = f32(x - px);
		y = f32(y - py);
		z = f32(z - pz);
		var u = ease(x), v = ease(y), w = ease(z);
		var r0 = PERLIN[(x0 + seed) & 255], r1 = PERLIN[(x1 + seed) & 255];
		var r00 = PERLIN[(r0 + y0) & 255],
			r01 = PERLIN[(r0 + y1) & 255],
			r10 = PERLIN[(r1 + y0) & 255],
			r11 = PERLIN[(r1 + y1) & 255];
		var xm = f32(x - 1), ym = f32(y - 1), zm = f32(z - 1);
		var n00 = lerp(grad(r00 + z0, x, y, z), grad(r00 + z1, x, y, zm), w);
		var n01 = lerp(grad(r01 + z0, x, ym, z), grad(r01 + z1, x, ym, zm), w);
		var n10 = lerp(grad(r10 + z0, xm, y, z), grad(r10 + z1, xm, y, zm), w);
		var n11 = lerp(grad(r11 + z0, xm, ym, z), grad(r11 + z1, xm, ym, zm), w);
		return lerp(lerp(n00, n01, v), lerp(n10, n11, v), u);
	}

	static final PERLIN_BASIS:Array<Float> = [
		1, 1, 0, -1,  1, 0, 1, -1,  0, -1, -1,  0,
		1, 0, 1, -1,  0, 1, 1,  0, -1, -1,  0, -1,
		0, 1, 1,  0, -1, 1, 0,  1, -1,  0, -1, -1
	];

	// stb_perlin's permutation (its second copy dropped: an index is taken modulo 256).
	static final PERLIN:Array<Int> = [
		23, 125, 161, 52, 103, 117, 70, 37, 247, 101, 203, 169, 124, 126, 44, 123, 152, 238, 145, 45, 171, 114, 253, 10, 192, 136, 4, 157, 249, 30, 35, 72,
		175, 63, 77, 90, 181, 16, 96, 111, 133, 104, 75, 162, 93, 56, 66, 240, 8, 50, 84, 229, 49, 210, 173, 239, 141, 1, 87, 18, 2, 198, 143, 57, 225, 160,
		58, 217, 168, 206, 245, 204, 199, 6, 73, 60, 20, 230, 211, 233, 94, 200, 88, 9, 74, 155, 33, 15, 219, 130, 226, 202, 83, 236, 42, 172, 165, 218, 55,
		222, 46, 107, 98, 154, 109, 67, 196, 178, 127, 158, 13, 243, 65, 79, 166, 248, 25, 224, 115, 80, 68, 51, 184, 128, 232, 208, 151, 122, 26, 212, 105,
		43, 179, 213, 235, 148, 146, 89, 14, 195, 28, 78, 112, 76, 250, 47, 24, 251, 140, 108, 186, 190, 228, 170, 183, 139, 39, 188, 244, 246, 132, 48, 119,
		144, 180, 138, 134, 193, 82, 182, 120, 121, 86, 220, 209, 3, 91, 241, 149, 85, 205, 150, 113, 216, 31, 100, 41, 164, 177, 214, 153, 231, 38, 71, 185,
		174, 97, 201, 29, 95, 7, 92, 54, 254, 191, 118, 34, 221, 131, 11, 163, 99, 234, 81, 227, 147, 156, 176, 17, 142, 69, 12, 110, 62, 27, 255, 0, 194, 59,
		116, 242, 252, 19, 21, 187, 53, 207, 129, 64, 135, 61, 40, 167, 237, 102, 223, 106, 159, 197, 189, 215, 137, 36, 32, 22, 5
	];

	// stb_perlin's gradient for each permutation entry (its second copy dropped likewise).
	static final PERLIN_GRAD_INDEX:Array<Int> = [
		7, 9, 5, 0, 11, 1, 6, 9, 3, 9, 11, 1, 8, 10, 4, 7, 8, 6, 1, 5, 3, 10, 9, 10, 0, 8, 4, 1, 5, 2, 7, 8, 7, 11, 9, 10, 1, 0, 4, 7, 5, 0, 11, 6, 1, 4, 2,
		8, 8, 10, 4, 9, 9, 2, 5, 7, 9, 1, 7, 2, 2, 6, 11, 5, 5, 4, 6, 9, 0, 1, 1, 0, 7, 6, 9, 8, 4, 10, 3, 1, 2, 8, 8, 9, 10, 11, 5, 11, 11, 2, 6, 10, 3, 4,
		2, 4, 9, 10, 3, 2, 6, 3, 6, 10, 5, 3, 4, 10, 11, 2, 9, 11, 1, 11, 10, 4, 9, 4, 11, 0, 4, 11, 4, 0, 0, 0, 7, 6, 10, 4, 1, 3, 11, 5, 3, 4, 2, 9, 1, 3,
		0, 1, 8, 0, 6, 7, 8, 7, 0, 4, 6, 10, 8, 2, 3, 11, 11, 8, 0, 2, 4, 8, 3, 0, 0, 10, 6, 1, 2, 2, 4, 5, 6, 0, 1, 3, 11, 9, 5, 5, 9, 6, 9, 8, 3, 8, 1, 8,
		9, 6, 9, 11, 10, 7, 5, 6, 5, 9, 1, 3, 7, 0, 2, 10, 11, 2, 6, 1, 3, 11, 7, 7, 2, 1, 7, 3, 0, 8, 1, 1, 5, 0, 6, 10, 11, 11, 0, 2, 7, 0, 10, 8, 3, 5, 7,
		1, 11, 1, 0, 7, 9, 0, 11, 5, 10, 3, 2, 3, 5, 9, 7, 9, 8, 4, 6, 5
	];
}
