package helix.render;

import helix.math.Vector2D;
import helix.services.fonts.Font2D;

/** Represents a font ready to draw: helix-services' `Font2D` with its atlas on the GPU.

	`Renderer.createFont` makes one, from a font helix-services' `Fonts` made; `Batch2D.drawText`,
	`Batch3D.drawText` and `TextLayout2D` use it; the program frees its atlas with `dispose`. A size is measured as the font's is, from its
	ascent to its descent; a font drawn at another size is scaled. Every kind of font is drawn by the batches' one shader, which reads
	a coverage or bitmap atlas's alpha as it is and makes a distance-field atlas's edge sharp at the size drawn (`fontKind`). */
class GpuFont2D {
	/** Gets the font: its metrics and glyphs. */
	public final font:Font2D;

	/** Gets its atlas, as a texture: white, each glyph's coverage or distance as alpha. */
	public final atlas:Texture2D;

	@:allow(helix.render)
	function new(font:Font2D, atlas:Texture2D) {
		this.font = font;
		this.atlas = atlas;
	}

	/** Gets the distance from one line's top to the next's at the font's size: its ascent, descent and line gap. */
	public var lineHeight(get, never):Float;

	function get_lineHeight():Float {
		throw "helix-render: GpuFont2D.get_lineHeight is not yet built (stage 1)";
	}

	/** Returns the size of text drawn on one line per line break, as `Batch2D.drawText` draws it.

		@param text  The text.
		@param size  Optional. The size it is drawn at; the font's own when omitted.
		@param letterSpacing  Optional. Space added after each character, as `drawText` adds it; defaults to 0.
		@param kerned  Optional. Whether pairs of characters are kerned as the font gives them, as `drawText`'s `kerned`; defaults to true.
		@param out  Optional. Set to the size; a new vector when omitted.
		@return  The width of its widest line as x, and its lines' height as y, in the units it is drawn in. */
	public function measureText(text:String, ?size:Float, letterSpacing = 0., kerned = true, ?out:Vector2D):Vector2D {
		throw "helix-render: GpuFont2D.measureText is not yet built (stage 1)";
	}

	/** Frees the atlas on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing. */
	public function dispose():Void {
		throw "helix-render: GpuFont2D.dispose is not yet built (stage 1)";
	}
}
