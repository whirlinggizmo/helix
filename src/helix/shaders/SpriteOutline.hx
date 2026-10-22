package helix.shaders;

import helix.graphics.Graphics;
import helix.graphics.SpriteEffect;

/** A sprite effect of the library: the sprite's shape outlined in a color, a width of texels out from its edge (eight reads around each pixel:
	the sides and the diagonals). The outline is drawn where the sprite's region is see-through, so a sprite needs that much transparent margin
	around its shape; what lies past its region in an atlas is never read. Shared by the sprites given it (SpriteEffect). Built on the
	program's GPU (Graphics) the first time one is made. */
class SpriteOutline extends SpriteEffect {
	/** The outline's color, 0xAARRGGBB (sRGB, its alpha how opaque), faded with each sprite's tint's alpha. */
	public var color(default, set):Int;

	function set_color(value:Int):Int {
		color = value;
		parameters.setColor("outline_color", value);
		return value;
	}

	/** How far it reaches out from the shape, in the sprite's texels, 0 (none) to 32. Clamped to 0..32 (NaN is 0). */
	public var width(default, set):Float;

	function set_width(value:Float):Float {
		value = value > 0 ? (value < 32 ? value : 32) : 0;
		width = value;
		parameters.setFloat("width", value);
		return value;
	}

	/** An outline of color (0xAARRGGBB, black by default) width texels wide (1 by default). */
	public function new(color = 0xff000000, width = 1.) {
		super(ShaderLibrary.get(Graphics.instance, "sprite_outline", SpriteOutlinePacked.text()));
		this.color = color;
		this.width = width;
	}
}
