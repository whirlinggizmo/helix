package helix.font;

import haxe.io.Bytes;

/** A baked glyph: its place in the atlas, its box's offset from the pen on the baseline (y down) and its advance, in pixels at the baked height.
	A glyph with nothing to draw (a space) has no size. */
typedef BakedGlyph = {
	final code:Int;
	final x:Int;
	final y:Int;
	final width:Int;
	final height:Int;
	final xOffset:Int;
	final yOffset:Int;
	final advance:Float;
}

/** A glyph's distance field and its box's size and offset from the pen. */
private typedef Shape = {
	final field:Bytes;
	final width:Int;
	final height:Int;
	final xOffset:Int;
	final yOffset:Int;
}

/** A font's characters baked into one distance-field atlas: a byte a texel, 128 on the outline, rising inward and falling outward by 128 /
	padding a pixel. */
typedef BakedFont = {
	final width:Int;
	final height:Int;
	final field:Bytes;
	final pixelHeight:Float;
	final scale:Float;
	final ascent:Float;
	final descent:Float;
	final lineGap:Float;
	final glyphs:Array<BakedGlyph>;
}

/** Bakes a TrueType font's characters into a signed distance field atlas, in Haxe, the same on every target: each glyph's outline is flattened
	into segments finer than a twentieth of a pixel, and each texel holds its signed distance to them (inside by the nonzero rule), so text drawn
	from it stays sharp from small to about four times the baked height. Glyphs are packed in rows, left to right. */
class FontBaker {
	static inline var ON_EDGE = 128;

	/** Bakes codes (characters) of font at pixelHeight (ascent to descent) with padding pixels of field around each glyph, into an atlas
		atlasWidth wide and as tall as it needs (a power of two), with a free last row (its last texel is set fully inside: a white texel). */
	public static function bake(font:TrueType, codes:Array<Int>, pixelHeight:Float, padding:Int, atlasWidth:Int):BakedFont {
		var scale = pixelHeight / (font.ascent - font.descent);
		var fields:Array<Bytes> = [], glyphs:Array<BakedGlyph> = [];
		var x = 0, y = 0, rowHeight = 0;
		for (code in codes) {
			var glyph = font.getGlyphIndex(code);
			var shape = distanceField(font.getOutline(glyph), scale, padding);
			var placeX = 0, placeY = 0;
			if (shape != null) {
				if (x + shape.width + 1 > atlasWidth) {
					x = 0;
					y += rowHeight + 1;
					rowHeight = 0;
				}
				placeX = x;
				placeY = y;
				x += shape.width + 1;
				rowHeight = shape.height > rowHeight ? shape.height : rowHeight;
			}
			fields.push(shape != null ? shape.field : null);
			glyphs.push({
				code: code,
				x: placeX,
				y: placeY,
				width: shape != null ? shape.width : 0,
				height: shape != null ? shape.height : 0,
				xOffset: shape != null ? shape.xOffset : 0,
				yOffset: shape != null ? shape.yOffset : 0,
				advance: font.getAdvance(glyph) * scale
			});
		}
		// A free row below the glyphs, for the white texel.
		var height = 1;
		while (height < y + rowHeight + 1)
			height *= 2;
		var atlas = Bytes.alloc(atlasWidth * height);
		for (i in 0...glyphs.length) {
			var g = glyphs[i];
			for (row in 0...g.height)
				atlas.blit((g.y + row) * atlasWidth + g.x, fields[i], row * g.width, g.width);
		}
		atlas.set(height * atlasWidth - 1, 255);
		return {
			width: atlasWidth,
			height: height,
			field: atlas,
			pixelHeight: pixelHeight,
			scale: scale,
			ascent: font.ascent * scale,
			descent: font.descent * scale,
			lineGap: font.lineGap * scale,
			glyphs: glyphs
		};
	}

