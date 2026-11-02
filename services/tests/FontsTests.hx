import haxe.io.Bytes;
import helix.services.assets.Assets;
import helix.services.fonts.Font2D;
import helix.services.fonts.Fonts;
import helix.services.images.Images;

/** Checks Fonts over fakes: a font's glyphs rasterized, a character it lacks left out, placed apart on a power-of-two atlas (skyline and
	rows), their coverage as the atlas's alpha on white, and their offsets and advances kept; hard-edged glyphs; a file that isn't a font
	failing; a BMFont's pages stacked onto one atlas, its characters' places on it, offsets from the baseline, its invalid-character glyph
	its .notdef, and a binary BMFont failing; and glyphs rasterized from a
	font's bytes, each on its own, as coverage, hard-edged or signed distances, aborted, or failing. */
class FontsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var files = new FakeFileSystem();
		files.files.set("ui.ttf", Bytes.ofString("font"));
		files.files.set("bad.ttf", Bytes.ofString("junk"));
		files.files.set("fonts/pixel.fnt",
			Bytes.ofString('info face="Pixel" size=8\ncommon lineHeight=10 base=8 scaleW=4 scaleH=4 pages=2\npage id=0 file="pixel_0.png"\npage id=1 file="pixel_1.png"\nchars count=3\nchar id=-1 x=0 y=0 width=2 height=3 xoffset=0 yoffset=3 xadvance=3 page=0 chnl=15\nchar id=65 x=0 y=0 width=3 height=4 xoffset=1 yoffset=2 xadvance=4 page=0 chnl=15\nchar id=66 x=1 y=1 width=2 height=2 xoffset=0 yoffset=3 xadvance=3 page=1 chnl=15\n'));
		files.files.set("fonts/pixel_0.png", Bytes.ofString("4x4"));
		files.files.set("fonts/pixel_1.png", Bytes.ofString("4x4"));
		var rasterizer = new FakeFontRasterizer(),
			decoder = new FakeImageDecoder();
		var assets = new Assets({sources: [FileSystem(files)]});
		var images = new Images(decoder, assets);
		function pump()
			for (_ in 0...8) {
				files.poll();
				rasterizer.poll();
				decoder.poll();
				images.poll();
			}
		function apart(font:Font2D):Bool {
			for (a in font.glyphs)
				for (b in font.glyphs)
					if (a != b && a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height)
						return false;
			return true;
		}

		for (packing in [helix.services.fonts.FontPacking.Skyline, helix.services.fonts.FontPacking.Rows]) {
			var fonts = new Fonts(rasterizer, assets, images, {padding: 1, packing: packing}),
				font:Font2D = null;
			fonts.load("ui.ttf", 8, [65, 0x4E00, 66, 67], f -> font = f);
			check(font == null, '$packing: not answered during the call');
			pump();
			check(font != null && font.glyphs.length == 3 && font.getGlyph(0x4E00) == null, '$packing: a character the font lacks has no glyph');
			check(font.size == 8 && font.ascent == 6 && font.descent == -2, '$packing: the metrics');
			var w = font.atlas.width;
			check(w == font.atlas.height && w & (w - 1) == 0 && w >= 8, '$packing: a power-of-two atlas');
			var c = font.getGlyph(67);
			check(c.width == 4 && c.height == 8 && c.offsetX == 1 && c.offsetY == -8 && c.advance == 5, '$packing: a glyph\'s size, offsets, advance');
			check(apart(font), '$packing: glyphs placed apart');
			var at = (c.y * w + c.x) * 4;
			check(font.atlas.pixels.get(at) == 255 && font.atlas.pixels.get(at + 3) == 100, '$packing: coverage as alpha on white');
		}

		var hard:Font2D = null;
		new Fonts(rasterizer, assets, images).loadBitmap("ui.ttf", 4, [65], f -> hard = f);
		pump();
		var a = hard.getGlyph(65);
		check(hard.atlas.pixels.get((a.y * hard.atlas.width + a.x) * 4 + 3) == 255, "hard-edged: coverage over 80 is full");

		var why = "";
		new Fonts(rasterizer, assets, images).load("bad.ttf", 8, [65], _ -> throw "loaded what isn't a font", m -> why = m);
		pump();
		check(why.indexOf("bad.ttf") >= 0, "what isn't a font fails, by name");

		var pixel:Font2D = null;
		new Fonts(rasterizer, assets, images).loadBmFont("fonts/pixel.fnt", f -> pixel = f);
		pump();
		check(pixel != null && pixel.atlas.width == 4 && pixel.atlas.height == 8, "a BMFont's two pages stacked onto one atlas");
		var b = pixel.getGlyph(66);
		check(b.x == 1 && b.y == 5 && b.offsetY == -5 && b.advance == 3, "a character on the second page: below the first, offset from the baseline");
		check(pixel.size == 10 && pixel.ascent == 8 && pixel.descent == -2, "its size its line height, its ascent its base");
		check(pixel.notdef != null && pixel.notdef.codepoint == -1 && pixel.notdef.advance == 3 && hard.notdef == null,
			"a BMFont's invalid-character glyph (-1) its .notdef; a TrueType font's none");
		// BMFont's binary format, its header bytes that aren't UTF-8 (a browser's toString throws a RangeError for them).
		files.files.set("fonts/binary.fnt", Bytes.ofHex("424d4603010e000000f4908080"));
		why = "";
		new Fonts(rasterizer, assets, images).loadBmFont("fonts/binary.fnt", _ -> throw "loaded a binary BMFont", m -> why = m);
		pump();
		check(why.indexOf("fonts/binary.fnt") >= 0 && why.indexOf("binary BMFont") >= 0, "a binary BMFont file fails, by name: " + why);
		var fonts = new Fonts(rasterizer, assets, images), raster:Array<helix.platform.RasterGlyph> = null, metrics = [];
		fonts.rasterize(Bytes.ofString("font"), 8, [65, 0x4E00, 66], (glyphs, ascent, descent, lineGap) -> {
			raster = glyphs;
			metrics = [ascent, descent, lineGap];
		});
		check(raster == null && !rasterizer.sdf, "rasterized from bytes: not answered during the call, as coverage");
		pump();
		check(raster != null && raster.length == 3 && raster[1].codepoint == 0x4E00 && !raster[1].found && raster[2].codepoint == 66,
			"rasterized from bytes: a glyph for each character, in order, one the font lacks not found");
		check(raster[2].width == 3
			&& raster[2].height == 8
			&& raster[2].offsetX == 1
			&& raster[2].offsetY == -8
			&& raster[2].advance == 4,
			"rasterized from bytes: a glyph's size, offsets, advance");
		check(raster[2].pixels.get(0) == 100 && raster[2].pixels.get(23) == 50, "rasterized from bytes: coverage as it is");
		check(metrics[0] == 6 && metrics[1] == -2 && metrics[2] == 0, "rasterized from bytes: the metrics");

		var bitmap:Array<helix.platform.RasterGlyph> = null;
		fonts.rasterizeBitmap(Bytes.ofString("font"), 4, [65, 66], (glyphs, _, _, _) -> bitmap = glyphs);
		pump();
		check(bitmap[1].pixels.get(0) == 255 && bitmap[1].pixels.get(7) == 0, "hard-edged from bytes: coverage under 80 is none, the rest full");

		var distances = false;
		fonts.rasterizeDistanceField(Bytes.ofString("font"), 4, [65], (_, _, _, _) -> distances = true);
		check(rasterizer.sdf, "signed distances asked of the platform");
		pump();
		check(distances, "signed distances rasterized");

		var aborted = false;
		fonts.rasterize(Bytes.ofString("font"), 4, [65], (_, _, _, _) -> aborted = true, _ -> aborted = true)();
		pump();
		check(!aborted, "an aborted rasterize calls nothing");

		var refused = "";
		fonts.rasterize(Bytes.ofString("junk"), 4, [65], (_, _, _, _) -> throw "rasterized what isn't a font", m -> refused = m);
		pump();
		check(refused == "not a font", "what isn't a font fails");

		var abortedLoad = false;
		fonts.load("ui.ttf", 4, [65], _ -> abortedLoad = true, _ -> abortedLoad = true)();
		pump();
		check(!abortedLoad, "an aborted load calls nothing");

		var distance:helix.services.fonts.FontKind = Distance,
			fit:helix.services.screen.ScreenFit = PixelPerfect;
		check('$distance $fit' == "Distance PixelPerfect", "the enums print as their names: $distance $fit");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
