package helix.raylib.internal;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RText;
import helix.raylib.modules.RTextures.*;

/** Draws text sharp under a screen fit drawn at the window's resolution (`SCREEN_STRETCH_CANVAS`): each glyph made at the size it lands
	on the screen, in framebuffer pixels, and drawn one texel to a pixel, where the font's own texture, made at its size, would be scaled
	by the fit. A TrueType or OpenType font's glyphs are rasterized from the font again, and the default font's resampled from its bitmap,
	each stroke covering the same share of the pixels it lands on. Fonts made otherwise (from an image, a BMFont, glyphs a program made)
	draw from their own texture, as without a fit.

	Glyphs are made the first time they're drawn at a size, onto one texture shared by every font: 512 x 512, made twice as large each
	time it's full up to 2048 x 2048, then emptied and filled again from what's drawn next. Sizes are rounded to steps (a whole pixel up to 64, 4 pixels past it) so
	a window being resized makes a glyph at each step rather than every size between. The texture isn't kept in memory: once the GPU's
	context is lost and restored, it's emptied, and glyphs are made again as they're drawn.

	Linked by `SetScreenFit`, whose program sets the hooks `RText` calls at its start. */
@:noCompletion
@:allow(helix.raylib)
class ScreenText {
	static function __init__():Void {
		RText.screenGlyph = draw;
		RText.screenFontBytes = open;
	}

	/** The texels between glyphs, so filtering one never reads its neighbour. */
	static inline final GAP = 2;

	/** The atlas's first size, and its largest. */
	static inline final FIRST = 512;

	static inline final LARGEST = 2048;

	/** The largest size key: a glyph made past it is drawn from the font's own texture. */
	static inline final MOST_SIZE = 1023;

	// The atlas, its rows (each its top, height and the x its next glyph goes at), and the glyphs on it by font, then by size and
	// codepoint. A texture emptied waits a frame to be unloaded, as the frame's draws so far read it.
	static var atlas:Null<Texture2D>;
	static var atlasSize = 0;
	static var rows:Array<Int>;
	static var made:ObjectMap<Font, IntMap<Glyph>>;
	static var retired:Null<Texture2D>;
	static var retiredAt = 0;
	static var restoring = false;

	// Reused each draw.
	static var source:Rectangle;
	static var dest:Rectangle;
	static var origin:Vector2;

	/** Links this class into a program setting a fit, so its start sets the hooks. */
	public static function link():Void {}

	// Opens a TrueType or OpenType font's bytes for its glyphs to be made at any size, once a program loads one.
	static function open(font:Font, bytes:haxe.io.Bytes):Void {
		Runtime.fonts().openFont(bytes, opened -> {
			font.opened = opened;
			font.ownsOpened = true;
		}, _ -> {});
	}

	// Draws a glyph from the atlas, made there first, when the screen's pass is fitted at the window's resolution; false, drawing nothing,
	// otherwise, so the font's own texture draws it.
	static function draw(font:Font, codepoint:Int, position:Vector2, fontSize:Float, tint:Color):Bool {
		var screen = Runtime.screen, frame = Runtime.frame;
		if (screen == null || frame == null || screen.designWidth == 0 || Frame.FrameFit.atDesignSize || frame.inTarget || screen.scaleX != screen.scaleY)
			return false;
		var bitmap = font.opened < 0;
		if (bitmap && (RText.fontDefault == null || font.texture == null || font.texture.id != RText.fontDefault.texture.id))
			return false;
		// The glyph raylib draws: a character the font wasn't made with draws as its '?'.
		codepoint = font.glyphs[RText.GetGlyphIndex(font, codepoint)].value;
		// Framebuffer pixels to a unit drawn in: the fit's scale, and a 2D camera's zoom or DrawTextPro's turn in the view.
		var view = frame.view, scale = screen.scaleX;
		var zoom = Math.sqrt(view.m0 * view.m0 + view.m1 * view.m1);
		var pixels = scale * zoom;
		if (pixels <= 0)
			return false;
		// The size key: the line's height in framebuffer pixels in steps, or for a bitmap an eighth of a pixel a texel.
		var key = bitmap ? Math.round(fontSize / font.baseSize * pixels * 8) : stepOf(fontSize * pixels);
		if (key < 1 || key > MOST_SIZE)
			return false;
		var glyph = glyphOf(font, codepoint, key, bitmap);
		if (glyph == null)
			return false;
		if (glyph.width == 0)
			return true;
		// Units drawn in a texel of the glyph: its size made over its size drawn, near a framebuffer pixel.
		var unit = (bitmap ? fontSize / font.baseSize / (key / 8) : fontSize / key);
		var x = position.x + glyph.offsetX * unit,
			y = position.y + glyph.offsetY * unit;
		if (view.m1 == 0 && view.m4 == 0 && view.m0 > 0 && view.m0 == view.m5) {
			// Its corner on a framebuffer pixel, so a texel lands on one.
			x = (Math.round((x * zoom + view.m12 - frame.originX) * scale) / scale + frame.originX - view.m12) / zoom;
			y = (Math.round((y * zoom + view.m13 - frame.originY) * scale) / scale + frame.originY - view.m13) / zoom;
		}
		source.x = glyph.x;
		source.y = glyph.y;
		source.width = glyph.width;
		source.height = glyph.height;
		dest.x = x;
		dest.y = y;
		dest.width = glyph.width * unit;
		dest.height = glyph.height * unit;
		DrawTexturePro(atlas, source, dest, origin, 0, tint);
		return true;
	}

