package helix.services.fonts;

import haxe.io.Bytes;
import helix.formats.bmfont.BmFontFile;
import helix.formats.text.Utf8Text;
import helix.formats.truetype.TrueTypeTables;
import helix.log.Log;
import helix.math.RectPacker2D;
import helix.platform.IFontRasterizer;
import helix.platform.RasterGlyph;
import helix.services.assets.Assets;
import helix.services.images.Image;
import helix.services.images.Images;

/** Provides fonts by path: a TrueType or OpenType font rasterized at a size as coverage (`load`), hard-edged (`loadBitmap`) or signed
	distances (`loadDistanceField`), or a BMFont's .fnt and its images (`loadBmFont`), each as a `Font2D` with its glyphs on one atlas. A
	TrueType font's glyphs also come from its bytes, each on its own, for a program that places them itself (`rasterize`,
	`rasterizeBitmap`, `rasterizeDistanceField`). Each kind is its own call, so a program carries only the rasterizing it asks for. A
	font's kerning pairs come with it: a TrueType font's between the characters asked for, a BMFont's from its .fnt. A program or an
	engine layer holding glyph images of its own makes a font of them with `packFont`.

	A TrueType font's glyphs are rasterized by the platform (`IFontRasterizer`) and packed onto an atlas as `FontsOptions` says. Its
	answers come as the assets, images and rasterizer it uses are polled.

	```haxe
	var fonts = new Fonts(rasterizer, assets, images);
	fonts.load("ui.ttf", 24, [for (c in 32...127) c], font -> ui = font);
	``` */
class Fonts {
	final rasterizer:IFontRasterizer;
	final assets:Assets;
	final images:Images;
	final options:FontsOptions;

	/** Creates the fonts over the platform's rasterizer, the assets fonts are found in, and the images a BMFont's are decoded by.

		@param rasterizer  The platform's font rasterizer.
		@param assets  The assets the files are read through.
		@param images  The images a BMFont's pages are decoded by.
		@param options  Optional. How the atlas is made. Defaults to a texel of padding, packed as a skyline. */
	public function new(rasterizer:IFontRasterizer, assets:Assets, images:Images, ?options:FontsOptions) {
		this.rasterizer = rasterizer;
		this.assets = assets;
		this.images = images;
		this.options = options != null ? options : {};
	}

	/** Loads a TrueType or OpenType font and rasterizes its glyphs at a size onto one atlas, as antialiased coverage (`FontKind.Coverage`).

		One of `loaded` or `failed` is called once, at a later poll, never during this call.
		@param path  The file, as the assets name it.
		@param size  The pixel height: the font's ascent to its descent.
		@param codepoints  The characters wanted; one the font lacks has no glyph.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
		@return  A function that aborts the load; neither callback is called after it, and once one was, it does nothing. */
	public function load(path:String, size:Float, codepoints:Array<Int>, loaded:Font2D->Void, ?failed:String->Void):Void->Void
		return loadWith(rasterize, Coverage, path, size, codepoints, loaded, failed);

	/** Loads a TrueType or OpenType font as `load` does, its glyphs' coverage made hard-edged (`FontKind.Bitmap`), for pixel fonts drawn
		at their own size.

		@param path  The file, as the assets name it.
		@param size  The pixel height: the font's ascent to its descent.
		@param codepoints  The characters wanted; one the font lacks has no glyph.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
		@return  A function that aborts the load; neither callback is called after it, and once one was, it does nothing. */
	public function loadBitmap(path:String, size:Float, codepoints:Array<Int>, loaded:Font2D->Void, ?failed:String->Void):Void->Void
		return loadWith(rasterizeBitmap, Bitmap, path, size, codepoints, loaded, failed);

	/** Loads a TrueType or OpenType font as `load` does, its glyphs signed distances to their outlines (`FontKind.Distance`), sharp at
		any size through a distance-field shader.

		@param path  The file, as the assets name it.
		@param size  The pixel height: the font's ascent to its descent.
		@param codepoints  The characters wanted; one the font lacks has no glyph.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
		@return  A function that aborts the load; neither callback is called after it, and once one was, it does nothing. */
	public function loadDistanceField(path:String, size:Float, codepoints:Array<Int>, loaded:Font2D->Void, ?failed:String->Void):Void->Void
		return loadWith(rasterizeDistanceField, Distance, path, size, codepoints, loaded, failed);

