package helix.formats.gltf;

/** Represents one material of a glTF model: its metallic-roughness factors and the images its textures sample.

	Each texture is given as the index of its image in `GltfFile.images`, the image its glTF texture's `source` names; a sampler, a
	texture coordinate set other than the first and a texture's transform are not read. Factors the file omits take glTF's defaults. */
class GltfMaterial {
	/** Gets the material's name: empty when the file gives none. */
	public final name:String;

	/** Gets whether the material has a `pbrMetallicRoughness` block, which holds its base color, metalness and roughness: when it
		hasn't, those are glTF's defaults. */
	public final hasPbrMetallicRoughness:Bool;

	/** Gets the base color factor: red, green, blue and alpha, each 0 to 1, multiplying the base color image. Defaults to 1, 1, 1, 1. */
	public final baseColorFactor:Array<Float>;

	/** Gets the index of the base color image in `GltfFile.images`, or -1 when there is none. */
	public final baseColorImage:Int;

	/** Gets the metalness factor, 0 to 1. Defaults to 1. */
	public final metallic:Float;

	/** Gets the roughness factor, 0 to 1. Defaults to 1. */
	public final roughness:Float;

	/** Gets the index of the metallic-roughness image in `GltfFile.images`, or -1 when there is none: roughness in its green channel,
		metalness in its blue. */
	public final metallicRoughnessImage:Int;

	/** Gets the index of the normal map's image in `GltfFile.images`, or -1 when there is none. */
	public final normalImage:Int;

	/** Gets the index of the occlusion image in `GltfFile.images`, or -1 when there is none: how much light reaches each point, in its
		red channel. */
	public final occlusionImage:Int;

	/** Gets the emissive factor: red, green and blue, each 0 to 1, multiplying the emissive image. Defaults to 0, 0, 0. */
	public final emissiveFactor:Array<Float>;

	/** Gets the index of the emissive image in `GltfFile.images`, or -1 when there is none. */
	public final emissiveImage:Int;

	@:allow(helix.formats.gltf)
	function new(name:String, hasPbrMetallicRoughness:Bool, baseColorFactor:Array<Float>, baseColorImage:Int, metallic:Float, roughness:Float,
			metallicRoughnessImage:Int, normalImage:Int, occlusionImage:Int, emissiveFactor:Array<Float>, emissiveImage:Int) {
		this.name = name;
		this.hasPbrMetallicRoughness = hasPbrMetallicRoughness;
		this.baseColorFactor = baseColorFactor;
		this.baseColorImage = baseColorImage;
		this.metallic = metallic;
		this.roughness = roughness;
		this.metallicRoughnessImage = metallicRoughnessImage;
		this.normalImage = normalImage;
		this.occlusionImage = occlusionImage;
		this.emissiveFactor = emissiveFactor;
		this.emissiveImage = emissiveImage;
	}
}
