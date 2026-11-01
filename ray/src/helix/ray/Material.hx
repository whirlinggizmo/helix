package helix.ray;

/** Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`); the diffuse map's texture and color are what a draw shows.

	It is counted (docs/DECISIONS.md 25): the program holds it from `LoadMaterialDefault` until `UnloadMaterial`, and each model whose
	`materials` holds it holds it too. When the last lets go, its maps' textures are released and its shader unloaded, unless it is the
	default one. */
class Material {
	// Its holders (docs/DECISIONS.md 25): the program from `LoadMaterialDefault` or `new` until `UnloadMaterial`, and each model whose
	// `materials` holds it. At 0 its maps' textures and its shader are released (`Models.releaseMaterial`).
	@:allow(helix.ray)
	var refs = 1;

	/** Gets or sets the shader it draws with. */
	public var shader:Shader;

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
}
