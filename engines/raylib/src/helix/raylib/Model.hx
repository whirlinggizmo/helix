package helix.raylib;

/** Represents raylib's `Model`: meshes, materials, which material each mesh draws with, and a transform.

	A model holds a count on each of its meshes and materials (docs/DECISIONS.md 25): putting one in `meshes` or `materials` retains it,
	replacing or `UnloadModel` releases it, and what no one holds any more is freed. */
class Model {
	/** Gets or sets the transform applied before `DrawModel`'s position, rotation and scale. */
	public var transform:Matrix;

	/** Gets the number of meshes, set when `meshes` is. */
	public var meshCount:Int;

	/** Gets the number of materials, set when `materials` is. */
	public var materialCount:Int;

	/** Gets or sets the meshes, each held by the model. Setting copies the array, retains its meshes, releases the ones it replaces and
		sets `meshCount`. */
	public var meshes(default, set):ModelMeshes;

	/** Gets or sets the materials, each held by the model. Setting copies the array, retains its materials, releases the ones it
		replaces and sets `materialCount`. */
	public var materials(default, set):ModelMaterials;

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
	@:allow(helix.raylib)
	var pose:Null<Array<Transform>> = null;

	// The bone matrices UpdateModelAnimation last computed, each skinned mesh's boneMatrices (raylib 6.2's model.boneMatrices); null
	// without bones.
	@:allow(helix.raylib)
	var boneMatrices:Null<Array<Matrix>> = null;

	// The file it was loaded from, sharing its GPU data with the file's other loads, or "" for a model of a mesh.
	@:allow(helix.raylib)
	var path = "";

	/** Creates a model, holding its meshes and materials. Models are made by `Raylib.LoadModelAsync` and `Raylib.LoadModelFromMesh`.

		@param meshes  The meshes.
		@param materials  The materials.
		@param meshMaterial  Each mesh's material. */
	public function new(meshes:Array<Mesh>, materials:Array<Material>, meshMaterial:Array<Int>) {
		transform = new Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
		this.meshes = meshes;
		this.materials = materials;
		this.meshMaterial = meshMaterial;
	}

	function set_meshes(value:ModelMeshes):ModelMeshes {
		var next = value == null ? [] : (cast value : Array<Mesh>).copy();
		for (m in next)
			helix.raylib.internal.Models.retainMesh(m);
		var old = meshes;
		meshes = next;
		if (old != null)
			for (m in old)
				helix.raylib.internal.Models.releaseMesh(m);
		meshCount = next.length;
		return meshes;
	}

	function set_materials(value:ModelMaterials):ModelMaterials {
		var next = value == null ? [] : (cast value : Array<Material>).copy();
		for (m in next)
			helix.raylib.internal.Models.retainMaterial(m);
		var old = materials;
		materials = next;
		if (old != null)
			for (m in old)
				helix.raylib.internal.Models.releaseMaterial(m);
		materialCount = next.length;
		return materials;
	}
}