	// A line height's step: a whole pixel up to 64, 4 pixels past it.
	static function stepOf(size:Float):Int
		return size <= 64 ? Math.round(size) : Math.round(size / 4) * 4;

	// The glyph made at a size, made now when it hasn't been; null when it can't be, too large for the atlas.
	static function glyphOf(font:Font, codepoint:Int, key:Int, bitmap:Bool):Null<Glyph> {
		if (atlas == null)
			start(FIRST);
		if (retired != null && Runtime.frames > retiredAt) {
			UnloadTexture(retired);
			retired = null;
		}
		var glyphs = made.get(font);
		if (glyphs == null)
			made.set(font, glyphs = new IntMap());
		var id = key << 21 | codepoint;
		var glyph = glyphs.get(id);
		if (glyph != null)
			return glyph;
		glyph = bitmap ? resampled(font, codepoint, key / 8) : rasterized(font, codepoint, key);
		if (glyph.width > 0 && !place(glyph)) {
			// Full: a larger atlas, or this one emptied, every glyph made again as it's drawn.
			if (glyph.width + GAP > LARGEST || glyph.height + GAP > LARGEST)
				return null;
			retired = atlas;
			retiredAt = Runtime.frames;
			start(atlasSize < LARGEST ? atlasSize * 2 : atlasSize);
			made.set(font, glyphs = new IntMap());
			place(glyph);
		}
		glyphs.set(id, glyph);
		return glyph;
	}

	// An empty atlas of a size: white, every texel clear, the glyphs' coverage its alpha.
	static function start(size:Int):Void {
		atlas = LoadTextureFromImage(GenImageColor(size, size, new Color(255, 255, 255, 0)));
		SetTextureFilter(atlas, TEXTURE_FILTER_BILINEAR);
		if (!restoring) {
			restoring = true;
			Runtime.restoring.push(restored);
		}
		atlasSize = size;
		rows = [];
		made = new ObjectMap();
		if (source == null) {
			source = new Rectangle(0, 0, 0, 0);
			dest = new Rectangle(0, 0, 0, 0);
			origin = new Vector2(0, 0);
		}
	}

	// Empties the atlas once the GPU's context is restored, its GPU copy gone: the next glyph drawn starts another.
	static function restored():Void {
		if (atlas != null)
			UnloadTexture(atlas);
		if (retired != null)
			UnloadTexture(retired);
		atlas = null;
		retired = null;
	}

