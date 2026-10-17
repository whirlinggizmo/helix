package helix.render3d;

import helix.graphics.Shader;
import helix.graphics.ShaderParameters;
import helix.render2d.Texture2D;

/** How a model's surface looks: glTF's metallic-roughness model. A base color (0xRRGGBBAA, its color sRGB-encoded as the convention's colors
	are; its alpha below 255 makes the surface see-through), an optional base color texture (sRGB) multiplying it, how metallic (0..1) and how
	rough (0..1) it is, an optional normal map (linear, tangent space, green up) and its strength, light it gives off (emissive), and
	whether lights shade it at all. Shared by any number of models: models alike in mesh and material draw
	together. */
class Material {
	// Kept across a hot reload: ids made after one mustn't repeat those of materials still drawn.
	@:hot static var nextId = 1;

	// Which one it is, for sorting alike draws together.
	@:allow(helix.render3d.Stage3D) var id = nextId++;

	var blendAlways = false;
	var parameters:Null<ShaderParameters>;

	/** White, not metallic, roughness 0.5, lit, untextured, giving off no light. */
	public function new() {}

	/** The base color, 0xRRGGBBAA. */
	public var baseColor:Int = 0xffffffff;

	/** The base color texture, or null for none (white). */
	public var texture:Null<Texture2D>;

	/** How metallic, 0..1. Clamped to 0..1 (NaN is 0). */
	public var metallic(default, set):Float = 0.;

	function set_metallic(value:Float):Float {
		value = value > 0 ? (value < 1 ? value : 1) : 0;
		metallic = value;
		return value;
	}

	/** How rough, 0..1. Clamped to 0..1 (NaN is 0). */
	public var roughness(default, set):Float = .5;

	function set_roughness(value:Float):Float {
		value = value > 0 ? (value < 1 ? value : 1) : 0;
		roughness = value;
		return value;
	}

	/** Whether lights shade it; unlit, it shows its color as it is. */
	public var lit:Bool = true;

	/** The normal map (linear, tangent space, green up), or null for none. Load it linear (not sRGB), with mipmaps. */
	public var normalTexture:Null<Texture2D>;

	/** How strongly the normal map bends the surface: 1 as it is, 0 flat. 0 or more (under 0, or NaN, is 0). */
	public var normalScale(default, set):Float = 1.;

	function set_normalScale(value:Float):Float {
		value = value >= 0 ? value : 0;
		normalScale = value;
		return value;
	}

	/** The light it gives off, 0xRRGGBBAA (sRGB, alpha ignored); black for none. */
	public var emissive(default, null):Int = 0x000000ff;

	/** How bright its emissive light is: the color times this. */
	public var emissiveStrength(default, null):Float = 1.;

	/** Gives it light of its own, color (0xRRGGBBAA, sRGB) times strength, lit or not. False for a strength under 0. */
	public function setEmissive(color:Int, strength = 1.):Bool {
		if (!(strength >= 0))
			return false;
		emissive = color;
		emissiveStrength = strength;
		return true;
	}

	/** Whether both sides of its triangles draw (the back with its normal turned toward the viewer), for open surfaces, leaves, cloth, or
		a surface a shader cuts holes in; otherwise back faces are culled. */
	public var doubleSided:Bool = false;

	/** The app's surface shader it draws with, or null for the stage's own shading. */
	public var shader(default, null):Null<Shader>;

	/** Draws it with an app's surface shader (a .hxshader of kind surface: its own fragment stage, and maybe a vertex hook), which gets the
		material's values and textures and the stage's lights; null goes back to the stage's own shading. False, changing nothing, for a shader
		of another kind. Its parameters (shaderParameters) start empty when the shader changes. */
	public function setShader(value:Null<Shader>):Bool {
		if (value != null && value.kind != "surface")
			return false;
		if (value != shader)
			parameters = value == null ? null : new ShaderParameters(value);
		shader = value;
		return true;
	}

	/** Its surface shader's own parameters and textures, set by name; null without a shader. */
	public var shaderParameters(get, never):Null<ShaderParameters>;

	function get_shaderParameters():Null<ShaderParameters>
		return parameters;

	/** Whether it is see-through: drawn blended, back to front after the opaque, when set so or when its base color's alpha is below 255.
		Set, it draws blended even at full alpha, as glTF's alphaMode BLEND says (its texture's alpha then shows through). */
	public var blended(get, set):Bool;

	function get_blended():Bool
		return blendAlways || baseColor & 255 < 255;

	function set_blended(value:Bool):Bool {
		blendAlways = value;
		return value;
	}
}
