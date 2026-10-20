package helix.shaders;

import helix.graphics.Graphics;
import helix.render2d.Texture2D;
import helix.render3d.Material;

/** A library surface shader: the material shaded as the stage shades it, burnt away where a noise texture is below a threshold rising with
	amount, with a glowing edge along the cut; its shadow is cut away with it. The noise is laid over the model at rest in its own space
	(helix_model_position: a skinned model's bind pose), read along the three planes of that space and blended by the surface's facing
	(triplanar), so the holes stay where they are on the body as it moves and animates, whatever its texture coordinates, and every GPU reads
	the same noise. The noise is the library's (ShaderLibrary.getNoise) unless the game gives its own. Made on a material, it is that
	material's surface shader from then on (LibrarySurface); make the material doubleSided to see its inside through the holes. */
class Dissolve extends LibrarySurface {
	/** How much is burnt away, 0 (whole, by default) to 1 (gone). Clamped to 0..1 (NaN is 0). */
	public var amount(default, set):Float;

	function set_amount(value:Float):Float {
		value = value > 0 ? (value < 1 ? value : 1) : 0;
		amount = value;
		writeFloat("amount", value);
		return value;
	}

	/** The glowing edge's color, 0xRRGGBBAA (sRGB): its alpha how much of the edge shows, what's behind the model through the rest (dithered:
		a share of its pixels thrown away in a fixed pattern, so the model stays opaque and its shadow alike); opaque orange by default. */
	public var edgeColor(default, set):Int;

	function set_edgeColor(value:Int):Int {
		edgeColor = value;
		writeLinear("edge_color", value, edgeIntensity);
		return value;
	}

	/** How bright the edge glows: its color times this, 0 or more (past 1 brighter than white light): 4 by default. Under 0, or NaN, is 0. */
	public var edgeIntensity(default, set):Float = 4.;

	function set_edgeIntensity(value:Float):Float {
		value = value > 0 ? value : 0;
		edgeIntensity = value;
		writeLinear("edge_color", edgeColor, value);
		return value;
	}

	/** How wide the edge glows, in the noise's values (0..1) past the threshold, .001 to 1: .08 by default. Clamped to .001..1 (NaN is .001). */
	public var edgeWidth(default, set):Float;

	function set_edgeWidth(value:Float):Float {
		value = value > .001 ? (value < 1 ? value : 1) : .001;
		edgeWidth = value;
		writeFloat("edge_width", value);
		return value;
	}

	/** How many times the noise repeats per unit of the model's own space (its mesh's, before the model's placing and scale), above 0: 1 by
		default, the library's noise's 8 cells across then each an eighth of a unit. Under .001, or NaN, is .001. */
	public var scale(default, set):Float;

	function set_scale(value:Float):Float {
		value = value > .001 ? value : .001;
		scale = value;
		writeFloat("scale", value);
		return value;
	}

	/** The noise it burns along (its red channel, sampled as its sampling says: repeating, for scale to tile it): the library's by default. */
	public var noise(default, set):Texture2D;

	function set_noise(value:Texture2D):Texture2D {
		noise = value;
		if (attached)
			material.shaderParameters.setTexture("dissolve_noise", value);
		return value;
	}

	/** Makes Dissolve material's surface shader: whole, an orange edge .08 wide, the library's noise repeating every unit. */
	public function new(material:Material) {
		super(material, "dissolve", DissolvePacked.text());
		amount = 0;
		edgeColor = 0xff7a1eff;
		edgeWidth = .08;
		scale = 1;
		noise = ShaderLibrary.getNoise(Graphics.instance);
	}
}
