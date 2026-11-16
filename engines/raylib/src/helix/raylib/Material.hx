package helix.raylib;

/** Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`).

	A draw shows the diffuse map's texture and color.

	The program holds a reference until `UnloadMaterial`, and each model using it holds one too. Freed when the last held reference is
	released, which releases its maps' textures and its shader. */
class Material {
	// Its holders (docs/DECISIONS.md 25): the program from `LoadMaterialDefault` or `new` until `UnloadMaterial`, and each model whose
	// `materials` holds it. At 0 its maps let go of their textures and it of its shader (`Models.releaseMaterial`).
	@:allow(helix.raylib)
	var refs = 1;

	/** Gets or sets the material's shader.

		Assigning keeps a copy of the record, counted as one of the shader's holders, and lets go of the shader it replaces.

		A freed material lets go of its shader. The default shader is never freed. */
	public var shader(default, set):Shader;

	/** Gets the maps, `MAX_MATERIAL_MAPS` of them, by `MATERIAL_MAP_*`. */
	public var maps:Array<MaterialMap>;

	/** Gets four values for a shader's own use. */
	public var params:Array<Float>;

	// The Materials extra's values (helix.raylib.extras.Materials), each draw's: the alpha cutoff, 0 for none; the light given off, red,
	// green and blue, its color times its intensity; whether it is unlit; whether shadows fall on it. A glTF file's are loaded into them.
	@:allow(helix.raylib)
	var alphaCutoff = 0.;
	@:allow(helix.raylib)
	var emissiveRed = 0.;
	@:allow(helix.raylib)
	var emissiveGreen = 0.;
	@:allow(helix.raylib)
	var emissiveBlue = 0.;
	@:allow(helix.raylib)
	var unlit = false;
	@:allow(helix.raylib)
	var shadowed = true;

	/** Creates a material. See `Raylib.LoadMaterialDefault` for making raylib's default material, and `LoadModelAsync` for
		loading a model's materials.

		@param shader  The shader.
		@param maps  The maps.
		@param params  The values. */
	public function new(shader:Shader, maps:Array<MaterialMap>, ?params:Array<Float>) {
		this.shader = shader;
		this.maps = maps;
		this.params = params == null ? [0, 0, 0, 0] : params;
	}

	function set_shader(s:Shader):Shader {
		if (s == shader)
			return s;
		var kept = s;
		if (s != null) {
			kept = new Shader(s.id, s.locs, s.program);
			kept.mapped = true;
			helix.raylib.internal.Models.retainShader(kept);
		}
		var old = shader;
		shader = kept;
		if (old != null)
			helix.raylib.internal.Models.releaseShader(old);
		return kept;
	}
}