	// The outline as line segments in pixels, y down: x0, y0, x1, y1 each.
	static function segments(outline:TrueType.GlyphOutline, scale:Float):Array<Float> {
		var out = [];
		for (contour in outline) {
			var p = contour.points, on = contour.onCurve, n = on.length;
			// Start at an on-curve point, or between two off-curve ones.
			var start = on.indexOf(true);
			var sx, sy;
			if (start < 0) {
				sx = (p[0] + p[2]) / 2;
				sy = (p[1] + p[3]) / 2;
				start = 0;
			} else {
				sx = p[start * 2];
				sy = p[start * 2 + 1];
			}
			var cx = sx, cy = sy, control = false, qx = 0., qy = 0.;
			inline function line(x:Float, y:Float):Void {
				out.push(cx * scale);
				out.push(-cy * scale);
				out.push(x * scale);
				out.push(-y * scale);
				cx = x;
				cy = y;
			}
			function curve(x:Float, y:Float):Void {
				// Flat to within 1/20 pixel: a quadratic's deviation is |p0 - 2 p1 + p2| / 8 over the steps squared.
				var bx = (cx - 2 * qx + x) * scale,
					by = (cy - 2 * qy + y) * scale;
				var steps = Std.int(Math.max(1, Math.ceil(Math.sqrt(Math.sqrt(bx * bx + by * by) / 8 / .05))));
				var x0 = cx, y0 = cy;
				for (i in 1...steps + 1) {
					var t = i / steps, it = 1 - t;
					line(it * it * x0 + 2 * it * t * qx + t * t * x, it * it * y0 + 2 * it * t * qy + t * t * y);
				}
			}
			for (k in 1...n + 1) {
				var i = (start + k) % n, px = p[i * 2], py = p[i * 2 + 1];
				if (on[i]) {
					if (control)
						curve(px, py);
					else
						line(px, py);
					control = false;
				} else {
					if (control)
						curve((qx + px) / 2, (qy + py) / 2);
					qx = px;
					qy = py;
					control = true;
				}
			}
			// Close back to the start.
			if (control)
				curve(sx, sy);
			else if (cx != sx || cy != sy)
				line(sx, sy);
		}
		return out;
	}

	// The glyph's field and its box, or null for an empty outline.
	static function distanceField(outline:TrueType.GlyphOutline, scale:Float, padding:Int):Null<Shape> {
		var s = segments(outline, scale);
		if (s.length == 0)
			return null;
		var minX = s[0], minY = s[1], maxX = s[0], maxY = s[1], k = 0;
		while (k < s.length) {
			minX = Math.min(minX, Math.min(s[k], s[k + 2]));
			maxX = Math.max(maxX, Math.max(s[k], s[k + 2]));
			minY = Math.min(minY, Math.min(s[k + 1], s[k + 3]));
			maxY = Math.max(maxY, Math.max(s[k + 1], s[k + 3]));
			k += 4;
		}
		var x0 = Math.floor(minX) - padding,
			y0 = Math.floor(minY) - padding,
			x1 = Math.ceil(maxX) + padding,
			y1 = Math.ceil(maxY) + padding;
		var w = x1 - x0, h = y1 - y0;
		if (w <= padding * 2 || h <= padding * 2)
			return null;
		var field = Bytes.alloc(w * h), perPixel = ON_EDGE / padding;
		for (j in 0...h) {
			var py = y0 + j + .5;
			for (i in 0...w) {
				var px = x0 + i + .5, best = 1e30, winding = 0;
				k = 0;
				while (k < s.length) {
					var ax = s[k], ay = s[k + 1], bx = s[k + 2], by = s[k + 3];
					// Winding: the edge crossing the ray to the right of the point, counted by its direction.
					if ((ay <= py) != (by <= py)) {
						var cross = ax + (py - ay) / (by - ay) * (bx - ax);
						if (cross > px)
							winding += by > ay ? 1 : -1;
					}
					var dx = bx - ax, dy = by - ay, length = dx * dx + dy * dy;
					var t = length > 0 ? ((px - ax) * dx + (py - ay) * dy) / length : 0;
					t = t < 0 ? 0 : t > 1 ? 1 : t;
					var ex = ax + t * dx - px,
						ey = ay + t * dy - py,
						d = ex * ex + ey * ey;
					if (d < best)
						best = d;
					k += 4;
				}
				var distance = Math.sqrt(best),
					value = ON_EDGE + (winding != 0 ? distance : -distance) * perPixel;
				field.set(j * w + i, value < 0 ? 0 : value > 255 ? 255 : Std.int(value));
			}
		}
		return {
			field: field,
			width: w,
			height: h,
			xOffset: x0,
			yOffset: y0
		};
	}
}
