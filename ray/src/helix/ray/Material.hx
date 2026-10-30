package helix.ray;

/** Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`); the diffuse map's texture and color are what a draw shows. */
class Material {
	/** Gets or sets the shader it draws with. */
	public var shader:Shader;

	/** Gets its maps, `MAX_MATERIAL_MAPS` of them, by `MATERIAL_MAP_*`. */
	public var maps:Array<MaterialMap>;

	/** Gets four values for a shader's own use. */
	public var params:Array<Float>;

	/** Creates a material. Materials are made by `Raylib.LoadMaterialDefault` and `Raylib.LoadModel`.

		@param shader  The shader.
		@param maps  The maps.
		@param params  The values. */
	public function new(shader:Shader, maps:Array<MaterialMap>, ?params:Array<Float>) {
		this.shader = shader;
		this.maps = maps;
		this.params = params == null ? [0, 0, 0, 0] : params;
	}
}
