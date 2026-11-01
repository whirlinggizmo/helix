package helix.services.models;

import helix.formats.gltf.GltfMaterial;
import helix.geometry.Animation3D;
import helix.geometry.Mesh3D;
import helix.geometry.Skeleton3D;
import helix.geometry.Skin3D;
import helix.math.Matrix3D;
import helix.services.images.Image;

/** Represents a model as `Models` reads it: its meshes, with their nodes' transforms put into them, its materials, and its images
	decoded. */
class Model3D {
	/** Gets the file it was read from, as the assets name it. */
	public final path:String;

	/** Gets the meshes, each node's triangles in the scene's order: its transform in their positions, normals and tangents, but for a
		skinned mesh's (`meshSkinIndices`), whose vertices are as the file gives them, in the space its skin binds them in, as glTF has it. */
	public final meshes:Array<Mesh3D>;

	/** Gets the index of each mesh's material in `materials`, beside it in `meshes`; -1 for none. */
	public final meshMaterialIndices:Array<Int>;

	/** Gets the index of each mesh's skin in `skins`, beside it in `meshes`; -1 for a mesh without one. */
	public final meshSkinIndices:Array<Int>;

	/** Gets each mesh's node's transform in the model, beside it in `meshes`. A mesh without a skin has it in its vertices already; a
		skinned one hasn't, and doesn't need it: its skin's matrices put it in the model. It is kept for an engine that places skinned
		meshes by their nodes anyway, as raylib does. */
	public final meshTransforms:Array<Matrix3D>;

	/** Gets the skeleton its skinned meshes follow: every node any of the file's skins names as a joint, and the nodes above them, each a
		bone (its node's name, its parent, its node's own transform at rest), parents first; null for a model without skins. */
	public final skeleton:Null<Skeleton3D>;

	/** Gets the skins, as the file has them, their bones the skeleton's. */
	public final skins:Array<Skin3D>;

	/** Gets the animations of the skeleton's bones, each the file's animation's channels that move them (translation, rotation, scale);
		a channel moving another node, or morph weights, is left out. Empty without a skeleton. */
	public final animations:Array<Animation3D>;

	/** Gets the materials, as the file has them; a material names its images by their index in `images`. */
	public final materials:Array<GltfMaterial>;

	/** Gets the images, decoded, by their index in the file; null for one that couldn't be read or decoded (the failure logged). */
	public final images:Array<Null<Image>>;

	@:allow(helix.services.models)
	function new(path:String, meshes:Array<Mesh3D>, meshMaterialIndices:Array<Int>, meshSkinIndices:Array<Int>, meshTransforms:Array<Matrix3D>,
			skeleton:Null<Skeleton3D>, skins:Array<Skin3D>, animations:Array<Animation3D>, materials:Array<GltfMaterial>, images:Array<Null<Image>>) {
		this.path = path;
		this.meshes = meshes;
		this.meshMaterialIndices = meshMaterialIndices;
		this.meshSkinIndices = meshSkinIndices;
		this.meshTransforms = meshTransforms;
		this.skeleton = skeleton;
		this.skins = skins;
		this.animations = animations;
		this.materials = materials;
		this.images = images;
	}

	/** Returns the index of the first animation of a name.

		@param name  The name.
		@return  Its index in `animations`, or -1 for none. */
	public function findAnimation(name:String):Int {
		for (i => animation in animations)
			if (animation.name == name)
				return i;
		return -1;
	}
}
