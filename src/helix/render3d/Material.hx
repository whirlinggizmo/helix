package helix.render3d;

import helix.render2d.Texture2D;

/** How a model's surface looks: glTF's metallic-roughness model. A base color (0xRRGGBBAA, its color sRGB-encoded as the convention's colors
	are; its alpha below 255 makes the surface see-through), an optional base color texture (sRGB) multiplying it, how metallic (0..1) and how
	rough (0..1) it is, an optional normal map (linear, tangent space, green up) and its strength, light it gives off (emissive), and
	whether lights shade it at all. Shared by any number of models: models alike in mesh and material draw
	together. */
class Material {
	static var nextId = 1;

	// Which one it is, for sorting alike draws together.
	@:allow(helix.render3d.Stage3D) var id = nextId++;

	var baseColor = 0xffffffff;
	var texture:Null<Texture2D>;
	var metallic = 0.;
	var roughness = .5;
	var lit = true;
	var normalTexture:Null<Texture2D>;
	var normalScale = 1.;
	var emissive = 0x000000ff;
	var emissiveStrength = 1.;

	/** White, not metallic, roughness 0.5, lit, untextured, giving off no light. */
	public function new() {}

	/** The base color, 0xRRGGBBAA. */
	public function getBaseColor():Int
		return baseColor;

	/** Sets the base color, 0xRRGGBBAA. */
	public function setBaseColor(color:Int):Void
		baseColor = color;

	/** The base color texture, or null for none (white). */
	public function getTexture():Null<Texture2D>
		return texture;

	/** Sets the base color texture; null for none. */
	public function setTexture(value:Null<Texture2D>):Void
		texture = value;

	/** How metallic, 0..1. */
	public function getMetallic():Float
		return metallic;

	/** False for a value outside 0..1. */
	public function setMetallic(value:Float):Bool {
		if (!(value >= 0 && value <= 1))
			return false;
		metallic = value;
		return true;
	}

	/** How rough, 0..1. */
	public function getRoughness():Float
		return roughness;

	/** False for a value outside 0..1. */
	public function setRoughness(value:Float):Bool {
		if (!(value >= 0 && value <= 1))
			return false;
		roughness = value;
		return true;
	}

	/** Whether lights shade it; unlit, it shows its color as it is. */
	public function isLit():Bool
		return lit;

	/** Lights shade it, or not. */
	public function setLit(value:Bool):Void
		lit = value;

	/** The normal map (linear, tangent space, green up), or null for none. */
	public function getNormalTexture():Null<Texture2D>
		return normalTexture;

	/** Sets the normal map; null for none. Load it linear (not sRGB), with mipmaps. */
	public function setNormalTexture(value:Null<Texture2D>):Void
		normalTexture = value;

	/** How strongly the normal map bends the surface: 1 as it is, 0 flat. */
	public function getNormalScale():Float
		return normalScale;

	/** False for a scale under 0. */
	public function setNormalScale(value:Float):Bool {
		if (!(value >= 0))
			return false;
		normalScale = value;
		return true;
	}

	/** The light it gives off, 0xRRGGBBAA (sRGB, alpha ignored); black for none. */
	public function getEmissive():Int
		return emissive;

	/** How bright its emissive light is: the color times this. */
	public function getEmissiveStrength():Float
		return emissiveStrength;

	/** Gives it light of its own, color (0xRRGGBBAA, sRGB) times strength, lit or not. False for a strength under 0. */
	public function setEmissive(color:Int, strength = 1.):Bool {
		if (!(strength >= 0))
			return false;
		emissive = color;
		emissiveStrength = strength;
		return true;
	}

	/** Whether it is see-through: its base color's alpha is below 255. */
	public function isBlended():Bool
		return baseColor & 255 < 255;
}
