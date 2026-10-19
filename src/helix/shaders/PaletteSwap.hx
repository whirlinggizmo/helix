package helix.shaders;

import helix.graphics.SpriteEffect;
import helix.graphics.Graphics;
import helix.render2d.Texture2D;

/** A sprite effect of the library: the sprite drawn in a palette's colors. Its texels' red channel (0..255) is a column of the palette, a
	texture a row a variant (a game's PNG: the first row the colors as drawn, a row below for each swap), and row chooses which; the sprite's
	alpha is kept, times the palette's, and both are times the tint. The sprite and the palette are read texel by texel at exact texel centers,
	whatever either's sampling, so an index never blends with its neighbor; a red past the palette's width takes its last column. Shared by the
	sprites given it (SpriteEffect): a sprite of another variant has a PaletteSwap of its own. Built on the program's GPU (Graphics) the first
	time one is made. */
class PaletteSwap extends SpriteEffect {
	/** The palette: a column an index, a row a variant. */
	public var palette(default, set):Texture2D;

	function set_palette(value:Texture2D):Texture2D {
		palette = value;
		parameters.setTexture("palette", value);
		return value;
	}

	/** The palette's row drawn, 0 (its top, by default) or more; one past its last draws its last. Under 0 is 0. */
	public var row(default, set):Int;

	function set_row(value:Int):Int {
		value = value > 0 ? value : 0;
		row = value;
		parameters.setFloat("row", value);
		return value;
	}

	/** The sprite in palette's colors, its row row (0 by default). */
	public function new(palette:Texture2D, row = 0) {
		super(ShaderLibrary.get(Graphics.instance, "palette_swap", PaletteSwapPacked.text()));
		this.palette = palette;
		this.row = row;
	}
}
