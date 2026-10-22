package helix.shader;

import helix.graphics.Graphics;
import helix.graphics.SpriteEffect;
import helix.texture.Texture2D;

/** A sprite effect of the library: the sprite burnt away where a noise texture, laid across its region, is below a threshold rising with
	amount, with a glowing edge along the cut. The noise is the library's (ShaderLibrary.getNoise) unless the game gives its own. Shared by the
	sprites given it (SpriteEffect). Built on the program's GPU (Graphics) the first time one is made. */
class SpriteDissolve extends SpriteEffect {
	/** How much is burnt away, 0 (whole, by default) to 1 (gone). Clamped to 0..1 (NaN is 0). */
	public var amount(default, set):Float;

	function set_amount(value:Float):Float {
		value = value > 0 ? (value < 1 ? value : 1) : 0;
		amount = value;
		parameters.setFloat("amount", value);
		return value;
	}

	/** The edge's color, 0xAARRGGBB (sRGB, its alpha how much of it over the sprite's): orange by default. */
	public var edgeColor(default, set):Int;

	function set_edgeColor(value:Int):Int {
		edgeColor = value;
		parameters.setColor("edge_color", value);
		return value;
	}

	/** How wide the edge glows, in the noise's values (0..1) past the threshold, .001 to 1: .1 by default. Clamped to .001..1 (NaN is .001). */
	public var edgeWidth(default, set):Float;

	function set_edgeWidth(value:Float):Float {
		value = value > .001 ? (value < 1 ? value : 1) : .001;
		edgeWidth = value;
		parameters.setFloat("edge_width", value);
		return value;
	}

	/** How many times the noise repeats across the sprite's region, above 0: 1 by default. Under .001, or NaN, is .001. */
	public var scale(default, set):Float;

	function set_scale(value:Float):Float {
		value = value > .001 ? value : .001;
		scale = value;
		parameters.setFloat("scale", value);
		return value;
	}

	/** The noise it burns along (its red channel, sampled as its sampling says: repeating, for scale to tile it): the library's by default. */
	public var noise(default, set):Texture2D;

	function set_noise(value:Texture2D):Texture2D {
		noise = value;
		parameters.setTexture("dissolve_noise", value);
		return value;
	}

	/** Whole, an orange edge .1 wide, the library's noise once across. */
	public function new() {
		super(ShaderLibrary.get(Graphics.instance, "sprite_dissolve", SpriteDissolvePacked.text()));
		amount = 0;
		edgeColor = 0xffff7a1e;
		edgeWidth = .1;
		scale = 1;
		noise = ShaderLibrary.getNoise(Graphics.instance);
	}
}
