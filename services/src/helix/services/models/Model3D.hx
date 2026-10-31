package helix.services.models;

import helix.formats.gltf.GltfMaterial;
import helix.services.images.Image;

/** Represents a model as `Models` reads it: its meshes, with their nodes' transforms put into them, its materials, and its images
	decoded. */
class Model3D {
	/** Gets the file it was read from, as the assets name it. */
	public final path:String;

	/** Gets the meshes, each node's triangles in the scene's order, its transform in their positions and normals. */
	public final meshes:Array<Mesh3D>;

	/** Gets the materials, as the file has them; a material names its images by their index in `images`. */
	public final materials:Array<GltfMaterial>;

	/** Gets the images, decoded, by their index in the file; null for one that couldn't be read or decoded (the failure logged). */
	public final images:Array<Null<Image>>;

	@:allow(helix.services.models)
	function new(path:String, meshes:Array<Mesh3D>, materials:Array<GltfMaterial>, images:Array<Null<Image>>) {
		this.path = path;
		this.meshes = meshes;
		this.materials = materials;
		this.images = images;
	}
}
