package helix.ray;

/** Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`); the diffuse map's texture and color are what a draw shows.

	It is counted (docs/DECISIONS.md 25): the program holds it from `LoadMaterialDefault` until `UnloadMaterial`, and each model whose
	`materials` holds it holds it too. When the last lets go, its maps let go of their textures and it of its shader, each freed when
	nothing else holds it. */
class Material {
	// Its holders (docs/DECISIONS.md 25): the program from `LoadMaterialDefault` or `new` until `UnloadMaterial`, and each model whose
	// `materials` holds it. At 0 its maps let go of their textures and it of its shader (`Models.releaseMaterial`).
	@:allow(helix.ray)
	var refs = 1;

	/** Gets or sets the shader it draws with. Assigning keeps a copy of the record, counted as one of the shader's holders, and lets go of
		the shader it replaces; the material lets go of it when it is freed. The default shader is never freed. */
	public var shader(default, set):Shader;

	/** Gets its maps, `MAX_MATERIAL_MAPS` of them, by `MATERIAL_MAP_*`. */
	public var maps:Array<MaterialMap>;

	/** Gets four values for a shader's own use. */
	public var params:Array<Float>;

	/** Creates a material. Materials are made by `Raylib.LoadMaterialDefault` and `Raylib.LoadModelAsync`.

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
			helix.ray.internal.Models.retainShader(kept);
		}
		var old = shader;
		shader = kept;
		if (old != null)
			helix.ray.internal.Models.releaseShader(old);
		return kept;
	}
}
