package helix.ray;

/** Represents raylib's `Model`: meshes, materials, which material each mesh draws with, and a transform. */
class Model {
	/** Gets or sets the transform applied before `DrawModel`'s position, rotation and scale. */
	public var transform:Matrix;

	/** Gets the number of meshes. */
	public var meshCount:Int;

	/** Gets the number of materials. */
	public var materialCount:Int;

	/** Gets the meshes. */
	public var meshes:Array<Mesh>;

	/** Gets the materials. */
	public var materials:Array<Material>;

	/** Gets the material of each mesh, by its index in `materials`. */
	public var meshMaterial:Array<Int>;

	/** Gets the number of bones: the joints of the file's first skin, 0 for a model without one. */
	public var boneCount:Int = 0;

	/** Gets the bones, the file's first skin's joints in its order, each parent the nearest joint above it; null without a skin. */
	public var bones:Null<Array<BoneInfo>> = null;

	/** Gets each bone's transform in the model as the skin was bound to it: its inverse bind matrix inverted, or, for a file that gives
		none, its node's at rest; null without a skin. */
	public var bindPose:Null<Array<Transform>> = null;

	// The pose UpdateModelAnimation last set, by bone (raylib 6.2's currentPose); null without bones.
	@:allow(helix.ray)
	var pose:Null<Array<Transform>> = null;

	// The bone matrices UpdateModelAnimation last computed, each skinned mesh's boneMatrices (raylib 6.2's model.boneMatrices); null
	// without bones.
	@:allow(helix.ray)
	var boneMatrices:Null<Array<Matrix>> = null;

	// The file it was loaded from, sharing its GPU data with the file's other loads, or "" for a model of a mesh.
	@:allow(helix.ray)
	var path = "";

	/** Creates a model. Models are made by `Raylib.LoadModelAsync` and `Raylib.LoadModelFromMesh`.

		@param meshes  The meshes.
		@param materials  The materials.
		@param meshMaterial  Each mesh's material. */
	public function new(meshes:Array<Mesh>, materials:Array<Material>, meshMaterial:Array<Int>) {
		transform = new Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
		this.meshes = meshes;
		this.materials = materials;
		this.meshMaterial = meshMaterial;
		meshCount = meshes.length;
		materialCount = materials.length;
	}
}
