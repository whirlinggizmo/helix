import helix.font.FontBaker;
import helix.font.TrueType;
import sys.io.File;

/** Bakes a TrueType font's printable ASCII into a signed distance field atlas with helix.font.FontBaker, for the built-in font; run under
	the interpreter by tools/bake_fonts.py.

	usage: haxe -cp src -cp tools/bake_fonts -main FontBake --run FontBake <font.ttf> <pixel height> <padding> <atlas width> <out.r8> <out.json>

	out.r8 holds one byte a texel, row by row (its last texel fully inside: the white texel); out.json the atlas size and, per glyph, its place
	in the atlas, its offset from the pen on the baseline, and its advance, in pixels at the baked height. */
@:access(helix)
class FontBake {
	static function main():Void {
		var args = Sys.args();
		if (args.length != 6) {
			Sys.println("usage: FontBake <font.ttf> <pixel height> <padding> <atlas width> <out.r8> <out.json>");
			Sys.exit(2);
		}
		var font = new TrueType(File.getBytes(args[0]));
		var baked = FontBaker.bake(font, [for (c in 32...127) c], Std.parseFloat(args[1]), Std.parseInt(args[2]), Std.parseInt(args[3]));
		File.saveBytes(args[4], baked.field);
		File.saveContent(args[5], haxe.Json.stringify({
			pixelHeight: baked.pixelHeight,
			padding: Std.parseInt(args[2]),
			onEdge: 128,
			width: baked.width,
			height: baked.height,
			ascent: baked.ascent,
			descent: baked.descent,
			lineGap: baked.lineGap,
			first: 32,
			glyphs: [for (g in baked.glyphs) [g.x, g.y, g.width, g.height, g.xOffset, g.yOffset, g.advance]]
		}));
	}
}