	/** Rasterizes a TrueType or OpenType font's glyphs from the file's bytes as antialiased coverage, each on its own, for a program that
		places them itself: on an atlas of its own, or one image each. `load` makes a font of them on one atlas.

		One of `rasterized` or `failed` is called once, at a later poll, never during this call.
		@param encoded  The font file's bytes, TTF or OTF.
		@param size  The pixel height: the font's ascent to its descent.
		@param codepoints  The characters wanted.
		@param rasterized  Receives a glyph for each codepoint, in their order (one the font lacks isn't `found`, and is empty), and the
			font's ascent, descent (below the baseline, negative) and line gap, in pixels.
		@param failed  Optional. Receives why the font can't be read. When omitted, the failure is logged.
		@return  A function that aborts it; neither callback is called after it, and once one was, it does nothing. */
	public function rasterize(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, ?failed:String->Void):Void->Void {
		var aborted = false;
		rasterizer.rasterize(encoded, size, codepoints, (glyphs, ascent, descent, lineGap) -> if (!aborted) rasterized(glyphs, ascent, descent, lineGap),
			message -> if (!aborted) fail(failed, message));
		return () -> aborted = true;
	}

	/** Rasterizes glyphs as `rasterize` does, their coverage made hard-edged: each texel covered or not.

		@param encoded  The font file's bytes, TTF or OTF.
		@param size  The pixel height: the font's ascent to its descent.
		@param codepoints  The characters wanted.
		@param rasterized  Receives a glyph for each codepoint, in their order, and the font's ascent, descent and line gap.
		@param failed  Optional. Receives why the font can't be read. When omitted, the failure is logged.
		@return  A function that aborts it; neither callback is called after it, and once one was, it does nothing. */
	public function rasterizeBitmap(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, ?failed:String->Void):Void->Void {
		return rasterize(encoded, size, codepoints, (glyphs, ascent, descent, lineGap) -> {
			for (g in glyphs)
				for (i in 0...g.pixels.length)
					g.pixels.set(i, g.pixels.get(i) < 80 ? 0 : 255);
			rasterized(glyphs, ascent, descent, lineGap);
		}, failed);
	}

	/** Rasterizes glyphs as signed distances to their outlines (`IFontRasterizer.rasterizeDistanceField`): 128 on the outline, 64 a
		texel, with 4 texels of padding around each glyph.

		@param encoded  The font file's bytes, TTF or OTF.
		@param size  The pixel height: the font's ascent to its descent.
		@param codepoints  The characters wanted.
		@param rasterized  Receives a glyph for each codepoint, in their order, and the font's ascent, descent and line gap.
		@param failed  Optional. Receives why the font can't be read. When omitted, the failure is logged.
		@return  A function that aborts it; neither callback is called after it, and once one was, it does nothing. */
	public function rasterizeDistanceField(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, ?failed:String->Void):Void->Void {
		var aborted = false;
		rasterizer.rasterizeDistanceField(encoded, size, codepoints,
			(glyphs, ascent, descent, lineGap) -> if (!aborted) rasterized(glyphs, ascent, descent, lineGap), message -> if (!aborted) fail(failed, message));
		return () -> aborted = true;
	}

	// A font loaded and rasterized by one of the rasterize calls, packed onto one atlas.
	function loadWith(raster:(Bytes, Float, Array<Int>, (Array<RasterGlyph>, Float, Float, Float) -> Void, ? (String->Void)) -> (Void->Void), kind:FontKind,
			path:String, size:Float, codepoints:Array<Int>, loaded:Font2D->Void, failed:Null<String->Void>):Void->Void {
		var aborted = false, abortRasterize:Null<Void->Void> = null;
		var report = (message:String) -> if (!aborted) fail(failed, message);
		var abortLoad = assets.load(path, bytes -> {
			if (aborted)
				return;
			abortRasterize = raster(bytes, size, codepoints, (glyphs, ascent, descent, lineGap) -> {
				var found = [for (g in glyphs) if (g.found) g];
				loaded(packFont(path, kind, size, ascent, descent, lineGap, found, kerningsOf(bytes, size, found)));
			}, message -> report('$path: $message'));
		}, report);
		return () -> {
			aborted = true;
			abortLoad();
			if (abortRasterize != null)
				abortRasterize();
		};
	}