	// Puts a glyph's coverage on the atlas: in the first row tall enough and not much taller, with room left, or a new row below the
	// last. False when there's no room.
	static function place(glyph:Glyph):Bool {
		var w = glyph.width + GAP, h = glyph.height + GAP;
		var at = -1, bottom = 0;
		var i = 0;
		while (i < rows.length) {
			var top = rows[i], height = rows[i + 1], x = rows[i + 2];
			bottom = top + height;
			if (at < 0 && height >= h && height <= h + (h >> 2) + 2 && x + w <= atlasSize)
				at = i;
			i += 3;
		}
		if (at < 0) {
			if (bottom + h > atlasSize || w > atlasSize)
				return false;
			rows.push(bottom);
			rows.push(h);
			rows.push(0);
			at = rows.length - 3;
		}
		glyph.x = rows[at + 2];
		glyph.y = rows[at];
		rows[at + 2] += w;
		var rgba = haxe.io.Bytes.alloc(glyph.width * glyph.height * 4);
		for (p in 0...glyph.width * glyph.height) {
			rgba.set(p * 4, 255);
			rgba.set(p * 4 + 1, 255);
			rgba.set(p * 4 + 2, 255);
			rgba.set(p * 4 + 3, glyph.coverage.get(p));
		}
		UpdateTextureRec(atlas, new Rectangle(glyph.x, glyph.y, glyph.width, glyph.height), rgba);
		glyph.coverage = null;
		return true;
	}

	// A TrueType or OpenType glyph rasterized at a line height, its offsets from the line's top as the font's own.
	static function rasterized(font:Font, codepoint:Int, size:Int):Glyph {
		var raster = Runtime.fonts().rasterizeOpened(font.opened, size, [codepoint]);
		var r = raster.glyphs[0];
		var glyph = new Glyph();
		if (!r.found || r.width == 0 || r.height == 0)
			return glyph;
		glyph.width = r.width;
		glyph.height = r.height;
		glyph.offsetX = r.offsetX;
		glyph.offsetY = r.offsetY + Std.int(raster.ascent);
		glyph.coverage = r.pixels;
		return glyph;
	}

	// A bitmap glyph of the default font at a scale, framebuffer pixels a texel: each pixel covered by the share of it its texels cover,
	// so every stroke is as heavy as every other, its edges soft where it ends part way through a pixel.
	static function resampled(font:Font, codepoint:Int, scale:Float):Glyph {
		var index = RText.GetGlyphIndex(font, codepoint);
		var rec = font.recs[index], image = font.glyphs[index].image;
		var glyph = new Glyph();
		var tw = Std.int(rec.width), th = Std.int(rec.height);
		if (image == null || image.data == null || tw == 0 || th == 0 || image.format != PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA)
			return glyph;
		var w = Math.ceil(tw * scale), h = Math.ceil(th * scale);
		var columns = weights(tw, w, scale), lines = weights(th, h, scale);
		var coverage = haxe.io.Bytes.alloc(w * h);
		for (py in 0...h)
			for (px in 0...w) {
				var sum = 0.;
				for (ty in 0...th) {
					var wy = lines[py * th + ty];
					if (wy == 0)
						continue;
					for (tx in 0...tw) {
						var wx = columns[px * tw + tx];
						if (wx != 0)
							sum += wx * wy * image.data.get((ty * image.width + tx) * 2 + 1);
					}
				}
				coverage.set(py * w + px, Std.int(Math.min(255, sum + 0.5)));
			}
		glyph.width = w;
		glyph.height = h;
		glyph.offsetX = font.glyphs[index].offsetX * scale;
		glyph.offsetY = font.glyphs[index].offsetY * scale;
		glyph.coverage = coverage;
		return glyph;
	}

	// How much of each of `pixels` pixels each of `texels` texels covers, a texel `scale` pixels wide: pixel p's share of texel t at
	// p * texels + t.
	static function weights(texels:Int, pixels:Int, scale:Float):Array<Float> {
		var out = [for (_ in 0...texels * pixels) 0.];
		for (p in 0...pixels)
			for (t in 0...texels) {
				var overlap = Math.min(p + 1, (t + 1) * scale) - Math.max(p, t * scale);
				if (overlap > 0)
					out[p * texels + t] = overlap;
			}
		return out;
	}
}

// A glyph on the atlas: its place, its size and offsets from the line's top in its own pixels, and its coverage until it's placed.

@:allow(helix.raylib.internal.ScreenText)
private class Glyph {
	var x = 0;
	var y = 0;
	var width = 0;
	var height = 0;
	var offsetX = 0.;
	var offsetY = 0.;
	var coverage:Null<haxe.io.Bytes>;

	function new() {}
}
