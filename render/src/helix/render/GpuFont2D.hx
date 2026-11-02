package helix.render;

import helix.log.Log;
import helix.math.Vector2D;
import helix.services.fonts.Font2D;
import helix.services.fonts.Glyph2D;

/** Represents a font ready to draw: helix-services' `Font2D` with its atlas on the GPU.

	`Renderer.createFont` makes one, from a font helix-services' `Fonts` made; `Batch2D.drawText`,
	`Batch3D.drawText` and `TextLayout2D` use it; the program frees its atlas with `dispose`. A size is measured as the font's is, from its
	ascent to its descent; a font drawn at another size is scaled. Each batch's default shader draws its atlas's alpha as it is
	stored; a distance-field atlas's sharp edge, at any size, comes with the font's kind (helix-services' `Font2D.kind`, asked for), as a
	shader variant only a program drawing such a font carries. A program's shader is given the kind as `fontKind`.

	A character the font lacks is drawn, and measured, as the font's `?`, or else as its .notdef (`Font2D.notdef`), and skipped when it
	has neither, as raylib draws one; the first time each such character is met in a font, a warning is logged (helix-log, tag
	"render"). A control character the font lacks (a tab, a carriage return) is skipped, unwarned. */
class GpuFont2D {
	/** Gets the font: its metrics and glyphs. */
	public final font:Font2D;

	/** Gets its atlas, as a texture: white, each glyph's coverage or distance as alpha. */
	public final atlas:Texture2D;

	// The characters the font lacks that have been warned of.
	var warned:Null<Map<Int, Bool>> = null;

	@:allow(helix.render)
	function new(font:Font2D, atlas:Texture2D) {
		this.font = font;
		this.atlas = atlas;
	}

	/** Gets the distance from one line's top to the next's at the font's size: its ascent, descent and line gap. */
	public var lineHeight(get, never):Float;

	function get_lineHeight():Float {
		return font.ascent - font.descent + font.lineGap;
	}

	/** Returns the size of text drawn on one line per line break, as `Batch2D.drawText` draws it.

		@param text  The text.
		@param size  Optional. The size it is drawn at; the font's own when omitted.
		@param letterSpacing  Optional. Space added after each character, as `drawText` adds it; defaults to 0.
		@param kerned  Optional. Whether pairs of characters are kerned as the font gives them, as `drawText`'s `kerned`; defaults to true.
		@param out  Optional. Set to the size; a new vector when omitted.
		@return  The width of its widest line as x, and its lines' height as y, in the units it is drawn in. */
	public function measureText(text:String, ?size:Float, letterSpacing = 0., kerned = true, ?out:Vector2D):Vector2D {
		if (out == null)
			out = new Vector2D();
		var scale = scaleOf(size), widest = 0., lines = 0;
		for (line in text.split("\n")) {
			widest = Math.max(widest, widthOf(codes(line), scale, letterSpacing));
			lines++;
		}
		return out.set(widest, heightOf(lines, scale, 1));
	}

	/** Frees the atlas on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing. */
	public function dispose():Void {
		if (atlas.disposed)
			return;
		atlas.dispose();
		if (atlas.renderer != null)
			atlas.renderer.forget(this);
	}

	// The scale a size draws at: the size over the font's own.

	@:allow(helix.render)
	function scaleOf(size:Null<Float>):Float
		return size == null || font.size <= 0 ? 1 : size / font.size;

	// A string's characters.

	@:allow(helix.render)
	static function codes(text:String):Array<Int>
		return [for (c in new haxe.iterators.StringIteratorUnicode(text)) c];

	// The glyph a character is drawn with: its own; for one the font lacks its '?', else its .notdef, warned of once; null for none,
	// and for a control character it lacks.

	@:allow(helix.render)
	function glyphFor(code:Int):Null<Glyph2D> {
		var g = font.getGlyph(code);
		if (g != null || code < 0x20 || (code >= 0x7F && code < 0xA0))
			return g;
		var stand = font.getGlyph("?".code), drawn = '"?"';
		if (stand == null) {
			stand = font.notdef;
			drawn = stand == null ? "nothing" : "its .notdef";
		}
		if (warned == null)
			warned = [];
		if (!warned.exists(code)) {
			warned.set(code, true);
			var named = font.atlas.path == "" ? "a font" : font.atlas.path;
			Log.warn('$named lacks U+${StringTools.hex(code, 4)} ("${String.fromCharCode(code)}"), drawn as $drawn', "render");
		}
		return stand;
	}

	// The width of characters on one line at a scale: each one's advance and the spacing after it but the last; one the font lacks as
	// its stand-in (glyphFor).

	@:allow(helix.render)
	function widthOf(line:Array<Int>, scale:Float, spacing:Float, from = 0, ?to:Int):Float {
		var end = to == null ? line.length : to, width = 0., any = false;
		for (i in from...end) {
			var g = glyphFor(line[i]);
			if (g == null)
				continue;
			width += g.advance * scale + spacing;
			any = true;
		}
		return any ? width - spacing : 0;
	}

	// The height of lines: one line's ascent to descent, and a line height times the spacing for each after it.

	@:allow(helix.render)
	function heightOf(lines:Int, scale:Float, spacing:Float):Float
		return lines <= 0 ? 0 : ((lines - 1) * lineHeight * spacing + font.ascent - font.descent) * scale;
}