	/** Loads a BMFont: its .fnt (the text format) and its pages, stacked top to bottom onto one atlas. A page with no transparency whose
		texels are gray is coverage, so it becomes white with the gray as alpha, as raylib takes it.

		One of `loaded` or `failed` is called once, at a later poll, never during this call.
		@param path  The .fnt file, as the assets name it.
		@param loaded  Receives the font: its size the .fnt's line height, its ascent its base.
		@param failed  Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
		@return  A function that aborts the load; neither callback is called after it, and once one was, it does nothing. */
	public function loadBmFont(path:String, loaded:Font2D->Void, ?failed:String->Void):Void->Void {
		var aborted = false, finished = false, aborts:Array<Void->Void> = [];
		var report = (message:String) -> {
			if (aborted || finished)
				return;
			finished = true;
			for (abort in aborts)
				abort();
			fail(failed, message);
		};
		aborts.push(assets.load(path, bytes -> {
			if (aborted)
				return;
			// Replacing, not refusing: a face name in a system's 8-bit encoding needn't refuse the font, and a binary BMFont file
			// still starts "BMF", which the reader names.
			var file = try BmFontFile.read(Utf8Text.decodeReplacing(bytes), path) catch (e:String) {
				report('$path: $e');
				return;
			}
			var pages:Array<Null<Image>> = [for (_ in file.pages) null],
				left = file.pages.length;
			for (i in 0...file.pages.length)
				aborts.push(images.load(file.pages[i].path, image -> {
					pages[i] = image;
					if (--left == 0 && !aborted && !finished) {
						finished = true;
						loaded(stacked(file, pages));
					}
				}, report));
		}, report));
		return () -> {
			aborted = true;
			for (abort in aborts)
				abort();
		};
	}

	/** Returns a font made of glyph images, packed onto one atlas as `FontsOptions` says, as `load` packs a TrueType font's: the smallest
		power-of-two square they fit, white, each glyph's image as alpha. For a program or an engine layer holding a font's glyphs of its
		own (raylib's default font, the glyphs `rasterize` gives).

		@param name  The atlas's name, its image's `path`; "" for none.
		@param kind  What the glyphs hold.
		@param size  The pixel height of a line from its ascent to its descent.
		@param ascent  How far the tallest glyphs rise above the baseline, in pixels.
		@param descent  How far the lowest fall below it, in pixels, negative.
		@param lineGap  The space between one line's descent and the next line's ascent, in pixels.
		@param glyphs  Each glyph's image, `width * height` bytes, its place from the pen and its advance.
		@param kernings  Optional. The kerning pairs; none when omitted.
		@return  The font, its glyphs in the order given. */
	public function packFont(name:String, kind:FontKind, size:Float, ascent:Float, descent:Float, lineGap:Float, glyphs:Array<RasterGlyph>,
			?kernings:Array<Kerning2D>):Font2D {
		var padding = options.padding,
			lineHeight = Math.ceil(size) + 2 * padding;
		var area = 0;
		for (g in glyphs)
			area += (g.width + 2 * padding) * (g.height + 2 * padding);
		var width = 16;
		while (width * width < area)
			width *= 2;
		var places = place(glyphs, width, width, padding, lineHeight);
		while (places == null) {
			width *= 2;
			places = place(glyphs, width, width, padding, lineHeight);
		}
		var pixels = Bytes.alloc(width * width * 4);
		for (i in 0...width * width) {
			pixels.set(i * 4, 255);
			pixels.set(i * 4 + 1, 255);
			pixels.set(i * 4 + 2, 255);
		}
		var made = [];
		for (i in 0...glyphs.length) {
			var g = glyphs[i], x = places[i * 2], y = places[i * 2 + 1];
			for (row in 0...g.height)
				for (column in 0...g.width)
					pixels.set(((y + row) * width + x + column) * 4 + 3, g.pixels.get(row * g.width + column));
			made.push(new Glyph2D(g.codepoint, x, y, g.width, g.height, g.offsetX, g.offsetY, g.advance));
		}
		return new Font2D(kind, size, ascent, descent, lineGap, new Image(name, width, width, pixels), made, kernings);
	}

