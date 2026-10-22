package helix.shader;

import haxe.io.Bytes;
import helix.texture.Texture2D;

/** A color grade, a screen effect of the library: the frame's colors looked up in a 32 x 32 x 32 color cube (a LUT) laid out as a strip of
	SIZE squares, 1024 x 32 texels: blue chooses a square left to right, red runs across it, green down it, and each texel holds what that
	color becomes (sRGB). A grade is made by grading identity()'s strip in an image editor with the game's look and loading the PNG (linear
	sampling; Textures.load). Put it after the tone mapping, as the colors it grades are the screen's. */
class ColorLut extends LibraryScreenEffect {
	/** The cube's size: SIZE values of each channel, so the strip is SIZE * SIZE x SIZE texels. */
	public static inline var SIZE = 32;

	/** A grade through lut (a strip as above, sampled linear), or the identity strip until a lut is given. */
	public function new(?lut:Texture2D) {
		super("color_lut", ColorLutPacked.text());
		this.lut = lut;
		amount = 1;
	}

	/** The strip it looks colors up in, or null for the identity (the library's, ShaderLibrary.getIdentityLut: the frame unchanged). The texture
		stays its owner's. */
	public var lut(default, set):Null<Texture2D>;

	function set_lut(value:Null<Texture2D>):Null<Texture2D> {
		parameters.setTexture("lut_texture", value != null ? value : ShaderLibrary.getIdentityLut(gpu));
		return lut = value;
	}

	/** How much of the grade shows, 0 (the frame as it is) to 1 (all of it): 1 by default. */
	public var amount(default, set):Float;

	function set_amount(value:Float):Float
		return amount = writeFloat("amount", value, 0, 1);

	/** The identity strip's texels, RGBA8, rows top first (SIZE * SIZE x SIZE): each color itself, its channels i * 255 / 31 rounded. */
	public static function identity():Bytes {
		var width = SIZE * SIZE, pixels = Bytes.alloc(width * SIZE * 4);
		inline function level(i:Int):Int
			return Std.int(i * 255 / (SIZE - 1) + .5);
		for (g in 0...SIZE)
			for (x in 0...width) {
				var at = (g * width + x) * 4;
				pixels.set(at, level(x % SIZE));
				pixels.set(at + 1, level(g));
				pixels.set(at + 2, level(Std.int(x / SIZE)));
				pixels.set(at + 3, 255);
			}
		return pixels;
	}
}