	// A TrueType font's kerning pairs between the glyphs given, in pixels at a size, as stb_truetype reads them: none for a font it
	// can't read or without kerning.
	static function kerningsOf(encoded:Bytes, size:Float, glyphs:Array<RasterGlyph>):Array<Kerning2D> {
		var tables = try new TrueTypeTables(encoded) catch (_:Dynamic) null;
		if (tables == null || !tables.hasKerning)
			return [];
		var scale = tables.scaleFor(size), out:Array<Kerning2D> = [];
		var indices = [for (g in glyphs) tables.glyphIndex(g.codepoint)];
		for (i in 0...glyphs.length)
			if (tables.canKern(indices[i]))
				for (j in 0...glyphs.length) {
					var amount = tables.kerning(indices[i], indices[j]);
					if (amount != 0)
						out.push({first: glyphs[i].codepoint, second: glyphs[j].codepoint, amount: amount * scale});
				}
		return out;
	}

	// Each glyph's top-left on a width by height atlas, x then y, or null when they don't all fit.
	function place(glyphs:Array<RasterGlyph>, width:Int, height:Int, padding:Int, lineHeight:Int):Null<Array<Int>> {
		var out = [];
		if (options.packing == Skyline) {
			var sizes = [];
			for (g in glyphs) {
				sizes.push(g.width + 2 * padding);
				sizes.push(g.height + 2 * padding);
			}
			var places = RectPacker2D.pack(width, height, sizes);
			for (i in 0...glyphs.length) {
				if (places[i * 3 + 2] == 0)
					return null;
				out.push(places[i * 3] + padding);
				out.push(places[i * 3 + 1] + padding);
			}
			return out;
		}
		var x = padding, y = padding;
		for (g in glyphs) {
			if (x + g.width + padding > width) {
				x = padding;
				y += lineHeight;
			}
			if (y + g.height + padding > height || g.width + 2 * padding > width)
				return null;
			out.push(x);
			out.push(y);
			x += g.width + 2 * padding;
		}
		return out;
	}

	// A BMFont's pages stacked onto one atlas, top to bottom, and its characters as glyphs on it.
	static function stacked(file:BmFontFile, pages:Array<Null<Image>>):Font2D {
		var width = file.scaleWidth, pageHeight = file.scaleHeight;
		for (page in pages)
			if (page.width > width)
				width = page.width;
		var height = pageHeight * pages.length,
			pixels = Bytes.alloc(width * height * 4);
		for (p in 0...pages.length) {
			var page = pages[p], gray = isGray(page);
			for (y in 0...page.height)
				for (x in 0...page.width) {
					if (p * pageHeight + y >= height)
						continue;
					var from = (y * page.width + x) * 4,
						to = ((p * pageHeight + y) * width + x) * 4;
					if (gray) {
						pixels.set(to, 255);
						pixels.set(to + 1, 255);
						pixels.set(to + 2, 255);
						pixels.set(to + 3, page.pixels.get(from));
					} else
						pixels.blit(to, page.pixels, from, 4);
				}
		}
		var glyphs = [
			for (c in file.chars)
				new Glyph2D(c.id, c.x, c.y + pageHeight * c.page, c.width, c.height, c.xOffset, c.yOffset - file.base, c.xAdvance)
		];
		var notdef = [for (g in glyphs) if (g.codepoint == -1) g][0];
		// The .fnt's pairs as they are: a BmFontKerning has a Kerning2D's fields, its amount a whole number of pixels.
		return new Font2D(Coverage, file.lineHeight, file.base, file.base - file.lineHeight, 0, new Image(file.pages[0].path, width, height, pixels), glyphs,
			cast file.kernings, notdef);
	}

	// Whether an image is coverage drawn in gray: opaque everywhere, and gray everywhere.
	static function isGray(image:Image):Bool {
		var p = image.pixels;
		for (i in 0...image.width * image.height)
			if (p.get(i * 4 + 3) != 255 || p.get(i * 4) != p.get(i * 4 + 1) || p.get(i * 4) != p.get(i * 4 + 2))
				return false;
		return true;
	}

	static function fail(failed:Null<String->Void>, message:String):Void {
		if (failed != null)
			failed(message);
		else
			Log.warn(message, "fonts");
	}
}
